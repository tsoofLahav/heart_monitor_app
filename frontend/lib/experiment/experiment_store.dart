import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:heart_feedback/calibration/pulse_guide_progress_store.dart';
import 'package:heart_feedback/experiment/experiment_api.dart';
import 'package:heart_feedback/experiment/experiment_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache + bootstrap for experiment progress (server is source of truth).
class ExperimentStore extends ChangeNotifier {
  ExperimentStore._();
  static final ExperimentStore instance = ExperimentStore._();

  static const _cacheKey = 'experiment_progress_v1';

  ExperimentProgress? _progress;
  bool _bootstrapping = false;
  String? _lastError;

  ExperimentProgress? get progress => _progress;
  bool get isBootstrapping => _bootstrapping;
  String? get lastError => _lastError;

  Future<String> clientInstallId() =>
      PulseGuideProgressStore.instance.getDeviceId();

  Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _progress = ExperimentProgress.fromJson(map);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist(ExperimentProgress progress) async {
    _progress = progress;
    _lastError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(progress.toJson()));
    notifyListeners();
  }

  /// Create or restore participant/trial on the server.
  Future<ExperimentProgress?> bootstrap() async {
    if (_bootstrapping) return _progress;
    _bootstrapping = true;
    notifyListeners();
    try {
      await loadCached();
      final id = await clientInstallId();
      final remote = await ExperimentApi.instance.bootstrap(id);
      if (remote != null) {
        await _persist(remote);
        return remote;
      }
      _lastError = 'bootstrap_failed';
      notifyListeners();
      return _progress;
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<ExperimentProgress?> refresh() async {
    final id = await clientInstallId();
    final remote = await ExperimentApi.instance.fetchProgress(id);
    if (remote != null) {
      await _persist(remote);
      return remote;
    }
    return _progress;
  }

  Future<ExperimentProgress?> saveAssessment({
    required String phase,
    double? heartbeatScore,
    double? questionnaireScore,
    double? relaxMeanHrBpm,
    double? relaxHrvRmssd,
    double? relaxIbiCv,
    double? relaxDurationSeconds,
    int? relaxPeaksCount,
  }) async {
    final current = _progress;
    if (current == null) return null;
    final id = await clientInstallId();
    final remote = await ExperimentApi.instance.saveAssessment(
      clientInstallId: id,
      trialId: current.trialId,
      phase: phase,
      heartbeatScore: heartbeatScore,
      questionnaireScore: questionnaireScore,
      relaxMeanHrBpm: relaxMeanHrBpm,
      relaxHrvRmssd: relaxHrvRmssd,
      relaxIbiCv: relaxIbiCv,
      relaxDurationSeconds: relaxDurationSeconds,
      relaxPeaksCount: relaxPeaksCount,
    );
    if (remote != null) {
      await _persist(remote);
      return remote;
    }
    return null;
  }

  Future<ExperimentProgress?> saveTrainingSession({
    required int sessionNumber,
    required int score,
    double? avgHeartRate,
    double? durationSeconds,
    double? accuracy,
  }) async {
    final current = _progress;
    if (current == null) return null;
    final id = await clientInstallId();
    final remote = await ExperimentApi.instance.saveSession(
      clientInstallId: id,
      trialId: current.trialId,
      sessionNumber: sessionNumber,
      score: score,
      avgHeartRate: avgHeartRate,
      durationSeconds: durationSeconds,
      accuracy: accuracy,
    );
    if (remote != null) {
      await _persist(remote);
      return remote;
    }
    return null;
  }

  Future<bool> updateParticipantProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? trainingMode,
  }) async {
    if (_progress == null) await bootstrap();
    if (_progress == null) return false;
    final id = await clientInstallId();
    final remote = await ExperimentApi.instance.updateParticipantProfile(
      clientInstallId: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      trainingMode: trainingMode,
    );
    if (remote != null &&
        (trainingMode == null || remote.trainingMode == trainingMode)) {
      await _persist(remote);
      return true;
    }
    return false;
  }

  Future<bool> saveAppreciationAnswers({
    required String phase,
    required List<Map<String, dynamic>> answers,
  }) async {
    if (_progress == null) {
      await bootstrap();
    }
    final progress = _progress;
    if (progress == null) return false;
    final id = await clientInstallId();
    final remote = await ExperimentApi.instance.saveAppreciation(
      clientInstallId: id,
      trialId: progress.trialId,
      phase: phase,
      answers: answers,
    );
    if (remote != null) {
      await _persist(remote);
      return true;
    }
    return false;
  }

  Future<bool> saveSessionSchedule(List<Map<String, dynamic>> slots) async {
    if (_progress == null) {
      await bootstrap();
    }
    final progress = _progress;
    if (progress == null) return false;
    final id = await clientInstallId();
    final remote = await ExperimentApi.instance.saveSessionSchedule(
      clientInstallId: id,
      trialId: progress.trialId,
      slots: slots,
    );
    if (remote != null) {
      await _persist(remote);
      return true;
    }
    return false;
  }
}
