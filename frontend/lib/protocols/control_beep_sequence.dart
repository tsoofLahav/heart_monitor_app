import 'dart:math';

/// One generated control-group beep sequence (variable resting-HR rhythm).
class ControlBeepSequence {
  final double baseBpm;
  final double jitterFraction;
  final int durationSec;
  final List<double> beatTimesSec;

  const ControlBeepSequence({
    required this.baseBpm,
    required this.jitterFraction,
    required this.durationSec,
    required this.beatTimesSec,
  });

  int get actualBeatCount => beatTimesSec.length;

  /// Mean BPM from consecutive IBIs (falls back to baseBpm).
  double get meanBpm {
    if (beatTimesSec.length < 2) return baseBpm;
    var sumIbi = 0.0;
    for (var i = 1; i < beatTimesSec.length; i++) {
      sumIbi += beatTimesSec[i] - beatTimesSec[i - 1];
    }
    final meanIbi = sumIbi / (beatTimesSec.length - 1);
    if (meanIbi <= 0) return baseBpm;
    return 60.0 / meanIbi;
  }
}

/// Builds a variable IBI beep timeline for control training.
ControlBeepSequence generateControlBeepSequence([Random? random]) {
  final r = random ?? Random();
  final baseBpm = 55.0 + r.nextDouble() * 35.0; // 55–90
  final jitter = 0.04 + r.nextDouble() * 0.08; // 0.04–0.12
  final durationSec = 20 + r.nextInt(21); // 20–40 inclusive
  final meanIbi = 60.0 / baseBpm;

  final beats = <double>[];
  var t = meanIbi * (0.3 + r.nextDouble() * 0.4); // first beat slightly delayed
  while (t <= durationSec) {
    beats.add(t);
    final factor = 1.0 + (r.nextDouble() * 2 - 1) * jitter;
    final ibi = (meanIbi * factor).clamp(meanIbi * 0.7, meanIbi * 1.35);
    t += ibi;
  }

  return ControlBeepSequence(
    baseBpm: baseBpm,
    jitterFraction: jitter,
    durationSec: durationSec,
    beatTimesSec: beats,
  );
}
