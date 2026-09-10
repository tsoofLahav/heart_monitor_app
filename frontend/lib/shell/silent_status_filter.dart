/// A single interrupted iOS audio probe is not a silent-switch change.
/// Accept healthy readings immediately; require two consecutive failed readings.
class SilentStatusFilter {
  bool? _status;
  int _failures = 0;

  bool get pending => _status == null && _failures < 2;

  bool? update(bool? reading) {
    if (reading == false) {
      _failures = 0;
      _status = false;
    } else {
      _failures++;
      if (_failures >= 2) _status = reading;
    }
    return _status;
  }

  void reset() {
    _status = null;
    _failures = 0;
  }
}
