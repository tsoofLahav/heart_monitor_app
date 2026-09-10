import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/game/session_score.dart';

void main() {
  group('computeCountScoreOnly', () {
    test('perfect confident count scores 100 percent', () {
      expect(
          computeCountScoreOnly(
              guessedBeats: 10, actualBeats: 10, confidencePercent: 100),
          1);
    });

    test('8 vs 10 at 90 percent confidence scores 76 percent', () {
      expect(
          computeCountScoreOnly(
              guessedBeats: 8, actualBeats: 10, confidencePercent: 90),
          closeTo(0.76, 0.001));
    });

    test('overconfidence lowers the score for an inaccurate count', () {
      final high = computeCountScoreOnly(
          guessedBeats: 5, actualBeats: 10, confidencePercent: 90);
      final low = computeCountScoreOnly(
          guessedBeats: 5, actualBeats: 10, confidencePercent: 20);
      expect(high, lessThan(low));
    });

    test('exact count still reflects confidence', () {
      expect(
          computeCountScoreOnly(
              guessedBeats: 10, actualBeats: 10, confidencePercent: 0),
          0.7);
    });
  });
}
