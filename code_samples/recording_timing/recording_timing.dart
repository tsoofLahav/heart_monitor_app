/// Video buffers are outside the interval the participant counts.
const recordingWarmup = Duration(seconds: 3);
const recordingTail = Duration(seconds: 1);

class CountingCueWindow {
  final Duration start;
  final Duration end;
  const CountingCueWindow(this.start, this.end);

  double get startSeconds =>
      start.inMicroseconds / Duration.microsecondsPerSecond;
  double get endSeconds => end.inMicroseconds / Duration.microsecondsPerSecond;
}

/// [playCue] returns the monotonic timestamp immediately before requesting audio
/// playback. Native audio output latency must be checked on a physical device.
Future<CountingCueWindow> runCountingCues({
  required Duration countDuration,
  bool countingBeeps = true,
  required Duration Function() elapsed,
  required Future<void> Function(Duration) wait,
  required Future<Duration> Function() playCue,
  required bool Function() isActive,
}) async {
  Future<void> waitUntil(Duration target) async {
    final remaining = target - elapsed();
    if (remaining > Duration.zero) await wait(remaining);
    if (!isActive())
      throw StateError('Recording ended before counting completed');
  }

  await waitUntil(recordingWarmup);
  final start = countingBeeps ? await playCue() : elapsed();
  await waitUntil(start + countDuration);
  final end = countingBeeps ? await playCue() : elapsed();
  await waitUntil(end + recordingTail);
  return CountingCueWindow(start, end);
}

/// Require the backend to acknowledge the cue interval before scoring it.
/// Server timestamps are rounded to milliseconds.
bool backendMatchesCountingWindow(
    Map<String, dynamic> data, CountingCueWindow window) {
  final start = data['peak_window_start_sec'];
  final end = data['peak_window_end_sec'];
  return start is num &&
      end is num &&
      (start.toDouble() - window.startSeconds).abs() <= 0.002 &&
      (end.toDouble() - window.endSeconds).abs() <= 0.002;
}
