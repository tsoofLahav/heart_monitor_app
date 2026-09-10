import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heart_feedback/shell/app_colors.dart';

/// Scrolls ECG-style waveform from precomputed peak times (seconds).
class ECGPainter extends CustomPainter {
  final List<double> peaks;
  final double elapsedTime;
  final double totalDuration;

  static const double visibleWindowSeconds = 4.0;

  ECGPainter({
    required this.peaks,
    required this.elapsedTime,
    required this.totalDuration,
  });

  static double ecgShape(double dt) {
    final p = 0.08 * math.exp(-math.pow((dt + 0.2) / 0.045, 2));
    final q = -0.15 * math.exp(-math.pow((dt + 0.03) / 0.015, 2));
    final r = 1.0 * math.exp(-math.pow(dt / 0.018, 2));
    final s = -0.25 * math.exp(-math.pow((dt - 0.04) / 0.018, 2));
    final t = 0.25 * math.exp(-math.pow((dt - 0.28) / 0.07, 2));
    return p + q + r + s + t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = AppColors.accentTeal.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final linePaint = Paint()
      ..color = AppColors.accentTeal
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final amplitude = size.height * 0.35;
    final windowStart = elapsedTime - visibleWindowSeconds;

    Offset? prev;
    final totalPixels = size.width.toInt();

    for (int px = 0; px < totalPixels; px++) {
      final t = windowStart + (px / size.width) * visibleWindowSeconds;
      if (t > elapsedTime) break;

      double signal = 0.0;
      if (t >= 0) {
        for (final peakTime in peaks) {
          final dt = t - peakTime;
          if (dt >= -0.35 && dt <= 0.65) {
            signal += ecgShape(dt);
          }
        }
      }

      final y = centerY - signal * amplitude;
      final current = Offset(px.toDouble(), y);

      if (prev != null) {
        canvas.drawLine(prev, current, linePaint);
      }
      prev = current;
    }

    final cursorX = math.min(
      size.width,
      ((elapsedTime - windowStart) / visibleWindowSeconds) * size.width,
    );

    final cursorPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      cursorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) =>
      oldDelegate.elapsedTime != elapsedTime || oldDelegate.peaks != peaks;
}

/// Beat times for a constant BPM over [horizonSec] seconds.
List<double> peaksForConstantBpm(double bpm, {double horizonSec = 600}) {
  if (bpm <= 0) return const [];
  final ibi = 60.0 / bpm;
  final peaks = <double>[];
  for (double t = 0; t <= horizonSec; t += ibi) {
    peaks.add(t);
  }
  return peaks;
}
