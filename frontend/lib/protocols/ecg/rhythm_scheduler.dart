/// Schedules beats at a constant BPM; BPM changes retime the *next* gap without silencing.
class RhythmScheduler {
  RhythmScheduler({required double bpm}) : _bpm = bpm {
    _nextBeatSec = 60 / bpm;
  }

  double _bpm;
  double _elapsedSec = 0;
  late double _nextBeatSec;
  final List<double> _beatTimes = [];

  double get bpm => _bpm;
  double get elapsedSec => _elapsedSec;
  List<double> get beatTimes => List.unmodifiable(_beatTimes);

  double get _ibi => 60 / _bpm;

  /// Advance clock; returns how many new beats occurred (for audio).
  int advanceTo(double elapsedSec) {
    _elapsedSec = elapsedSec;
    var newBeats = 0;
    while (_elapsedSec >= _nextBeatSec) {
      _beatTimes.add(_nextBeatSec);
      _nextBeatSec += _ibi;
      newBeats++;
    }
    _prune();
    return newBeats;
  }

  /// New tempo for upcoming beats.
  ///
  /// - Never fires an extra beat now.
  /// - Next beat is at most one new IBI from [now] (no long silence while scrubbing).
  /// - If a beat is already scheduled sooner, keep it so rhythm continues while sliding.
  void setBpm(double bpm) {
    if (bpm <= 0) return;
    if ((bpm - _bpm).abs() < 0.001) return;
    _bpm = bpm;
    final cap = _elapsedSec + _ibi;
    if (_nextBeatSec <= _elapsedSec) {
      _nextBeatSec = cap;
    } else if (_nextBeatSec > cap) {
      _nextBeatSec = cap;
    }
  }

  void _prune() {
    final cutoff = _elapsedSec - 12;
    while (_beatTimes.isNotEmpty && _beatTimes.first < cutoff) {
      _beatTimes.removeAt(0);
    }
  }
}
