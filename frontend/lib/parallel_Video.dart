import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'guessing_screen.dart';

const int TOTAL_DURATION = 20; // Total duration in seconds

class BiofeedbackScreen extends StatefulWidget {
  @override
  _BiofeedbackScreenState createState() => _BiofeedbackScreenState();
}

class _BiofeedbackScreenState extends State<BiofeedbackScreen> {
  CameraController? _cameraController;
  bool _isRecording = false;
  String _statusMessage = "Cover lens gently with finger and press Start";

  late Timer _animationTimer;
  late Timer _progressTimer;
  int _heartFrame = 0;
  double _progress = 0.0;
  int _elapsedMillis = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _cameraController = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _startRecordingSession() async {
    _statusMessage = "";
    _isRecording = true;
    _progress = 0.0;
    _elapsedMillis = 0;
    setState(() {});

    final roundCount = TOTAL_DURATION ~/ 10;

    _startAnimationTimer();
    _startProgressTimer();

    // Turn on flashlight for the full session
    await _cameraController!.setFlashMode(FlashMode.torch);

    for (int i = 0; i < roundCount; i++) {
      try {
        await _cameraController!.startVideoRecording();
        await Future.delayed(Duration(seconds: 10));
        if (_cameraController!.value.isRecordingVideo) {
          final file = await _cameraController!.stopVideoRecording();
          final result = await _sendVideoToBackend(file.path);

          // Handle backend rejection
          if (result == 'not_reading' || result == 'server_error') {
            await _handleSessionFailure("Session failed. Please try again.");
            return;
          }
        }
      } catch (e) {
        print("❌ Video recording or upload error: $e");
        await _handleSessionFailure("Recording error. Please try again.");
        return;
      }
    }

    // Turn off flashlight after the session ends
    await _cameraController!.setFlashMode(FlashMode.off);

    _animationTimer.cancel();
    _progressTimer.cancel();

    _isRecording = false;
    _statusMessage = "Finished";
    setState(() {});

    await _sendEndRequest();
  }

  Future<String?> _sendVideoToBackend(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://monitor-app-ajbjg3d3dgayghc9.israelcentral-01.azurewebsites.net/process_video'),
    );
    request.files.add(await http.MultipartFile.fromPath('video', filePath));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📡 Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['not_reading'] == true) return 'not_reading';
        return 'ok';
      } else {
        return 'server_error';
      }
    } catch (e) {
      print("❌ Error sending video: $e");
      return 'server_error';
    }
  }

  Future<void> _sendEndRequest() async {
    try {
      final response = await http.post(
        Uri.parse('https://monitor-app-ajbjg3d3dgayghc9.israelcentral-01.azurewebsites.net/end'),
      );

      print("📡 End Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final packagedData = {
          'peaks_count': data['peaks_count'],
          'real_peaks': (data['real_peaks'] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
          'fake_peaks': (data['fake_peaks'] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
          'duration': (data['duration'] as num).toDouble(),
          'clean_signal': (data['clean_signal'] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
        };

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GuessingScreen(data: packagedData),
          ),
        );
      } else {
        await _handleSessionFailure("Server error. Please try again.");
      }
    } catch (e) {
      print("❌ Error during end session request: $e");
      await _handleSessionFailure("Network error. Please try again.");
    }
  }

  Future<void> _handleSessionFailure(String message) async {
    _animationTimer.cancel();
    _progressTimer.cancel();
    _isRecording = false;
    _progress = 0.0;
    _elapsedMillis = 0;

    try {
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}

    setState(() {
      _statusMessage = message;
    });
  }

  void _startAnimationTimer() {
    _animationTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      setState(() {
        _heartFrame = (_heartFrame + 1) % 6;
      });
    });
  }

  void _startProgressTimer() {
    final totalMillis = TOTAL_DURATION * 1000;
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsedMillis += 100;
        _progress = (_elapsedMillis / totalMillis).clamp(0.0, 1.0);
      });
      if (_elapsedMillis >= totalMillis) timer.cancel();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    if (_animationTimer.isActive) _animationTimer.cancel();
    if (_progressTimer.isActive) _progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Heartbeat Session")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _cameraController?.value.isInitialized == true
              ? SizedBox(
                  width: 150,
                  height: 150,
                  child: CameraPreview(_cameraController!),
                )
              : CircularProgressIndicator(),
          SizedBox(height: 30),
          _isRecording
              ? Column(
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 800),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Image.asset(
                        "assets/heart$_heartFrame.png",
                        key: ValueKey<int>(_heartFrame),
                        width: 100,
                        height: 100,
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                        minHeight: 8,
                      ),
                    ),
                  ],
                )
              : Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isRecording ? null : _startRecordingSession,
            child: Text("Start"),
          ),
        ],
      ),
    );
  }
}
