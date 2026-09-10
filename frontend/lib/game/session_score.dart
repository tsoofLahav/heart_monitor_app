const double _overconfidencePenalty = 0.5;

/// Count-only score (0–1) for protocol guessing; ignores animation pick.
double computeCountScoreOnly({
  required int? guessedBeats,
  required int actualBeats,
  required double confidencePercent,
}) {
  final guess = guessedBeats ?? 0;
  final beatError = (guess - actualBeats).abs();
  final countAccuracy =
      (1.0 - beatError / actualBeats.clamp(1, 1 << 30)).clamp(0.0, 1.0);
  final confidenceNorm = (confidencePercent / 100.0).clamp(0.0, 1.0);

  if (beatError == 0) {
    return 0.7 + 0.3 * confidenceNorm;
  }
  final overconfidence = (confidenceNorm - countAccuracy).clamp(0.0, 1.0);
  return (countAccuracy * (1.0 - _overconfidencePenalty * overconfidence))
      .clamp(0.0, 1.0);
}
