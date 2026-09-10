import 'package:heart_feedback/experiment/assessment_models.dart';
import 'package:heart_feedback/game/session_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assessment schedule starts with 15 then four unique lengths', () {
    final schedule = buildAssessmentNetSchedule();
    expect(schedule.length, 5);
    expect(schedule.first, 15);
    expect(schedule.skip(1).toSet(), {25, 35, 45, 60});
  });

  test('match start signs are three higher and three lower', () {
    final signs = buildMatchStartOffsetSigns();
    expect(signs.length, 6);
    expect(signs.where((s) => s == 1).length, 3);
    expect(signs.where((s) => s == -1).length, 3);
  });

  test('matchStartBpm applies ±15 and clamps', () {
    expect(matchStartBpm(72, 1), 87);
    expect(matchStartBpm(72, -1), 57);
    expect(matchStartBpm(40, -1), 40);
    expect(matchStartBpm(150, 1), 150);
  });

  test('heartbeat score averages count scores', () {
    final trials = [
      AssessmentTrialResult(
        netStableSec: 15,
        sessionData: {'peaks_count': 20},
        guessedBeats: 20,
        confidencePercent: 100,
      ),
      AssessmentTrialResult(
        netStableSec: 25,
        sessionData: {'peaks_count': 30},
        guessedBeats: 30,
        confidencePercent: 100,
      ),
    ];
    final expected = ((computeCountScoreOnly(
                  guessedBeats: 20,
                  actualBeats: 20,
                  confidencePercent: 100,
                ) +
                computeCountScoreOnly(
                  guessedBeats: 30,
                  actualBeats: 30,
                  confidencePercent: 100,
                )) /
            2) *
        100;
    expect(heartbeatScoreFromTrials(trials), closeTo(expected, 0.01));
  });

  test('questionnaire score averages match accuracy', () {
    final matches = [
      const AssessmentMatchResult(
        sessionData: {},
        measuredHrBpm: 72,
        startBpm: 57,
        matchedBpm: 72,
      ),
      const AssessmentMatchResult(
        sessionData: {},
        measuredHrBpm: 72,
        startBpm: 87,
        matchedBpm: 82,
      ),
    ];
    // Perfect + |82-72|/110 error
    final a1 = 1.0;
    final a2 = (1.0 - 10.0 / 110.0);
    expect(
      questionnaireScoreFromMatches(matches),
      closeTo(((a1 + a2) / 2) * 100, 0.01),
    );
  });

  test('relax vitals parse from session quality', () {
    final vitals = AssessmentRelaxVitals.fromSession({
      'peaks_count': 70,
      'quality': {
        'mean_hr_bpm': 68.5,
        'rmssd': 42.1,
        'ibi_cv': 0.04,
        'duration_sec': 60.0,
      },
    });
    expect(vitals.meanHrBpm, 68.5);
    expect(vitals.hrvRmssd, 42.1);
    expect(vitals.ibiCv, 0.04);
    expect(vitals.durationSeconds, 60.0);
    expect(vitals.peaksCount, 70);
  });
}
