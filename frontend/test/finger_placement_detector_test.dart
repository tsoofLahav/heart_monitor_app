import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/recording/finger_frame_metrics.dart';
import 'package:heart_feedback/recording/finger_placement_detector.dart';

void main() {
  group('FingerPlacementDetector', () {
    test('confirms after baseline and stable finger-like frames', () async {
      final detector = FingerPlacementDetector();
      detector.begin();

      for (var i = 0; i < 4; i++) {
        detector.process(
          metricsFromLuminanceGrid(
            luminances: List<double>.filled(24, 200),
            skinRatio: 0.05,
          ),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 410));
      detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 200),
          skinRatio: 0.05,
        ),
      );
      expect(detector.phase, FingerWaitPhase.waitingFinger);

      var confirmed = false;
      for (var i = 0; i < FingerPlacementDetector.requiredConsecutiveHits; i++) {
        confirmed = detector.process(
          metricsFromLuminanceGrid(
            luminances: List<double>.filled(24, 120),
            skinRatio: 0.85,
          ),
        );
      }
      expect(confirmed, isFalse);
      expect(detector.phase, FingerWaitPhase.holding);

      await Future<void>.delayed(FingerPlacementDetector.holdDuration +
          const Duration(milliseconds: 10));
      confirmed = detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 120),
          skinRatio: 0.85,
        ),
      );
      expect(confirmed, isTrue);
      expect(detector.isConfirmed, isTrue);
    });

    test('resets consecutive hits when skin drops', () async {
      final detector = FingerPlacementDetector();
      detector.begin();

      for (var i = 0; i < 4; i++) {
        detector.process(
          metricsFromLuminanceGrid(
            luminances: List<double>.filled(24, 200),
            skinRatio: 0.05,
          ),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 410));
      detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 200),
          skinRatio: 0.05,
        ),
      );

      detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 120),
          skinRatio: 0.85,
        ),
      );
      detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 200),
          skinRatio: 0.1,
        ),
      );
      final confirmed = detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 120),
          skinRatio: 0.85,
        ),
      );
      expect(confirmed, isFalse);
    });

    test('beginFromPreStart skips baseline when pre-start samples exist', () async {
      final detector = FingerPlacementDetector();
      for (var i = 0; i < FingerPlacementDetector.minPreStartSamples; i++) {
        detector.feedPreStartBaseline(
          metricsFromLuminanceGrid(
            luminances: List<double>.filled(24, 200),
            skinRatio: 0.05,
          ),
        );
      }
      expect(detector.isPreStartBaselineReady, isTrue);

      detector.beginFromPreStart();
      expect(detector.phase, FingerWaitPhase.waitingFinger);

      var confirmed = false;
      for (var i = 0; i < FingerPlacementDetector.requiredConsecutiveHits; i++) {
        confirmed = detector.process(
          metricsFromLuminanceGrid(
            luminances: List<double>.filled(24, 120),
            skinRatio: 0.85,
          ),
        );
      }
      expect(confirmed, isFalse);
      expect(detector.phase, FingerWaitPhase.holding);

      await Future<void>.delayed(FingerPlacementDetector.holdDuration +
          const Duration(milliseconds: 10));
      confirmed = detector.process(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 120),
          skinRatio: 0.85,
        ),
      );
      expect(confirmed, isTrue);
    });

    test('feedPreStartBaseline ignores finger-on frames', () {
      final detector = FingerPlacementDetector();
      detector.feedPreStartBaseline(
        metricsFromLuminanceGrid(
          luminances: List<double>.filled(24, 120),
          skinRatio: 0.90,
        ),
      );
      expect(detector.isPreStartBaselineReady, isFalse);
    });
  });

  test('skin tone heuristic accepts orange-red', () {
    expect(isSkinToneForTest(180, 100, 80), isTrue);
    expect(isSkinToneForTest(40, 40, 200), isFalse);
  });
}
