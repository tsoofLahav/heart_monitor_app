import 'package:uuid/uuid.dart';

class SessionDataManager {
  static final SessionDataManager _instance = SessionDataManager._internal();
  factory SessionDataManager() => _instance;
  SessionDataManager._internal();

  final List<double> _audioStartTimes = [];
  final Map<String, Map<String, dynamic>> _sessionData = {};
  final Map<String, String> _names = {};

  void addAudioStartSignal({required bool valid}) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _audioStartTimes.add(valid ? now : -1);
  }

  String saveSessionData(
    Map<String, dynamic> backendData, {
    DateTime? startedAtUtc,
  }) {
    final id = const Uuid().v4();
    final entry = <String, dynamic>{
      'backend': backendData,
      'audioStartTimes': List.of(_audioStartTimes),
    };
    if (startedAtUtc != null) {
      entry['startedAtUtc'] = startedAtUtc.toIso8601String();
    }
    _sessionData[id] = entry;
    _audioStartTimes.clear();
    return id;
  }

  void reset() {
    _audioStartTimes.clear();
  }

  Map<String, Map<String, dynamic>> get sessionData => _sessionData;
  Map<String, String> get names => _names;
}
