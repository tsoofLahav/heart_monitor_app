import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/protocols/control_beep_sequence.dart';

void main() {
  test('control beep sequence stays in resting ranges', () {
    final seq = generateControlBeepSequence(Random(42));
    expect(seq.durationSec >= 20 && seq.durationSec <= 40, isTrue);
    expect(seq.baseBpm >= 55 && seq.baseBpm <= 90, isTrue);
    expect(seq.actualBeatCount, greaterThan(5));
    expect(seq.meanBpm, greaterThan(40));
    expect(seq.meanBpm, lessThan(120));
    expect(seq.beatTimesSec.last, lessThanOrEqualTo(seq.durationSec + 0.01));
  });
}
