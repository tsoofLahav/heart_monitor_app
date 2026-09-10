import 'dart:math';

import 'package:heart_feedback/game/session_score.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';

const int assessmentTotalSteps = 12;
const int assessmentCountTrialCount = 5;
const int assessmentMatchTrialCount = 6;
const int assessmentFirstNetSec = 15;
const int assessmentMatchNetSec = 20;
const int assessmentRelaxNetSec = 60;
const double assessmentMatchStartOffsetBpm = 15;
const List<int> assessmentHiddenNetSecs = [25, 35, 45, 60];

/// One count+confidence trial (steps 1–5).
class AssessmentTrialResult {
  final int netStableSec;
  final Map<String, dynamic> sessionData;
  final int guessedBeats;
  final double confidencePercent;

  const AssessmentTrialResult({
    required this.netStableSec,
    required this.sessionData,
    required this.guessedBeats,
    required this.confidencePercent,
  });

  int get actualPeaks => peaksCountFromSession(sessionData);

  double? get meanHrBpm => meanHrFromSession(sessionData);

  double get countScoreFraction => computeCountScoreOnly(
        guessedBeats: guessedBeats,
        actualBeats: actualPeaks,
        confidencePercent: confidencePercent,
      );
}

/// One slider-matching trial (steps 6–11).
class AssessmentMatchResult {
  final Map<String, dynamic> sessionData;
  final double measuredHrBpm;
  final double startBpm;
  final double matchedBpm;

  const AssessmentMatchResult({
    required this.sessionData,
    required this.measuredHrBpm,
    required this.startBpm,
    required this.matchedBpm,
  });

  double get hrError => (matchedBpm - measuredHrBpm).abs();

  double get accuracyFraction => hrAccuracyFromError(hrError);
}

/// Vitals from the final relax recording (step 12) — analysis only.
class AssessmentRelaxVitals {
  final double? meanHrBpm;
  final double? hrvRmssd;
  final double? ibiCv;
  final double? durationSeconds;
  final int? peaksCount;

  const AssessmentRelaxVitals({
    this.meanHrBpm,
    this.hrvRmssd,
    this.ibiCv,
    this.durationSeconds,
    this.peaksCount,
  });

  factory AssessmentRelaxVitals.fromSession(Map<String, dynamic> sessionData) {
    final quality = sessionData['quality'];
    double? numField(String key) {
      if (quality is! Map) return null;
      final v = quality[key];
      if (v == null) return null;
      return (v as num).toDouble();
    }

    return AssessmentRelaxVitals(
      meanHrBpm: meanHrFromSession(sessionData),
      hrvRmssd: numField('rmssd'),
      ibiCv: numField('ibi_cv'),
      durationSeconds: numField('duration_sec') ??
          (sessionData['duration_sec'] as num?)?.toDouble(),
      peaksCount: peaksCountFromSession(sessionData),
    );
  }
}

/// Build net lengths for count trials: 15s first, then shuffled 25/35/45/60.
List<int> buildAssessmentNetSchedule([Random? random]) {
  final r = random ?? Random();
  final rest = List<int>.from(assessmentHiddenNetSecs)..shuffle(r);
  return [assessmentFirstNetSec, ...rest];
}

/// Three +1 and three −1 signs, shuffled — applied as ±[assessmentMatchStartOffsetBpm].
List<int> buildMatchStartOffsetSigns([Random? random]) {
  final r = random ?? Random();
  final signs = <int>[1, 1, 1, -1, -1, -1]..shuffle(r);
  return signs;
}

double matchStartBpm(double measuredHrBpm, int offsetSign) {
  final start = measuredHrBpm + offsetSign * assessmentMatchStartOffsetBpm;
  return start.clamp(40.0, 150.0);
}

/// Mean HR across count trials that have a usable mean_hr_bpm.
double? averageHrFromTrials(List<AssessmentTrialResult> trials) {
  final hrs = <double>[];
  for (final t in trials) {
    final hr = t.meanHrBpm;
    if (hr != null && hr.isFinite && hr > 0) hrs.add(hr);
  }
  if (hrs.isEmpty) return null;
  return hrs.reduce((a, b) => a + b) / hrs.length;
}

/// HeartbeatScore 0–100 = mean count+confidence score across count trials.
double heartbeatScoreFromTrials(List<AssessmentTrialResult> trials) {
  if (trials.isEmpty) return 0;
  final sum = trials.fold<double>(0, (acc, t) => acc + t.countScoreFraction);
  return ((sum / trials.length) * 100).clamp(0.0, 100.0);
}

/// QuestionnaireScore 0–100 = mean slider match accuracy across match trials.
double questionnaireScoreFromMatches(List<AssessmentMatchResult> matches) {
  if (matches.isEmpty) return 0;
  final sum = matches.fold<double>(0, (acc, m) => acc + m.accuracyFraction);
  return ((sum / matches.length) * 100).clamp(0.0, 100.0);
}
