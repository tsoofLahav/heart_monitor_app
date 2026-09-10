import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// QA skip tools for local testing.
///
/// Enabled when:
/// - running a **debug** build (`kDebugMode`), or
/// - launched with `--dart-define=QA_SKIP=true`
bool get qaSkipEnabled {
  const fromDefine = bool.fromEnvironment('QA_SKIP', defaultValue: false);
  return kDebugMode || fromDefine;
}

/// Local QA overrides (training arm, etc.). Never used in production paths
/// unless [qaSkipEnabled] is true.
class QaOverrides extends ChangeNotifier {
  QaOverrides._();
  static final QaOverrides instance = QaOverrides._();

  static const _trainingModeKey = 'qa_training_mode_override';

  /// `null` = use server; otherwise `ppg` or `audio`.
  String? _trainingModeOverride;
  bool _loaded = false;

  String? get trainingModeOverride => _trainingModeOverride;

  Future<void> load() async {
    if (!qaSkipEnabled) {
      _trainingModeOverride = null;
      _loaded = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_trainingModeKey);
    if (raw == 'ppg' || raw == 'audio') {
      _trainingModeOverride = raw;
    } else {
      _trainingModeOverride = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTrainingModeOverride(String? mode) async {
    if (mode != null && mode != 'ppg' && mode != 'audio') return;
    _trainingModeOverride = mode;
    notifyListeners();
    if (!qaSkipEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    if (mode == null) {
      await prefs.remove(_trainingModeKey);
    } else {
      await prefs.setString(_trainingModeKey, mode);
    }
  }

  /// Effective mode for launching training sessions.
  String effectiveTrainingMode(String serverMode) {
    if (!qaSkipEnabled || !_loaded) return serverMode;
    return _trainingModeOverride ?? serverMode;
  }
}

/// Synthetic good PPG-style payload for skipping recordings.
Map<String, dynamic> qaFakeSessionData({
  int peaksCount = 28,
  double meanHrBpm = 72,
  double? rmssd,
  double? ibiCv,
  double? durationSec,
}) {
  return {
    'peaks_count': peaksCount,
    'quality_label': 'good',
    'not_reading': false,
    'quality': {
      'mean_hr_bpm': meanHrBpm,
      'label': 'good',
      if (rmssd != null) 'rmssd': rmssd,
      if (ibiCv != null) 'ibi_cv': ibiCv,
      if (durationSec != null) 'duration_sec': durationSec,
    },
  };
}

/// Compact AppBar action that opens a menu of skip options.
class QaSkipMenuButton extends StatelessWidget {
  final List<PopupMenuEntry<VoidCallback>> entries;

  const QaSkipMenuButton({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (!qaSkipEnabled || entries.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<VoidCallback>(
      tooltip: 'QA skip',
      icon: const Icon(Icons.fast_forward, color: Colors.orangeAccent),
      onSelected: (action) => action(),
      itemBuilder: (_) => entries,
    );
  }
}

PopupMenuItem<VoidCallback> qaSkipItem(String label, VoidCallback onSkip) {
  return PopupMenuItem<VoidCallback>(
    value: onSkip,
    child: Text(label),
  );
}
