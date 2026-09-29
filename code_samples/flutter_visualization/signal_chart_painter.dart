import 'package:flutter/material.dart';

/// Signal and peak times share the trimmed-signal origin. Use the sample rate
/// for horizontal scaling; the scored interval can be shorter than the signal.
/// [duration] is a fallback signal span for older payloads without FPS.
class SignalWithPeaksPainter extends CustomPainter {
  final List<double> signal;
  final List<double> realPeaks;
  final double duration;
  final double? sampleRate;

  SignalWithPeaksPainter({
    required this.signal,
    required this.realPeaks,
    required this.duration,
    this.sampleRate,
  });

  double get _effectiveDuration {
    final fps = sampleRate;
    if (fps != null && fps.isFinite && fps > 0 && signal.length > 1) {
      // The last sample is at (N - 1) / FPS, not N / FPS.
      return (signal.length - 1) / fps;
    }
    return duration.isFinite && duration > 0 ? duration : 1.0;
  }

  int _sampleIndexForTime(double timeSec) {
    if (signal.isEmpty) return 0;
    if (signal.length == 1) return 0;
    final frac = (timeSec / _effectiveDuration).clamp(0.0, 1.0);
    return (frac * (signal.length - 1)).round().clamp(0, signal.length - 1);
  }

  double _xForTime(double timeSec, double width) {
    return (timeSec / _effectiveDuration).clamp(0.0, 1.0) * width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (signal.isEmpty) return;

    final maxVal = signal.reduce((a, b) => a > b ? a : b);
    final minVal = signal.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() + 1e-6;

    double yForValue(double value) =>
        size.height - ((value - minVal) / range) * size.height;

    final signalPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < signal.length; i++) {
      final x = signal.length == 1
          ? size.width / 2
          : (i / (signal.length - 1)) * size.width;
      final y = yForValue(signal[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, signalPaint);

    final peakLinePaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.5;
    final peakDotPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    for (final peakTime in realPeaks) {
      if (!peakTime.isFinite || peakTime < 0 || peakTime > _effectiveDuration)
        continue;
      final x = _xForTime(peakTime, size.width);
      final idx = _sampleIndexForTime(peakTime);
      final y = yForValue(signal[idx]);

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), peakLinePaint);
      canvas.drawCircle(Offset(x, y), 5, peakDotPaint);
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SignalWithPeaksPainter oldDelegate) =>
      oldDelegate.signal != signal ||
      oldDelegate.realPeaks != realPeaks ||
      oldDelegate.duration != duration ||
      oldDelegate.sampleRate != sampleRate;
}
