import 'dart:math';

import 'package:heart_feedback/game/session_score.dart';

const int backendTrimSeconds = 3;
const int netStableMinSec = 20;
const int netStableMaxSec = 40;
const double hrSliderCenter = 0.5;
const double defaultSliderBpm = 90;

int videoSecondsForNetStable(int netStableSec) =>
    netStableSec + backendTrimSeconds;

int drawRandomNetStableSec([Random? random]) {
  final r = random ?? Random();
  return netStableMinSec + r.nextInt(netStableMaxSec - netStableMinSec + 1);
}

/// Maps slider position to BPM (left higher, right lower, center 90).
double bpmFromSliderValue(double t) {
  final clamped = t.clamp(0.0, 1.0);
  if (clamped <= hrSliderCenter) {
    return 150 + (90 - 150) * (clamped / hrSliderCenter);
  }
  return 90 + (40 - 90) * ((clamped - hrSliderCenter) / (1 - hrSliderCenter));
}

double sliderValueFromBpm(double bpm) {
  if (bpm >= 90) {
    return hrSliderCenter * (150 - bpm) / (150 - 90);
  }
  return hrSliderCenter + (1 - hrSliderCenter) * (90 - bpm) / (90 - 40);
}

/// Number of rhythm waypoints along the slider (changes apply when thumb crosses one).
const int hrSliderWaypointCount = 23;

int hrWaypointIndexFromSlider(double t) {
  final clamped = t.clamp(0.0, 1.0);
  if (hrSliderWaypointCount <= 1) return 0;
  // Round = stable zone while dragging; change when thumb is closer to next tick.
  return (clamped * (hrSliderWaypointCount - 1)).round().clamp(
        0,
        hrSliderWaypointCount - 1,
      );
}

double hrSliderValueForWaypoint(int waypointIndex) {
  if (hrSliderWaypointCount <= 1) return hrSliderCenter;
  final i = waypointIndex.clamp(0, hrSliderWaypointCount - 1);
  return i / (hrSliderWaypointCount - 1);
}

double bpmForWaypoint(int waypointIndex) {
  return bpmFromSliderValue(hrSliderValueForWaypoint(waypointIndex));
}

double? meanHrFromSession(Map<String, dynamic> sessionData) {
  final quality = sessionData['quality'];
  if (quality is! Map) return null;
  final v = quality['mean_hr_bpm'];
  if (v == null) return null;
  return (v as num).toDouble();
}

int peaksCountFromSession(Map<String, dynamic> sessionData) {
  return (sessionData['peaks_count'] as num?)?.toInt() ?? 0;
}

/// HR accuracy 0–1; max error span 110 BPM (40–150 range).
double hrAccuracyFromError(double hrError) {
  return (1.0 - hrError / 110.0).clamp(0.0, 1.0);
}

class ProtocolRound {
  final int roundIndex;
  final int netStableSec;
  final Map<String, dynamic> sessionData;
  final int guessedBeats;
  final double confidencePercent;
  final double sliderBpm;

  const ProtocolRound({
    required this.roundIndex,
    required this.netStableSec,
    required this.sessionData,
    required this.guessedBeats,
    required this.confidencePercent,
    required this.sliderBpm,
  });

  int get actualPeaks => peaksCountFromSession(sessionData);

  double? get meanHrBpm => meanHrFromSession(sessionData);

  double get hrError {
    final actual = meanHrBpm;
    if (actual == null) return double.nan;
    return (sliderBpm - actual).abs();
  }

  double get countScoreFraction => computeCountScoreOnly(
        guessedBeats: guessedBeats,
        actualBeats: actualPeaks,
        confidencePercent: confidencePercent,
      );

  double get hrScoreFraction {
    final actual = meanHrBpm;
    if (actual == null) return 0;
    if (hrError.isNaN) return 0;
    return hrAccuracyFromError(hrError);
  }

  /// Combined round score 0–1 (50% count, 50% HR).
  double get combinedScoreFraction =>
      0.5 * countScoreFraction + 0.5 * hrScoreFraction;

  int get combinedScorePercent =>
      (combinedScoreFraction * 100).round().clamp(0, 100);
}

/// Final step score: average of both rounds (0–100).
int protocolStepScore(List<ProtocolRound> rounds) {
  if (rounds.isEmpty) return 0;
  final sum = rounds.fold<double>(
    0,
    (acc, r) => acc + r.combinedScoreFraction,
  );
  return ((sum / rounds.length) * 100).round().clamp(0, 100);
}

/// Result returned to forest trail when [ProtocolFlowScreen.returnScoreToCaller].
class ProtocolSessionResult {
  final int score;
  final double? avgHeartRate;
  final double? durationSeconds;

  const ProtocolSessionResult({
    required this.score,
    this.avgHeartRate,
    this.durationSeconds,
  });
}

ProtocolSessionResult protocolSessionResultFromRounds(
    List<ProtocolRound> rounds) {
  final score = protocolStepScore(rounds);
  final hrs = <double>[];
  var duration = 0.0;
  for (final r in rounds) {
    final hr = r.meanHrBpm;
    if (hr != null && hr.isFinite && hr > 0) hrs.add(hr);
    duration += r.netStableSec;
  }
  return ProtocolSessionResult(
    score: score,
    avgHeartRate: hrs.isEmpty ? null : hrs.reduce((a, b) => a + b) / hrs.length,
    durationSeconds: duration > 0 ? duration : null,
  );
}

bool isBadProtocolReading(Map<String, dynamic> result) {
  if (result['not_reading'] == true) return true;
  final label = result['quality_label']?.toString();
  return label == 'bad';
}
