import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AnimatedVideoPage extends StatefulWidget {
  final List<double> peaks;
  final double duration;
  final VoidCallback onFinished;

  const AnimatedVideoPage({
    required this.peaks,
    required this.duration,
    required this.onFinished,
  });

  @override
  _AnimatedVideoPageState createState() => _AnimatedVideoPageState();
}

class _AnimatedVideoPageState extends State<AnimatedVideoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _player = AudioPlayer();
  Set<int> _playedPeaks = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward();
    _startPeakMonitor();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tickTimer?.cancel();
        widget.onFinished();
      }
    });
  }

  void _startPeakMonitor() {
    _tickTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      double currentTime = _controller.value * widget.duration;

      for (int i = 0; i < widget.peaks.length; i++) {
        if (!_playedPeaks.contains(i) &&
            (currentTime - widget.peaks[i]).abs() < 0.02) {
          _playedPeaks.add(i);
          _player.play(AssetSource('beep.mp3'), volume: 1.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Playing Animation")),
      body: CustomPaint(
        painter: ECGPainter(
          peaks: widget.peaks,
          elapsedTime: _controller.value * widget.duration,
          totalDuration: widget.duration,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List<double> peaks;
  final double elapsedTime;
  final double totalDuration;

  ECGPainter({
    required this.peaks,
    required this.elapsedTime,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2;

    final width = size.width.toInt();
    final height = size.height.toInt();
    final centerY = height ~/ 2;
    final buffer = List<double>.filled(width, 0);

    final secondsPerPixel = totalDuration / width;

    for (double p in peaks) {
      double timeFromNow = p - elapsedTime; // if negative, already passed
      int x = (width - 1 - (timeFromNow / secondsPerPixel)).round();

      if (x >= 0 && x < width - 30) {
        for (int i = 0; i < 30; i++) {
          final pulse = math.exp(-math.pow((i - 15) / 4, 2));
          if (x + i < width) {
            buffer[x + i] += pulse;
          }
        }
      }
    }

    for (int x = 1; x < width; x++) {
      double y1 = centerY - buffer[x - 1] * 30;
      double y2 = centerY - buffer[x] * 30;
      canvas.drawLine(Offset(x - 1.0, y1), Offset(x.toDouble(), y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) =>
      oldDelegate.elapsedTime != elapsedTime;
}
