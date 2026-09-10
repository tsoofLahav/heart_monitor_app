import 'package:heart_feedback/recording/finger_frame_metrics.dart';

enum FingerWaitPhase {
  idle,
  baseline,
  waitingFinger,
  holding,
  confirmed,
}

/// Detects fingertip coverage from torch-lit preview frames.
class FingerPlacementDetector {
  FingerWaitPhase phase = FingerWaitPhase.idle;

  static const Duration baselineDuration = Duration(milliseconds: 400);
  static const Duration holdDuration = Duration(milliseconds: 800);
  static const int minPreStartSamples = 5;
  static const int requiredConsecutiveHits = 7;
  static const double skinRatioThreshold = 0.70;
  static const double maxLuminanceStdDev = 35.0;
  static const double minBrightnessDelta = 15.0;
  static const double minRelativeBrightnessDelta = 0.10;
  static const double baselineSkinAbortRatio = 0.50;
  static const double preStartBaselineEmaAlpha = 0.15;

  double? _baselineLuminance;
  DateTime? _baselineStartedAt;
  DateTime? _holdStartedAt;
  int _consecutiveHits = 0;
  int _baselineSampleCount = 0;
  double _baselineSum = 0;

  double? _preStartBaselineLuminance;
  int _preStartSampleCount = 0;

  bool get isPreStartBaselineReady =>
      _preStartBaselineLuminance != null &&
      _preStartSampleCount >= minPreStartSamples;

  void reset() {
    resetAll();
  }

  void resetAll() {
    phase = FingerWaitPhase.idle;
    _baselineLuminance = null;
    _baselineStartedAt = null;
    _holdStartedAt = null;
    _consecutiveHits = 0;
    _baselineSampleCount = 0;
    _baselineSum = 0;
    resetPreStartBaseline();
  }

  void resetPreStartBaseline() {
    _preStartBaselineLuminance = null;
    _preStartSampleCount = 0;
  }

  void resetDetection() {
    phase = FingerWaitPhase.idle;
    _baselineLuminance = null;
    _baselineStartedAt = null;
    _holdStartedAt = null;
    _consecutiveHits = 0;
    _baselineSampleCount = 0;
    _baselineSum = 0;
  }

  /// Updates rolling open-lens baseline while the screen is idle (before Start).
  void feedPreStartBaseline(FingerFrameMetrics metrics) {
    if (phase != FingerWaitPhase.idle) return;
    if (metrics.skinRatio >= baselineSkinAbortRatio) return;

    final luminance = metrics.meanLuminance;
    final existing = _preStartBaselineLuminance;
    if (existing == null) {
      _preStartBaselineLuminance = luminance;
    } else {
      _preStartBaselineLuminance = existing * (1 - preStartBaselineEmaAlpha) +
          luminance * preStartBaselineEmaAlpha;
    }
    _preStartSampleCount++;
  }

  void begin() {
    resetDetection();
    phase = FingerWaitPhase.baseline;
    _baselineStartedAt = DateTime.now();
  }

  /// Starts finger wait using a pre-built baseline when available.
  void beginFromPreStart() {
    resetDetection();
    if (isPreStartBaselineReady) {
      _baselineLuminance = _preStartBaselineLuminance;
      phase = FingerWaitPhase.waitingFinger;
      return;
    }
    phase = FingerWaitPhase.baseline;
    _baselineStartedAt = DateTime.now();
  }

  bool get isConfirmed => phase == FingerWaitPhase.confirmed;

  bool _isFingerLikeFrame(FingerFrameMetrics metrics, double baseline) {
    final brightnessDelta = (metrics.meanLuminance - baseline).abs();
    final relativeDelta = baseline > 1 ? brightnessDelta / baseline : 0.0;
    final skinOk = metrics.skinRatio >= skinRatioThreshold;
    final uniformOk = metrics.luminanceStdDev <= maxLuminanceStdDev;
    final brightnessOk = brightnessDelta >= minBrightnessDelta ||
        relativeDelta >= minRelativeBrightnessDelta;
    return skinOk && uniformOk && brightnessOk;
  }

  /// Returns true when finger placement just became confirmed this frame.
  bool process(FingerFrameMetrics metrics) {
    if (phase == FingerWaitPhase.confirmed) return false;

    if (phase == FingerWaitPhase.baseline) {
      if (metrics.skinRatio >= baselineSkinAbortRatio) {
        _baselineStartedAt = DateTime.now();
        _baselineSampleCount = 0;
        _baselineSum = 0;
        return false;
      }
      _baselineSum += metrics.meanLuminance;
      _baselineSampleCount++;
      final elapsed = DateTime.now().difference(_baselineStartedAt!);
      if (elapsed >= baselineDuration && _baselineSampleCount > 0) {
        _baselineLuminance = _baselineSum / _baselineSampleCount;
        phase = FingerWaitPhase.waitingFinger;
      }
      return false;
    }

    if (phase == FingerWaitPhase.waitingFinger) {
      final baseline = _baselineLuminance;
      if (baseline == null) return false;

      if (_isFingerLikeFrame(metrics, baseline)) {
        _consecutiveHits++;
        if (_consecutiveHits >= requiredConsecutiveHits) {
          phase = FingerWaitPhase.holding;
          _holdStartedAt = DateTime.now();
        }
      } else {
        _consecutiveHits = 0;
      }
      return false;
    }

    if (phase == FingerWaitPhase.holding) {
      final baseline = _baselineLuminance;
      if (baseline == null) return false;

      if (!_isFingerLikeFrame(metrics, baseline)) {
        phase = FingerWaitPhase.waitingFinger;
        _consecutiveHits = 0;
        _holdStartedAt = null;
        return false;
      }

      final holdElapsed = DateTime.now().difference(_holdStartedAt!);
      if (holdElapsed >= holdDuration) {
        phase = FingerWaitPhase.confirmed;
        return true;
      }
    }

    return false;
  }
}
