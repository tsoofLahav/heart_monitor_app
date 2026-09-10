import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/protocols/ecg/rhythm_scheduler.dart';

void main() {
  test('beats keep firing while BPM changes if next beat is already soon', () {
    final s = RhythmScheduler(bpm: 60); // ibi 1s, first beat at t=1
    expect(s.advanceTo(0.5), 0);

    s.setBpm(120); // cap at 0.5+0.5=1.0, next still at 1.0
    expect(s.advanceTo(0.55), 0);
    expect(s.advanceTo(1.0), 1);
  });

  test('setBpm does not push next beat later than one new IBI from now', () {
    final s = RhythmScheduler(bpm: 40); // slow, ibi 1.5s
    s.advanceTo(0.0);
    s.setBpm(120); // fast, cap 0.5s from now
    expect(s.advanceTo(0.49), 0);
    expect(s.advanceTo(0.5), 1);
  });

  test('setBpm mid-run keeps imminent beat (rhythm while sliding)', () {
    final s = RhythmScheduler(bpm: 60);
    s.advanceTo(0.9);
    s.setBpm(90);
    expect(s.advanceTo(1.0), 1);
  });
}
