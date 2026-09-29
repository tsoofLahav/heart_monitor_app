import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/recording/recording_timing.dart';

void main() {
  test('scoring requires server acknowledgement of the cue interval', () {
    const window = CountingCueWindow(Duration(seconds: 3), Duration(seconds: 23));
    expect(backendMatchesCountingWindow({
      'peak_window_start_sec': 3, 'peak_window_end_sec': 23,
    }, window), isTrue);
    expect(backendMatchesCountingWindow({
      'peak_window_start_sec': 3, 'peak_window_end_sec': 23.5,
    }, window), isFalse);
    expect(backendMatchesCountingWindow({}, window), isFalse);
  });

  test('counting cues exclude warmup and tail capture', () async {
    var now = Duration.zero;
    final cues = <Duration>[];
    final result = await runCountingCues(
      countDuration: const Duration(seconds: 20),
      elapsed: () => now,
      wait: (duration) async => now += duration,
      isActive: () => true,
      playCue: () async {
        cues.add(now);
        final onset = now;
        // Platform audio command completion does not lengthen the count timer.
        now += const Duration(milliseconds: 50);
        return onset;
      },
    );
    expect(cues, [const Duration(seconds: 3), const Duration(seconds: 23)]);
    expect(result.startSeconds, 3);
    expect(result.endSeconds, 23);
    expect(now, const Duration(seconds: 24));
  });

  test('delayed timer records actual cue interval', () async {
    var now = Duration.zero;
    final result = await runCountingCues(
      countDuration: const Duration(seconds: 60),
      elapsed: () => now,
      wait: (duration) async =>
          now += duration + const Duration(milliseconds: 10),
      isActive: () => true,
      playCue: () async => now,
    );
    expect(result.startSeconds, 3.01);
    expect(result.endSeconds, 63.02);
  });

  test('leaving during warmup does not play counting cues', () async {
    var now = Duration.zero;
    var active = true;
    var cues = 0;
    await expectLater(
        runCountingCues(
          countDuration: const Duration(seconds: 20),
          elapsed: () => now,
          wait: (duration) async {
            now += duration;
            active = false;
          },
          isActive: () => active,
          playCue: () async {
            cues++;
            return now;
          },
        ),
        throwsStateError);
    expect(cues, 0);
  });
}
