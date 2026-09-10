import 'package:heart_feedback/shell/app_design.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/pulse_guide_assets.dart';
import 'package:heart_feedback/calibration/pulse_guide_progress_store.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/recording/finger_frame_metrics.dart';
import 'package:heart_feedback/recording/finger_placement_detector.dart';
import 'package:heart_feedback/recording/process_video_client.dart';
import 'package:heart_feedback/recording/recording_finger_copy.dart';
import 'package:heart_feedback/recording/recording_flow.dart';
import 'package:heart_feedback/recording/recording_timing.dart';
import 'package:heart_feedback/recording/recording_voice.dart';
import 'package:heart_feedback/recording/recording_guide_widgets.dart';
import 'package:heart_feedback/recording/rear_camera_selection.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/app_config.dart';
import 'package:heart_feedback/shell/qa_skip.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FingerWaitCancelled implements Exception {}

class HeartbeatRecordingScreen extends StatefulWidget {
  final RecordingFlow flow;
  final bool countingBeeps;
  final int? maxSessionSecondsOverride;
  final int? protocolRecordingNumber;
  final int protocolTotalRounds;
  final String? sessionTitle;
  final String? footerLabel;

  const HeartbeatRecordingScreen({
    super.key,
    required this.flow,
    this.countingBeeps = false,
    this.maxSessionSecondsOverride,
    this.protocolRecordingNumber,
    this.protocolTotalRounds = 2,
    this.sessionTitle,
    this.footerLabel,
  });

  @override
  State<HeartbeatRecordingScreen> createState() =>
      _HeartbeatRecordingScreenState();
}

class _HeartbeatRecordingScreenState extends State<HeartbeatRecordingScreen>
    with WidgetsBindingObserver {
  static const Duration _wrongCameraHintDelay = Duration(seconds: 4);
  static const Duration _fingerWaitTimeout = Duration(seconds: 90);

  CameraController? _cameraController;
  List<CameraDescription> _backCameras = [];
  int _cameraIndex = 0;
  bool _hasPreferredCamera = false;

  final AudioPlayer _cuePlayer = AudioPlayer();
  final RecordingVoice _voice = RecordingVoice();
  int _startRequest = 0;
  int _cameraGeneration = 0;
  bool _cameraFailed = false;
  bool _suspended = false;
  Future<void>? _cameraRelease;

  void _voiceHint(String cue) {
    _voice.speak(_l10n.localeName, cue, hint: true).catchError((Object error) {
      debugPrint('Voice hint failed: $error');
    });
  }

  final FingerPlacementDetector _fingerDetector = FingerPlacementDetector();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isAwaitingFinger = false;
  bool _isPreparingBaseline = false;
  bool _showWrongCameraHint = false;
  bool _imageStreamActive = false;
  bool _metricsInFlight = false;
  String _statusMessage = '';
  bool _didSetInitialStatus = false;

  static const double _guideImageHeight = 175;
  static const double _previewSize = 96;

  Timer? _animationTimer;
  Timer? _wrongCameraHintTimer;
  Timer? _fingerWaitTimeoutTimer;
  Completer<void>? _fingerConfirmedCompleter;

  int _heartFrame = 0;
  int _analyzeFrameCounter = 0;
  int _debugMetricsCounter = 0;
  DateTime? _sessionStartedAtUtc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _loadCamerasAndInit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSetInitialStatus) return;
    _didSetInitialStatus = true;
    _statusMessage = _idleCaption;
  }

  int get _maxSessionSeconds {
    if (widget.maxSessionSecondsOverride != null) {
      return widget.maxSessionSecondsOverride!;
    }
    switch (widget.flow) {
      case RecordingFlow.learn:
        return learnPracticeMaxSeconds;
      case RecordingFlow.protocol:
        return maxSessionSeconds;
    }
  }

  AppLocalizations get _l10n => context.l10n;

  String get _idleCaption {
    final l10n = _l10n;
    if (widget.flow == RecordingFlow.protocol &&
        widget.protocolRecordingNumber != null) {
      if (!widget.countingBeeps) return l10n.recordingNoCountCaption;
      return RecordingFingerCopy.protocolShortCaption(
        l10n,
        widget.protocolRecordingNumber!,
      );
    }
    return RecordingFingerCopy.idleCaption(l10n);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        (state == AppLifecycleState.inactive &&
            _cameraController?.value.isInitialized == true)) {
      if (_suspended) return;
      _suspended = true;
      _startRequest++;
      _cameraGeneration++;
      _cancelWrongCameraHintTimer();
      _cancelFingerWaitTimeoutTimer();
      _animationTimer?.cancel();
      final waiter = _fingerConfirmedCompleter;
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete();
      }
      _fingerConfirmedCompleter = null;
      _isRecording = false;
      _isAwaitingFinger = false;
      _isPreparingBaseline = false;
      _imageStreamActive = false;
      unawaited(_voice.stop());
      unawaited(_cuePlayer.stop());
      final controller = _cameraController;
      _cameraController = null;
      setState(() => _statusMessage = _l10n.recordingInterrupted);
      _cameraRelease = controller?.dispose();
      unawaited(WakelockPlus.disable());
    } else if (state == AppLifecycleState.resumed && _suspended) {
      _suspended = false;
      unawaited(WakelockPlus.enable());
      if (!_isProcessing) unawaited(_loadCamerasAndInit());
    }
  }

  Future<void> _loadCamerasAndInit() async {
    final generation = ++_cameraGeneration;
    if (_cameraFailed) _statusMessage = _idleCaption;
    setState(() => _cameraFailed = false);
    try {
      await _cameraRelease;
      final all = await availableCameras();
      if (!mounted || _suspended || generation != _cameraGeneration) return;
      _backCameras = orderedBackCamerasForPpg(all);
      if (_backCameras.isEmpty) throw StateError('No rear camera');
      final preferredName =
          await PulseGuideProgressStore.instance.getPreferredCameraName();
      if (!mounted || _suspended || generation != _cameraGeneration) return;
      _hasPreferredCamera = preferredName != null && preferredName.isNotEmpty;
      _cameraIndex = preferredPpgCameraIndex(
        _backCameras,
        preferredName: preferredName,
      );
      await _initCameraAtIndex(_cameraIndex, generation);
    } catch (error) {
      debugPrint('Recording camera initialization: $error');
      if (mounted && generation == _cameraGeneration) {
        setState(() {
          _cameraFailed = true;
          _statusMessage = _l10n.couldNotOpenCamera;
        });
      }
    }
  }

  Future<void> _initCameraAtIndex(int index, int generation) async {
    final description = _backCameras[index.clamp(0, _backCameras.length - 1)];
    final previous = _cameraController;
    setState(() => _cameraController = null);
    await previous?.dispose();
    if (!mounted || _suspended || generation != _cameraGeneration) return;
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    try {
      await controller.initialize();
      if (!mounted || _suspended || generation != _cameraGeneration) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (error) {
        debugPrint('Could not set flash off: $error');
      }
      if (mounted && !_suspended && generation == _cameraGeneration) {
        setState(() {});
        _fingerDetector.resetAll();
        await _startPreStartBaselineStream();
      }
    } catch (_) {
      if (identical(_cameraController, controller)) _cameraController = null;
      await controller.dispose();
      rethrow;
    }
  }

  Future<void> _startPreStartBaselineStream() async {
    if (_cameraController?.value.isInitialized != true) return;
    if (_isAwaitingFinger || _isRecording || _isProcessing) return;

    _isPreparingBaseline = true;
    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint('Could not enable flash for pre-start baseline: $e');
    }

    if (_imageStreamActive) return;
    try {
      await _cameraController!.startImageStream(_onCameraImage);
      _imageStreamActive = true;
    } catch (e) {
      debugPrint('startImageStream (pre-start): $e');
      _isPreparingBaseline = false;
    }
  }

  Future<void> _stopImageStreamIfNeeded() async {
    if (!_imageStreamActive || _cameraController == null) return;
    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('stopImageStream: $e');
    }
    _imageStreamActive = false;
  }

  void _cancelFingerWaitTimeoutTimer() {
    _fingerWaitTimeoutTimer?.cancel();
    _fingerWaitTimeoutTimer = null;
  }

  void _startFingerWaitTimeoutTimer() {
    _cancelFingerWaitTimeoutTimer();
    _fingerWaitTimeoutTimer = Timer(_fingerWaitTimeout, () {
      if (!mounted || !_isAwaitingFinger) return;
      setState(() {
        _statusMessage = RecordingFingerCopy.fingerWaitTimeoutHint(_l10n);
      });
      final waiter = _fingerConfirmedCompleter;
      if (waiter != null && !waiter.isCompleted) {
        waiter.completeError(FingerWaitCancelled());
      }
    });
  }

  void _cancelWrongCameraHintTimer() {
    _wrongCameraHintTimer?.cancel();
    _wrongCameraHintTimer = null;
  }

  void _scheduleWrongCameraHintIfNeeded() {
    if (_fingerDetector.phase != FingerWaitPhase.waitingFinger) return;
    if (_wrongCameraHintTimer != null || _showWrongCameraHint) return;
    _wrongCameraHintTimer = Timer(_wrongCameraHintDelay, () {
      if (!mounted || !_isAwaitingFinger) return;
      if (_fingerDetector.phase != FingerWaitPhase.waitingFinger) return;
      setState(() {
        _voiceHint('camera');
        _showWrongCameraHint = true;
        _statusMessage = _hasPreferredCamera
            ? RecordingFingerCopy.preferredCameraPlacementHint(_l10n)
            : RecordingFingerCopy.wrongCameraHint(_l10n);
      });
    });
  }

  void _onCameraImage(CameraImage image) {
    if (_isRecording) return;
    if (_metricsInFlight) return;

    _analyzeFrameCounter++;
    if (_analyzeFrameCounter % 2 != 0) return;

    final awaitingFinger =
        _isAwaitingFinger && _fingerConfirmedCompleter?.isCompleted != true;
    final preparingBaseline = _isPreparingBaseline && !awaitingFinger;
    if (!awaitingFinger && !preparingBaseline) return;

    final frameGeneration = _cameraGeneration;
    _metricsInFlight = true;
    final planeCount = image.planes.length;
    final formatGroup = image.format.group;
    metricsFromCameraImageAsync(image).then((metrics) {
      _metricsInFlight = false;
      if (!mounted ||
          _suspended ||
          frameGeneration != _cameraGeneration ||
          metrics == null) {
        return;
      }

      if (preparingBaseline && _isPreparingBaseline && !_isAwaitingFinger) {
        _fingerDetector.feedPreStartBaseline(metrics);
        if (kDebugMode && _debugMetricsCounter++ % 30 == 0) {
          debugPrint(
            'Pre-start baseline: ready=${_fingerDetector.isPreStartBaselineReady} '
            'Y=${metrics.meanLuminance.toStringAsFixed(1)} '
            'skin=${metrics.skinRatio.toStringAsFixed(2)}',
          );
        }
        return;
      }

      if (!awaitingFinger || _fingerConfirmedCompleter?.isCompleted == true) {
        return;
      }

      final phaseBefore = _fingerDetector.phase;
      final wasBaseline = phaseBefore == FingerWaitPhase.baseline;
      final confirmed = _fingerDetector.process(metrics);

      if (kDebugMode) {
        _debugMetricsCounter++;
        if (_debugMetricsCounter % 15 == 0) {
          debugPrint(
            'Finger metrics: phase=${_fingerDetector.phase} '
            'Y=${metrics.meanLuminance.toStringAsFixed(1)} '
            'std=${metrics.luminanceStdDev.toStringAsFixed(1)} '
            'skin=${metrics.skinRatio.toStringAsFixed(2)} '
            'planes=$planeCount fmt=$formatGroup',
          );
        }
      }

      if (_fingerDetector.phase == FingerWaitPhase.baseline &&
          metrics.skinRatio >= FingerPlacementDetector.baselineSkinAbortRatio) {
        _voiceHint('replace');
        if (mounted) {
          setState(
            () => _statusMessage =
                RecordingFingerCopy.baselineFingerOnHint(_l10n),
          );
        }
      } else if (_fingerDetector.phase == FingerWaitPhase.baseline && mounted) {
        setState(
          () => _statusMessage = RecordingFingerCopy.baselineHint(_l10n),
        );
      } else if (_fingerDetector.phase == FingerWaitPhase.holding && mounted) {
        setState(
          () => _statusMessage = RecordingFingerCopy.holdingFingerHint(_l10n),
        );
      } else if (_fingerDetector.phase == FingerWaitPhase.waitingFinger &&
          (wasBaseline || !_showWrongCameraHint)) {
        if (mounted) {
          setState(() {
            _statusMessage = _showWrongCameraHint
                ? RecordingFingerCopy.wrongCameraHint(_l10n)
                : RecordingFingerCopy.waitingFingerHint(_l10n);
          });
        }
        _scheduleWrongCameraHintIfNeeded();
      }

      if (confirmed) {
        _cancelFingerWaitTimeoutTimer();
        _fingerConfirmedCompleter?.complete();
      }
    });
  }

  Future<void> _cancelFingerWait() async {
    _startRequest++;
    final waiter = _fingerConfirmedCompleter;
    if (waiter != null && !waiter.isCompleted) {
      waiter.completeError(FingerWaitCancelled());
    }
    _cancelWrongCameraHintTimer();
    _cancelFingerWaitTimeoutTimer();
    await _voice.stop();
    _fingerDetector.resetDetection();
    _fingerConfirmedCompleter = null;
    _isAwaitingFinger = false;
    _showWrongCameraHint = false;
    if (mounted) {
      setState(() => _statusMessage = _idleCaption);
      await _startPreStartBaselineStream();
    }
  }

  Future<void> _runFingerWaitPhase() async {
    if (_cameraController?.value.isInitialized != true) return;

    _isPreparingBaseline = false;
    _fingerDetector.beginFromPreStart();
    _analyzeFrameCounter = 0;
    _showWrongCameraHint = false;
    _cancelWrongCameraHintTimer();
    _fingerConfirmedCompleter = Completer<void>();

    setState(() {
      _statusMessage = _fingerDetector.phase == FingerWaitPhase.waitingFinger
          ? RecordingFingerCopy.waitingFingerHint(_l10n)
          : RecordingFingerCopy.baselineHint(_l10n);
    });

    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint('Could not enable flash: $e');
    }

    if (!_imageStreamActive) {
      await _cameraController!.startImageStream(_onCameraImage);
      _imageStreamActive = true;
    }
    _startFingerWaitTimeoutTimer();

    if (_fingerDetector.phase == FingerWaitPhase.waitingFinger) {
      _scheduleWrongCameraHintIfNeeded();
    }

    await _fingerConfirmedCompleter!.future;
  }

  Future<void> _onStartPressed() async {
    if (_cameraController?.value.isInitialized != true) return;
    if (_isAwaitingFinger || _isRecording || _isProcessing) return;

    final request = ++_startRequest;
    setState(() => _isAwaitingFinger = true);

    try {
      await _runFingerWaitPhase();
      if (!mounted || request != _startRequest) return;

      await _stopImageStreamIfNeeded();
      _cancelWrongCameraHintTimer();
      _cancelFingerWaitTimeoutTimer();

      if (!mounted || request != _startRequest) return;
      await _voice.speak(
          _l10n.localeName, widget.countingBeeps ? 'ready_count' : 'ready');
      if (!mounted || request != _startRequest) return;
      _isAwaitingFinger = false;
      await _startRecordingSession();
    } on FingerWaitCancelled {
      if (mounted && request == _startRequest) await _cancelFingerWait();
      return;
    } catch (e) {
      debugPrint('Finger wait error: $e');
      if (mounted && request == _startRequest) await _cancelFingerWait();
    }
  }

  Future<void> _startRecordingSession() async {
    final request = _startRequest;
    final controller = _cameraController;
    if (controller?.value.isInitialized != true || _suspended) return;

    _statusMessage = '';
    _isRecording = true;
    _isProcessing = false;
    setState(() {});

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        _heartFrame = (_heartFrame + 1) % 6;
      });
    });

    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint('Could not enable flash: $e');
    }

    String? videoPath;
    CountingCueWindow? countingWindow;
    try {
      if (!mounted || request != _startRequest) return;
      await _cuePlayer.setReleaseMode(ReleaseMode.stop);
      await _cuePlayer.setSource(AssetSource('beep.mp3'));
      if (!mounted || request != _startRequest) return;
      await controller!.startVideoRecording();
      if (!mounted || request != _startRequest) return;
      // The camera plugin acknowledges capture before we begin the warmup.
      _sessionStartedAtUtc = DateTime.now().toUtc();
      final captureClock = Stopwatch()..start();
      countingWindow = await runCountingCues(
        countingBeeps: widget.countingBeeps,
        countDuration: Duration(seconds: _maxSessionSeconds) - recordingWarmup,
        elapsed: () => captureClock.elapsed,
        wait: (duration) => Future<void>.delayed(duration),
        isActive: () =>
            mounted &&
            !_suspended &&
            request == _startRequest &&
            _cameraController?.value.isRecordingVideo == true,
        playCue: () async {
          await _cuePlayer.stop();
          if (!mounted ||
              request != _startRequest ||
              _cameraController?.value.isRecordingVideo != true) {
            throw StateError('Capture stopped before cue');
          }
          final onset = captureClock.elapsed;
          await _cuePlayer.resume();
          return onset;
        },
      );

      if (!mounted || request != _startRequest) return;
      if (!_cameraController!.value.isRecordingVideo) {
        if (widget.flow == RecordingFlow.learn ||
            widget.flow == RecordingFlow.protocol) {
          Navigator.pop(context);
          return;
        }
        await _handleSessionFailure(_l10n.recordingInterrupted);
        return;
      }
      final file = await controller.stopVideoRecording();
      videoPath = file.path;
      if (!mounted || request != _startRequest) return;
      await _voice.speak(_l10n.localeName, 'finished');
    } catch (e) {
      debugPrint('Recording error: $e');
      if (!mounted || request != _startRequest) return;
      if (widget.flow == RecordingFlow.learn ||
          widget.flow == RecordingFlow.protocol) {
        if (mounted) Navigator.pop(context);
        return;
      }
      await _handleSessionFailure(_l10n.recordingErrorRetry);
      return;
    }

    if (!mounted || request != _startRequest) return;
    try {
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}

    _animationTimer?.cancel();
    _animationTimer = null;

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final uploadResult = await processVideo(
      filePath: videoPath,
      recordingStartedAtUtc: _sessionStartedAtUtc,
      countingWindow: countingWindow,
    );
    if (!mounted) return;

    if (uploadResult == null) {
      if (widget.flow == RecordingFlow.learn ||
          widget.flow == RecordingFlow.protocol) {
        Navigator.pop(context);
        return;
      }
      await _handleSessionFailure(_l10n.serverErrorRetry);
      return;
    }
    if (uploadResult['not_reading'] == true) {
      if (widget.flow == RecordingFlow.learn) {
        Navigator.pop(context, {'not_reading': true});
        return;
      }
      if (widget.flow == RecordingFlow.protocol) {
        Navigator.pop(context, {'not_reading': true});
        return;
      }
      await _handleNotReading();
      return;
    }

    await _navigateWithSessionData(packageSessionData(uploadResult));
  }

  Future<void> _navigateWithSessionData(
      Map<String, dynamic> packagedData) async {
    try {
      if (!mounted) return;

      Navigator.pop(context, packagedData);
    } catch (e) {
      debugPrint('Error navigating after upload: $e');
      await _handleSessionFailure(_l10n.networkErrorRetry);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _resetAfterError() async {
    _animationTimer?.cancel();
    _animationTimer = null;
    _isRecording = false;
    _isProcessing = false;
    _isAwaitingFinger = false;
    _showWrongCameraHint = false;
    _cancelWrongCameraHintTimer();
    _cancelFingerWaitTimeoutTimer();
    await _stopImageStreamIfNeeded();
    _isPreparingBaseline = false;
    _fingerDetector.resetAll();
    _sessionStartedAtUtc = null;

    try {
      if (_cameraController?.value.isRecordingVideo == true) {
        await _cameraController!.stopVideoRecording();
      }
    } catch (_) {}

    try {
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}

    if (mounted && !_isRecording && !_isProcessing && !_isAwaitingFinger) {
      await _startPreStartBaselineStream();
    }
  }

  Future<void> _handleNotReading() async {
    await _resetAfterError();
    if (!mounted) return;

    await showBadReadingNote(context, actionLabel: _l10n.startAgain);

    if (mounted) {
      setState(() => _statusMessage = _idleCaption);
    }
  }

  Future<void> _handleSessionFailure(String message) async {
    await _resetAfterError();
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  String _appBarTitle(AppLocalizations l10n) {
    if (widget.sessionTitle != null && widget.sessionTitle!.isNotEmpty) {
      return widget.sessionTitle!;
    }
    switch (widget.flow) {
      case RecordingFlow.learn:
        return l10n.practiceReading;
      case RecordingFlow.protocol:
        return l10n.protocolRecording;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    _startRequest++;
    _cancelWrongCameraHintTimer();
    _cancelFingerWaitTimeoutTimer();
    _animationTimer?.cancel();
    _cuePlayer.dispose();
    _voice.dispose();
    _stopImageStreamIfNeeded();
    _cameraController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  Widget _buildProcessingBody(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 28),
            Text(
              l10n.processingDataWait,
              style:
                  const TextStyle(color: Colors.white, fontSize: AppType.body),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_appBarTitle(l10n)),
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem(
                  'Skip recording (fake OK)',
                  () => Navigator.of(context).pop(qaFakeSessionData()),
                ),
              ],
            ),
        ],
      ),
      body: widget.flow == RecordingFlow.protocol &&
              widget.protocolRecordingNumber != null
          ? ProtocolRoundShell(
              roundNumber: widget.protocolRecordingNumber!,
              totalRounds: widget.protocolTotalRounds,
              footerLabel: widget.footerLabel,
              action: _recordingAction(l10n),
              child: _buildRecordingBody(l10n),
            )
          : ProtocolCenteredScrollBody(
              padding: kCenteredBodyPadding,
              action: _recordingAction(l10n),
              child: _buildRecordingBody(l10n),
            ),
    );
  }

  Widget? _recordingAction(AppLocalizations l10n) {
    // Detection keeps running while the user follows the placement hints.
    if (_isProcessing || _isRecording || _isAwaitingFinger) return null;
    if (_cameraFailed) {
      return ProtocolPrimaryButton(
        label: l10n.tryAgain,
        onPressed: _loadCamerasAndInit,
      );
    }
    return ProtocolPrimaryButton(
        label: l10n.start,
        onPressed: _cameraController?.value.isInitialized == true
            ? _onStartPressed
            : null);
  }

  Widget _buildRecordingBody(AppLocalizations l10n) {
    if (_isProcessing) {
      return _buildProcessingBody(l10n);
    }
    return _buildRecordingContent(l10n);
  }

  Widget _buildRecordingContent(
    AppLocalizations l10n,
  ) {
    final showCornerPreview =
        _cameraController?.value.isInitialized == true && !_isRecording;
    final showGuideImage = !_isRecording;
    final guideAsset =
        _isAwaitingFinger ? PulseGuideAssets.step3 : PulseGuideAssets.step2;
    final caption = _showWrongCameraHint
        ? RecordingFingerCopy.wrongCameraHint(l10n)
        : _isAwaitingFinger
            ? (_statusMessage.isNotEmpty
                ? _statusMessage
                : RecordingFingerCopy.waitingFingerHint(l10n))
            : (_statusMessage.isNotEmpty ? _statusMessage : _idleCaption);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showGuideImage) ...[
          RecordingGuideWithPreview(
            assetPath: guideAsset,
            controller: showCornerPreview ? _cameraController : null,
            imageHeight: _guideImageHeight,
            previewSize: _previewSize,
          ),
          const SizedBox(height: 20),
          Text(
            caption,
            style: TextStyle(
              color:
                  _showWrongCameraHint ? AppColors.accentMuted : Colors.white70,
              fontSize: AppType.body,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
        if (_isRecording)
          Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Image.asset(
                  'assets/heart$_heartFrame.png',
                  key: ValueKey<int>(_heartFrame),
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        if (_isAwaitingFinger) ...[
          if (!_showWrongCameraHint) ...[
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 24),
          ],
        ],
      ],
    );
  }
}
