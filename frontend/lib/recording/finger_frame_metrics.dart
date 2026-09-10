import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Metrics from one downsampled camera frame (YUV420).
class FingerFrameMetrics {
  final double meanLuminance;
  final double luminanceStdDev;
  final double skinRatio;

  const FingerFrameMetrics({
    required this.meanLuminance,
    required this.luminanceStdDev,
    required this.skinRatio,
  });
}

const int _grid = 32;

enum FingerImageLayout {
  bgra8888,
  yuv420ThreePlane,
  nv12InterleavedUv,
  unknown,
}

/// Serializable sample for isolate analysis.
class FingerFrameSampleInput {
  final int width;
  final int height;
  final FingerImageLayout layout;
  final Uint8List yBytes;
  final int yRowStride;
  final Uint8List? uvBytes;
  final int? uvRowStride;
  final Uint8List? uBytes;
  final int? uRowStride;
  final Uint8List? vBytes;
  final int? vRowStride;
  final int uPixelStride;
  final int vPixelStride;

  const FingerFrameSampleInput({
    required this.width,
    required this.height,
    required this.layout,
    required this.yBytes,
    required this.yRowStride,
    this.uvBytes,
    this.uvRowStride,
    this.uBytes,
    this.uRowStride,
    this.vBytes,
    this.vRowStride,
    this.uPixelStride = 1,
    this.vPixelStride = 1,
  });

  static FingerFrameSampleInput? fromCameraImage(CameraImage image) {
    if (image.planes.isEmpty) return null;

    final group = image.format.group;

    if (group == ImageFormatGroup.bgra8888 ||
        (image.planes.length == 1 && image.planes[0].bytesPerPixel == 4)) {
      final p = image.planes[0];
      return FingerFrameSampleInput(
        width: image.width,
        height: image.height,
        layout: FingerImageLayout.bgra8888,
        yBytes: Uint8List.fromList(p.bytes),
        yRowStride: p.bytesPerRow,
      );
    }

    final y = image.planes[0];

    if (image.planes.length == 2) {
      final uv = image.planes[1];
      return FingerFrameSampleInput(
        width: image.width,
        height: image.height,
        layout: FingerImageLayout.nv12InterleavedUv,
        yBytes: Uint8List.fromList(y.bytes),
        yRowStride: y.bytesPerRow,
        uvBytes: Uint8List.fromList(uv.bytes),
        uvRowStride: uv.bytesPerRow,
      );
    }

    if (image.planes.length >= 3) {
      final u = image.planes[1];
      final v = image.planes[2];
      return FingerFrameSampleInput(
        width: image.width,
        height: image.height,
        layout: FingerImageLayout.yuv420ThreePlane,
        yBytes: Uint8List.fromList(y.bytes),
        yRowStride: y.bytesPerRow,
        uBytes: Uint8List.fromList(u.bytes),
        uRowStride: u.bytesPerRow,
        uPixelStride: u.bytesPerPixel ?? 1,
        vBytes: Uint8List.fromList(v.bytes),
        vRowStride: v.bytesPerRow,
        vPixelStride: v.bytesPerPixel ?? 1,
      );
    }

    return FingerFrameSampleInput(
      width: image.width,
      height: image.height,
      layout: FingerImageLayout.unknown,
      yBytes: Uint8List.fromList(y.bytes),
      yRowStride: y.bytesPerRow,
    );
  }
}

FingerFrameMetrics? metricsFromSampleInput(FingerFrameSampleInput input) {
  switch (input.layout) {
    case FingerImageLayout.bgra8888:
      return _metricsFromBgra(
        width: input.width,
        height: input.height,
        bytes: input.yBytes,
        rowStride: input.yRowStride,
      );
    case FingerImageLayout.nv12InterleavedUv:
      return _metricsFromYuv(
        width: input.width,
        height: input.height,
        yBytes: input.yBytes,
        yRowStride: input.yRowStride,
        uvSample: (x, y) {
          final uv = input.uvBytes;
          final stride = input.uvRowStride;
          if (uv == null || stride == null) return null;
          final uvX = x ~/ 2;
          final uvY = y ~/ 2;
          final idx = uvY * stride + uvX * 2;
          if (idx + 1 >= uv.length) return null;
          return (uv[idx] - 128, uv[idx + 1] - 128);
        },
      );
    case FingerImageLayout.yuv420ThreePlane:
      return _metricsFromYuv(
        width: input.width,
        height: input.height,
        yBytes: input.yBytes,
        yRowStride: input.yRowStride,
        uvSample: (x, y) {
          final uPlane = input.uBytes;
          final vPlane = input.vBytes;
          final uStride = input.uRowStride;
          final vStride = input.vRowStride;
          if (uPlane == null ||
              vPlane == null ||
              uStride == null ||
              vStride == null) {
            return null;
          }
          final uvX = x ~/ 2;
          final uvY = y ~/ 2;
          final uIndex = uvY * uStride + uvX * input.uPixelStride;
          final vIndex = uvY * vStride + uvX * input.vPixelStride;
          if (uIndex >= uPlane.length || vIndex >= vPlane.length) return null;
          return (uPlane[uIndex] - 128, vPlane[vIndex] - 128);
        },
      );
    case FingerImageLayout.unknown:
      return _metricsFromYOnly(
          input.yBytes, input.yRowStride, input.width, input.height);
  }
}

Future<FingerFrameMetrics?> metricsFromCameraImageAsync(
    CameraImage image) async {
  final input = FingerFrameSampleInput.fromCameraImage(image);
  if (input == null) return null;
  return compute(metricsFromSampleInput, input);
}

FingerFrameMetrics? metricsFromCameraImage(CameraImage image) {
  final input = FingerFrameSampleInput.fromCameraImage(image);
  if (input == null) return null;
  return metricsFromSampleInput(input);
}

typedef _UvSample = (int u, int v)?;

FingerFrameMetrics? _metricsFromYuv({
  required int width,
  required int height,
  required List<int> yBytes,
  required int yRowStride,
  required _UvSample Function(int x, int y) uvSample,
}) {
  final luminances = <double>[];
  var skinCount = 0;
  var redDominantCount = 0;
  var total = 0;

  for (var gy = 0; gy < _grid; gy++) {
    for (var gx = 0; gx < _grid; gx++) {
      final x = ((gx + 0.5) / _grid * width).floor().clamp(0, width - 1);
      final y = ((gy + 0.5) / _grid * height).floor().clamp(0, height - 1);
      final yIndex = y * yRowStride + x;
      if (yIndex >= yBytes.length) continue;
      final yVal = yBytes[yIndex].toDouble();
      luminances.add(yVal);

      final uv = uvSample(x, y);
      if (uv != null) {
        final u = uv.$1.toDouble();
        final v = uv.$2.toDouble();
        final r = (yVal + 1.402 * v).clamp(0, 255).toDouble();
        final g = (yVal - 0.344 * u - 0.714 * v).clamp(0, 255).toDouble();
        final b = (yVal + 1.772 * u).clamp(0, 255).toDouble();
        if (_isSkinTone(r, g, b)) skinCount++;
        if (_isTorchFingerRed(r, g, b)) redDominantCount++;
      }
      total++;
    }
  }

  if (luminances.isEmpty || total == 0) return null;

  final mean = luminances.reduce((a, b) => a + b) / luminances.length;
  var sumSq = 0.0;
  for (final l in luminances) {
    final d = l - mean;
    sumSq += d * d;
  }
  final std = math.sqrt(sumSq / luminances.length);

  final skinRatio = skinCount / total;
  final redRatio = redDominantCount / total;
  final effectiveSkin = math.max(skinRatio, redRatio * 0.95);

  return FingerFrameMetrics(
    meanLuminance: mean,
    luminanceStdDev: std,
    skinRatio: effectiveSkin,
  );
}

FingerFrameMetrics? _metricsFromBgra({
  required int width,
  required int height,
  required List<int> bytes,
  required int rowStride,
}) {
  final luminances = <double>[];
  var skinCount = 0;
  var redDominantCount = 0;
  var total = 0;

  for (var gy = 0; gy < _grid; gy++) {
    for (var gx = 0; gx < _grid; gx++) {
      final x = ((gx + 0.5) / _grid * width).floor().clamp(0, width - 1);
      final y = ((gy + 0.5) / _grid * height).floor().clamp(0, height - 1);
      final i = y * rowStride + x * 4;
      if (i + 2 >= bytes.length) continue;
      final b = bytes[i].toDouble();
      final g = bytes[i + 1].toDouble();
      final r = bytes[i + 2].toDouble();
      final yVal = (0.299 * r + 0.587 * g + 0.114 * b);
      luminances.add(yVal);
      if (_isSkinTone(r, g, b)) skinCount++;
      if (_isTorchFingerRed(r, g, b)) redDominantCount++;
      total++;
    }
  }

  if (luminances.isEmpty || total == 0) return null;

  final mean = luminances.reduce((a, b) => a + b) / luminances.length;
  var sumSq = 0.0;
  for (final l in luminances) {
    final d = l - mean;
    sumSq += d * d;
  }
  final std = math.sqrt(sumSq / luminances.length);
  final skinRatio = skinCount / total;
  final redRatio = redDominantCount / total;

  return FingerFrameMetrics(
    meanLuminance: mean,
    luminanceStdDev: std,
    skinRatio: math.max(skinRatio, redRatio * 0.95),
  );
}

FingerFrameMetrics? _metricsFromYOnly(
  List<int> yBytes,
  int yRowStride,
  int width,
  int height,
) {
  final luminances = <double>[];
  for (var gy = 0; gy < _grid; gy++) {
    for (var gx = 0; gx < _grid; gx++) {
      final x = ((gx + 0.5) / _grid * width).floor().clamp(0, width - 1);
      final y = ((gy + 0.5) / _grid * height).floor().clamp(0, height - 1);
      final yIndex = y * yRowStride + x;
      if (yIndex >= yBytes.length) continue;
      luminances.add(yBytes[yIndex].toDouble());
    }
  }
  if (luminances.isEmpty) return null;
  final mean = luminances.reduce((a, b) => a + b) / luminances.length;
  var sumSq = 0.0;
  for (final l in luminances) {
    final d = l - mean;
    sumSq += d * d;
  }
  return FingerFrameMetrics(
    meanLuminance: mean,
    luminanceStdDev: math.sqrt(sumSq / luminances.length),
    skinRatio: 0,
  );
}

/// Torch + fingertip: strong red/orange even when classic skin rules fail.
bool _isTorchFingerRed(double r, double g, double b) {
  if (r < 100) return false;
  if (r <= g * 1.08) return false;
  if (r <= b * 1.25) return false;
  return true;
}

bool _isSkinTone(double r, double g, double b) {
  if (r < 55 || g < 28 || b < 12) return false;
  if (r <= g || r <= b) return false;
  if ((r - g).abs() < 10) return false;
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  if (maxC - minC < 10) return false;
  return true;
}

/// Test helper: metrics from flat luminance + optional uniform skin ratio override.
FingerFrameMetrics metricsFromLuminanceGrid({
  required List<double> luminances,
  double skinRatio = 0,
}) {
  final mean = luminances.reduce((a, b) => a + b) / luminances.length;
  var sumSq = 0.0;
  for (final l in luminances) {
    final d = l - mean;
    sumSq += d * d;
  }
  return FingerFrameMetrics(
    meanLuminance: mean,
    luminanceStdDev: math.sqrt(sumSq / luminances.length),
    skinRatio: skinRatio,
  );
}

bool isSkinToneForTest(double r, double g, double b) => _isSkinTone(r, g, b);

bool isTorchFingerRedForTest(double r, double g, double b) =>
    _isTorchFingerRed(r, g, b);
