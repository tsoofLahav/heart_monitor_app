import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/recording/finger_frame_metrics.dart';

void main() {
  FingerFrameMetrics sample(int pixelStride, int padding) {
    final rowStride = 2 * pixelStride + padding;
    final u = Uint8List(rowStride * 2);
    final v = Uint8List(rowStride * 2);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        u[y * rowStride + x * pixelStride] = 100;
        v[y * rowStride + x * pixelStride] = 180;
      }
    }
    return metricsFromSampleInput(FingerFrameSampleInput(
      width: 4,
      height: 4,
      layout: FingerImageLayout.yuv420ThreePlane,
      yBytes: Uint8List.fromList(List.filled(16, 100)),
      yRowStride: 4,
      uBytes: u,
      vBytes: v,
      uRowStride: rowStride,
      vRowStride: rowStride,
      uPixelStride: pixelStride,
      vPixelStride: pixelStride,
    ))!;
  }

  test('Android interleaved chroma matches planar chroma including row padding',
      () {
    final planar = sample(1, 0);
    expect(planar.skinRatio, 1);
    for (final padding in [0, 4, 12]) {
      final interleaved = sample(2, padding);
      expect(interleaved.skinRatio, planar.skinRatio);
      expect(interleaved.meanLuminance, planar.meanLuminance);
      expect(interleaved.luminanceStdDev, planar.luminanceStdDev);
    }
  });
}
