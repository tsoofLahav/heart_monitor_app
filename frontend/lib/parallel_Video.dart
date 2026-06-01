import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'guessing_screen.dart';
import 'pilote_export_screen.dart';
import 'session_data_manager.dart';

const String _apiBase =
    'https://monitor-app-ajbjg3d3dgayghc9.israelcentral-01.azurewebsites.net';
const int maxSessionSeconds = 25;

enum RecordingFlow { regular, pilote }

class HeartbeatRecordingScreen extends StatefulWidget {
  final RecordingFlow flow;

  const HeartbeatRecordingScreen({super.key, required this.flow});

  @override
  State<HeartbeatRecordingScreen> createState() => _HeartbeatRecordingScreenState();
}

/// Regular practice flow (guessing screen after session).
class BiofeedbackScreen extends HeartbeatRecordingScreen {
  BiofeedbackScreen({super.key}) : super(flow: RecordingFlow.regular);
}

/// Pilote capture flow (save/share export after session).
class PiloteRecordingScreen extends HeartbeatRecordingScreen {
  const PiloteRecordingScreen({super.key}) : super(flow: RecordingFlow.pilote);
}

class _HeartbeatRecordingScreenState extends State<HeartbeatRecordingScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isProcessing = false;
  String _statusMessage = 'Cover lens gently with finger and press Start';

  Timer? _animationTimer;
  Timer? _progressTimer;
  Completer<void>? _endRecordingCompleter;

  int _heartFrame = 0;
  double _progress = 0.0;
  int _elapsedMillis = 0;
  DateTime? _sessionStartedAtUtc;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  void _signalEndRecording() {
    final c = _endRecordingCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  Future<void> _startRecordingSession() async {
    if (_cameraController?.value.isInitialized != true) return;

    _sessionStartedAtUtc = DateTime.now().toUtc();
    _statusMessage = '';
    _isRecording = true;
    _isProcessing = false;
    _progress = 0.0;
    _elapsedMillis = 0;
    setState(() {});

    _animationTimer?.cancel();
    _progressTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      setState(() {
        _heartFrame = (_heartFrame + 1) % 6;
      });
    });
    _startProgressTimer();

    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint('Could not enable flash: $e');
    }

    String? videoPath;
    try {
      await _cameraController!.startVideoRecording();
      _endRecordingCompleter = Completer<void>();
      final endFuture = _endRecordingCompleter!.future;
      final maxDuration = Future<void>.delayed(
        const Duration(seconds: maxSessionSeconds),
      );
      await Future.any<void>([endFuture, maxDuration]);

      if (!mounted) return;
      if (!_cameraController!.value.isRecordingVideo) {
        await _handleSessionFailure('Recording was interrupted.');
        return;
      }
      final file = await _cameraController!.stopVideoRecording();
      videoPath = file.path;
    } catch (e) {
      debugPrint('Recording error: $e');
      await _handleSessionFailure('Recording error. Please try again.');
      return;
    }

    try {
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}

    _animationTimer?.cancel();
    _progressTimer?.cancel();
    _animationTimer = null;
    _progressTimer = null;
    _endRecordingCompleter = null;

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _statusMessage = 'Processing…';
    });

    final uploadResult = await _sendVideoToBackend(videoPath);
    if (!mounted) return;

    if (uploadResult == 'not_reading') {
      await _handleSessionFailure(
        'Could not read your pulse correctly. Cover the lens and try again.',
      );
      return;
    }
    if (uploadResult == 'server_error') {
      await _handleSessionFailure('Server error. Please try again.');
      return;
    }

    await _sendEndAndNavigate();
  }

  Future<String?> _sendVideoToBackend(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBase/process_video'),
    );
    request.files.add(await http.MultipartFile.fromPath('video', filePath));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('process_video: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['not_reading'] == true) return 'not_reading';
        return 'ok';
      }
      return 'server_error';
    } catch (e) {
      debugPrint('Error sending video: $e');
      return 'server_error';
    }
  }

  Future<void> _sendEndAndNavigate() async {
    try {
      final response = await http.post(Uri.parse('$_apiBase/end'));
      debugPrint('end: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) {
        await _handleSessionFailure('Server error. Please try again.');
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map) {
        await _handleSessionFailure('Server error. Please try again.');
        return;
      }
      final data = Map<String, dynamic>.from(decoded);
      final packagedData = {
        'peaks_count': data['peaks_count'],
        'real_peaks': (data['real_peaks'] as List).map((e) => (e as num).toDouble()).toList(),
        'fake_peaks': (data['fake_peaks'] as List).map((e) => (e as num).toDouble()).toList(),
        'duration': (data['duration'] as num).toDouble(),
        'clean_signal': (data['clean_signal'] as List).map((e) => (e as num).toDouble()).toList(),
      };

      if (!mounted) return;

      if (widget.flow == RecordingFlow.pilote) {
        final id = SessionDataManager().saveSessionData(
          packagedData,
          startedAtUtc: _sessionStartedAtUtc,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PiloteExportScreen(sessionId: id)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GuessingScreen(data: packagedData)),
        );
      }
    } catch (e) {
      debugPrint('Error during end session: $e');
      await _handleSessionFailure('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleSessionFailure(String message) async {
    _animationTimer?.cancel();
    _progressTimer?.cancel();
    _animationTimer = null;
    _progressTimer = null;
    _endRecordingCompleter = null;
    _isRecording = false;
    _isProcessing = false;
    _progress = 0.0;
    _elapsedMillis = 0;

    try {
      if (_cameraController?.value.isRecordingVideo == true) {
        await _cameraController!.stopVideoRecording();
      }
    } catch (_) {}

    try {
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _onEndPressed() {
    if (!_isRecording) return;
    setState(() {
      _statusMessage = 'Stopping…';
    });
    _signalEndRecording();
  }

  void _startProgressTimer() {
    final totalMillis = maxSessionSeconds * 1000;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedMillis += 100;
        _progress = (_elapsedMillis / totalMillis).clamp(0.0, 1.0);
      });
      if (_elapsedMillis >= totalMillis) timer.cancel();
    });
  }

  String _formatElapsed() {
    final s = _elapsedMillis ~/ 1000;
    final m = s ~/ 60;
    final rs = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}';
  }

  String get _appBarTitle =>
      widget.flow == RecordingFlow.pilote ? 'Pilote recording' : 'Heartbeat Session';

  @override
  void dispose() {
    _animationTimer?.cancel();
    _progressTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isRecording || _isProcessing;
    final accent = widget.flow == RecordingFlow.pilote
        ? Colors.deepPurpleAccent
        : Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(_appBarTitle)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _cameraController?.value.isInitialized == true
              ? SizedBox(
                  width: 150,
                  height: 150,
                  child: CameraPreview(_cameraController!),
                )
              : const CircularProgressIndicator(),
          const SizedBox(height: 30),
          if (_isProcessing)
            const Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Processing…',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            )
          else if (_isRecording)
            Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Image.asset(
                    'assets/heart$_heartFrame.png',
                    key: ValueKey<int>(_heartFrame),
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatElapsed(),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 8,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 40),
          if (!_isProcessing && !_isRecording)
            ElevatedButton(
              onPressed: _cameraController?.value.isInitialized == true
                  ? _startRecordingSession
                  : null,
              child: const Text('Start'),
            )
          else if (_isRecording)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: busy ? _onEndPressed : null,
              child: const Text('End'),
            ),
        ],
      ),
    );
  }
}
