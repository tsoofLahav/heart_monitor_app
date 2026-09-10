import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_design.dart';
import 'dart:async';

import 'package:heart_feedback/recording/recording_voice.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/pulse_guide_progress_store.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/recording/finger_frame_metrics.dart';
import 'package:heart_feedback/recording/finger_placement_detector.dart';
import 'package:heart_feedback/recording/rear_camera_selection.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum _IdentifyPhase { loading, testing, found, error }

enum _IdentifyError { none, noRearCamera, couldNotOpen }

/// Guided prep: user covers lenses one camera at a time until detection confirms.
class CameraIdentifyScreen extends StatefulWidget {
  const CameraIdentifyScreen({super.key});

  @override
  State<CameraIdentifyScreen> createState() => _CameraIdentifyScreenState();
}

class _CameraIdentifyScreenState extends State<CameraIdentifyScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _backCameras = [];
  int _cameraIndex = 0;
  int _sessionGen = 0;
  bool _suspended = false;
  Future<void>? _cameraRelease;

  final RecordingVoice _voice = RecordingVoice();
  final FingerPlacementDetector _fingerDetector = FingerPlacementDetector();

  bool _metricsInFlight = false;
  bool _switchingCamera = false;
  bool _previewReady = false;
  bool _confirming = false;
  int _analyzeFrameCounter = 0;

  _IdentifyPhase _phase = _IdentifyPhase.loading;
  _IdentifyError _error = _IdentifyError.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        (state == AppLifecycleState.inactive &&
            _cameraController?.value.isInitialized == true)) {
      if (_suspended) return;
      _suspended = true;
      _sessionGen++;
      unawaited(_voice.stop());
      _cameraRelease = _detachAndDisposeController();
      unawaited(WakelockPlus.disable());
    } else if (state == AppLifecycleState.resumed && _suspended) {
      _suspended = false;
      unawaited(WakelockPlus.enable());
      if (_phase != _IdentifyPhase.found) unawaited(_bootstrap());
    }
  }

  Future<void> _bootstrap() async {
    _sessionGen++;
    final gen = _sessionGen;
    setState(() {
      _phase = _IdentifyPhase.loading;
      _previewReady = false;
      _error = _IdentifyError.none;
    });

    try {
      await _cameraRelease;
      if (!mounted || _suspended || gen != _sessionGen) return;
      final all = await availableCameras();
      if (!mounted || gen != _sessionGen) return;
      _backCameras = orderedBackCamerasForPpg(all);
      if (_backCameras.isEmpty) {
        setState(() {
          _phase = _IdentifyPhase.error;
          _error = _IdentifyError.noRearCamera;
        });
        return;
      }
      _cameraIndex = 0;
      setState(() => _phase = _IdentifyPhase.testing);
      await _openCameraAtIndex(_cameraIndex, gen: gen);
    } catch (e) {
      debugPrint('Camera identify bootstrap failed: $e');
      if (!mounted || gen != _sessionGen) return;
      setState(() {
        _phase = _IdentifyPhase.error;
        _error = _IdentifyError.couldNotOpen;
      });
    }
  }

  /// Drop preview from the tree before disposing so CameraPreview never paints
  /// a disposed controller.
  Future<void> _detachAndDisposeController() async {
    final old = _cameraController;
    _cameraController = null;
    _previewReady = false;
    if (mounted) setState(() {});
    await Future<void>.delayed(Duration.zero);
    if (old == null) return;
    try {
      if (old.value.isStreamingImages) {
        await old.stopImageStream();
      }
    } catch (e) {
      debugPrint('Identify stopImageStream: $e');
    }
    try {
      await old.setFlashMode(FlashMode.off);
    } catch (_) {}
    try {
      await old.dispose();
    } catch (_) {}
  }

  Future<void> _openCameraAtIndex(int index, {required int gen}) async {
    if (_backCameras.isEmpty) return;
    if (gen != _sessionGen) return;
    _switchingCamera = true;
    _confirming = false;

    await _detachAndDisposeController();
    if (!mounted || gen != _sessionGen) {
      _switchingCamera = false;
      return;
    }

    final description = _backCameras[index.clamp(0, _backCameras.length - 1)];
    _cameraIndex = index;

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      if (!mounted || gen != _sessionGen) {
        await controller.dispose();
        return;
      }

      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (e) {
        debugPrint('Identify torch: $e');
      }

      _fingerDetector.resetAll();
      _fingerDetector.begin();
      _analyzeFrameCounter = 0;

      await controller.startImageStream(_onCameraImage);
      _cameraController = controller;

      if (mounted && gen == _sessionGen) {
        setState(() => _previewReady = true);
      }
    } catch (e) {
      debugPrint('Identify open camera failed ($index): $e');
      try {
        await controller.dispose();
      } catch (_) {}
      if (mounted && gen == _sessionGen) {
        setState(() {
          _previewReady = false;
          _cameraController = null;
          _phase = _IdentifyPhase.error;
          _error = _IdentifyError.couldNotOpen;
        });
      }
    } finally {
      _switchingCamera = false;
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_phase != _IdentifyPhase.testing) return;
    if (_switchingCamera || _metricsInFlight || _confirming) return;

    _analyzeFrameCounter++;
    if (_analyzeFrameCounter % 2 != 0) return;

    final frameGeneration = _sessionGen;
    _metricsInFlight = true;
    metricsFromCameraImageAsync(image).then((metrics) {
      _metricsInFlight = false;
      if (!mounted ||
          _suspended ||
          frameGeneration != _sessionGen ||
          metrics == null) {
        return;
      }
      if (_phase != _IdentifyPhase.testing || _switchingCamera || _confirming) {
        return;
      }

      final confirmed = _fingerDetector.process(metrics);
      if (!confirmed) return;
      unawaited(_onFingerConfirmed());
    });
  }

  Future<void> _onFingerConfirmed() async {
    if (_phase != _IdentifyPhase.testing || _confirming) return;
    _confirming = true;
    final generation = _sessionGen;

    final cam = _backCameras[_cameraIndex];
    await _stopStreamKeepController();

    try {
      if (!mounted || _suspended || generation != _sessionGen) return;
      await _voice.speak(context.l10n.localeName, 'found');
    } catch (e) {
      debugPrint('Identify voice: $e');
    }

    if (!mounted || _suspended || generation != _sessionGen) return;
    await PulseGuideProgressStore.instance.markCameraIdentified(
      cameraName: cam.name,
    );

    if (!mounted) return;
    setState(() {
      _phase = _IdentifyPhase.found;
      _previewReady = false;
    });
    await _detachAndDisposeController();
  }

  Future<void> _stopStreamKeepController() async {
    final controller = _cameraController;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (e) {
      debugPrint('Identify stopImageStream: $e');
    }
    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {}
  }

  Future<void> _onRetry() async {
    await _detachAndDisposeController();
    await _bootstrap();
  }

  void _onContinue() {
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionGen++;
    final controller = _cameraController;
    _cameraController = null;
    _previewReady = false;
    if (controller != null) {
      unawaited(() async {
        try {
          if (controller.value.isStreamingImages) {
            await controller.stopImageStream();
          }
        } catch (_) {}
        try {
          await controller.dispose();
        } catch (_) {}
      }());
    }
    _voice.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  String _errorMessage(AppLocalizations l10n) {
    return switch (_error) {
      _IdentifyError.noRearCamera => l10n.noRearCameraFound,
      _IdentifyError.couldNotOpen => l10n.couldNotOpenCamera,
      _IdentifyError.none => l10n.somethingWentWrong,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = _cameraController;
    final showPreview = _previewReady &&
        preview != null &&
        preview.value.isInitialized &&
        _phase == _IdentifyPhase.testing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(l10n.findYourCamera)),
      body: SafeArea(
        child: switch (_phase) {
          _IdentifyPhase.loading => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          _IdentifyPhase.error => _ErrorBody(
              message: _errorMessage(l10n),
              onRetry: _onRetry,
            ),
          _IdentifyPhase.found => _FoundBody(onContinue: _onContinue),
          _IdentifyPhase.testing => _TestingBody(
              showPreview: showPreview,
              preview: preview,
            ),
        },
      ),
    );
  }
}

class _TestingBody extends StatelessWidget {
  final bool showPreview;
  final CameraController? preview;

  const _TestingBody({
    required this.showPreview,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProtocolCenteredScrollBody(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.cameraFindTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppType.body,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.cameraFindBody,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: AppType.body,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: Center(
            child: () {
              final controller = preview;
              if (showPreview && controller != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: 220,
                        height: 220 / controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white54,
                ),
              );
            }(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.holdStillOnLens,
          style: const TextStyle(
              color: Colors.white70, fontSize: AppType.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }
}

class _FoundBody extends StatelessWidget {
  final VoidCallback onContinue;

  const _FoundBody({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProtocolCenteredScrollBody(
        action: ProtocolPrimaryButton(
            label: l10n.continueAction, onPressed: onContinue),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.accent, size: 72),
            const SizedBox(height: 24),
            Text(
              l10n.cameraRememberTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.title,
                fontWeight: FontWeight.w700,
                height: 1.4,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
                decorationThickness: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.cameraRememberHint,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppType.secondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ));
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProtocolCenteredScrollBody(
        action: ProtocolPrimaryButton(label: l10n.tryAgain, onPressed: onRetry),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppType.secondary,
                  height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ));
  }
}
