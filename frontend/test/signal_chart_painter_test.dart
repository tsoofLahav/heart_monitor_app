import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/game/signal_chart_painter.dart';

void main() {
  testWidgets(
      'peak dots stay on maxima when the scored interval is shorter than the signal',
      (tester) async {
    await tester.runAsync(() async {
      // Six seconds of returned samples, five seconds of measurement duration.
      // This reproduces the extra trailing buffer in quality practice.
      final signal = List<double>.filled(181, 0);
      const maxima = [30, 80, 130];
      for (final i in maxima) {
        signal[i - 1] = 0.5;
        signal[i] = 1;
        signal[i + 1] = 0.5;
      }
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      SignalWithPeaksPainter(
        signal: signal,
        realPeaks: maxima.map((i) => i / 30).toList(),
        duration: 5,
        sampleRate: 30,
      ).paint(canvas, const Size(360, 180));
      final picture = recorder.endRecording();
      final image = await picture.toImage(360, 180);
      final pixels =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      for (final index in maxima) {
        final x = index * 2; // sample index / 180 * width
        final offset = (2 * 360 + x) * 4;
        expect(pixels.getUint8(offset), greaterThan(200),
            reason: 'Red dot at waveform maximum $index');
        expect(pixels.getUint8(offset + 1), lessThan(160));
      }
      image.dispose();
      picture.dispose();
    });
  });

  test('changing the sample rate invalidates the chart', () {
    final signal = [0.0, 1.0, 0.0];
    final peaks = [1.0];
    final before = SignalWithPeaksPainter(
        signal: signal, realPeaks: peaks, duration: 2, sampleRate: 1);
    final after = SignalWithPeaksPainter(
        signal: signal, realPeaks: peaks, duration: 2, sampleRate: 2);
    expect(after.shouldRepaint(before), isTrue);
  });
}
