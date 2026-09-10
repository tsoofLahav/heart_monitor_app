import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

String recordingVoiceAsset(String language, String cue) =>
    'voice/${language.split(RegExp('[-_]')).first == 'he' ? 'he' : 'en'}_$cue.wav';

/// One voice at a time. Hints are throttled; important cues replace hints.
class RecordingVoice {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;
  int _generation = 0;
  DateTime? _lastHint;
  Completer<void>? _completion;
  StreamSubscription<void>? _subscription;

  Future<void> speak(String language, String cue, {bool hint = false}) async {
    if (_disposed || (hint && _completion != null)) return;
    if (hint &&
        _lastHint != null &&
        DateTime.now().difference(_lastHint!) < const Duration(seconds: 10)) {
      return;
    }
    if (hint) _lastHint = DateTime.now();
    final generation = ++_generation;
    _cancelCompletion();
    final completed = Completer<void>();
    _completion = completed;
    try {
      await _player.stop();
      if (_disposed || generation != _generation) return;
      _subscription = _player.onPlayerComplete.listen((_) {
        if (!completed.isCompleted) completed.complete();
      }, onError: (Object error) {
        if (!completed.isCompleted) completed.completeError(error);
      });
      // Attach the completion handler before playback can finish or fail.
      final playback =
          _player.play(AssetSource(recordingVoiceAsset(language, cue)));
      await Future.wait([playback, completed.future])
          .timeout(const Duration(seconds: 8));
    } finally {
      if (generation == _generation) {
        _cancelCompletion();
        await _player.stop();
      }
    }
  }

  void _cancelCompletion() {
    _subscription?.cancel();
    _subscription = null;
    final completion = _completion;
    _completion = null;
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  Future<void> stop() async {
    _generation++;
    _cancelCompletion();
    await _player.stop();
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _cancelCompletion();
    _player.dispose();
  }
}
