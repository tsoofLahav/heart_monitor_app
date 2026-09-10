import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/recording/recording_voice.dart';
import 'package:heart_feedback/recording/recording_screens.dart';
import 'package:heart_feedback/recording/recording_timing.dart';

void main() {
  test('each localized voice cue has a bundled nonempty WAV', () {
    for (final language in ['en', 'he']) {
      for (final cue in [
        'ready',
        'ready_count',
        'finished',
        'replace',
        'camera',
        'found'
      ]) {
        final asset = recordingVoiceAsset(language, cue);
        final bytes = File('assets/$asset').readAsBytesSync();
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(bytes.length, greaterThan(10000));
      }
    }
    expect(recordingVoiceAsset('he_IL', 'ready'), 'voice/he_ready.wav');
  });

  test('quality practice is silent and counting is explicit for assessments',
      () {
    expect(const LearnPracticeRecordingScreen().countingBeeps, isFalse);
    expect(
        const ProtocolRecordingScreen(maxSessionSeconds: 23, recordingNumber: 1)
            .countingBeeps,
        isTrue);
    expect(
        const ProtocolRecordingScreen(
                maxSessionSeconds: 63,
                recordingNumber: 12,
                countingBeeps: false)
            .countingBeeps,
        isFalse);
  });

  test('non-counting measurement preserves interval without playing beeps',
      () async {
    var now = Duration.zero;
    var beeps = 0;
    final interval = await runCountingCues(
      countingBeeps: false,
      countDuration: const Duration(seconds: 20),
      elapsed: () => now,
      wait: (duration) async {
        now += duration;
      },
      playCue: () async {
        beeps++;
        return now;
      },
      isActive: () => true,
    );
    expect(beeps, 0);
    expect(interval.startSeconds, 3);
    expect(interval.endSeconds, 23);
    expect(now, const Duration(seconds: 24));
  });
}
