import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

import 'package:heart_feedback/protocols/ecg/ecg_painter.dart';
import 'package:heart_feedback/protocols/ecg/rhythm_scheduler.dart';

/// Live ECG driven by [RhythmScheduler] (BPM updates from outside).
class ConstantRhythmMonitor extends StatefulWidget {
  final RhythmScheduler scheduler;
  final double height;

  const ConstantRhythmMonitor({
    super.key,
    required this.scheduler,
    this.height = 180,
  });

  @override
  State<ConstantRhythmMonitor> createState() => _ConstantRhythmMonitorState();
}

class _ConstantRhythmMonitorState extends State<ConstantRhythmMonitor>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final sec = elapsed.inMicroseconds / 1e6;
    final newBeats = widget.scheduler.advanceTo(sec);
    for (var i = 0; i < newBeats; i++) {
      _player.play(AssetSource('beep.mp3'), volume: 0.6);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scheduler;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: ECGPainter(
          peaks: s.beatTimes,
          elapsedTime: s.elapsedSec,
          totalDuration: s.elapsedSec + 1,
        ),
        size: Size.infinite,
      ),
    );
  }
}
