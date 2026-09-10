import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:heart_feedback/experiment/experiment_models.dart';
import 'package:heart_feedback/recording/backend_connection.dart';
import 'package:heart_feedback/recording/process_video_client.dart';
import 'package:http/http.dart' as http;

/// HTTPS client for experiment /data/* endpoints (same host as process_video).
class ExperimentApi {
  ExperimentApi._();
  static final ExperimentApi instance = ExperimentApi._();

  static const Duration _timeout = Duration(seconds: 45);

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$processVideoApiBase$path')
        .replace(queryParameters: query);
  }

  Future<ExperimentProgress?> bootstrap(String clientInstallId) async {
    if (!BackendConnection.isRecentlyWarm) {
      await BackendConnection.establishConnectionInBackground();
    }
    try {
      final response = await http
          .post(
            _uri('/data/bootstrap'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'client_install_id': clientInstallId}),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment bootstrap failed: $e');
      return null;
    }
  }

  Future<ExperimentProgress?> fetchProgress(String clientInstallId) async {
    try {
      final response = await http
          .get(
            _uri('/data/progress', {'client_install_id': clientInstallId}),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment progress failed: $e');
      return null;
    }
  }

  Future<ExperimentProgress?> saveAssessment({
    required String clientInstallId,
    required int trialId,
    required String phase,
    double? heartbeatScore,
    double? questionnaireScore,
    double? relaxMeanHrBpm,
    double? relaxHrvRmssd,
    double? relaxIbiCv,
    double? relaxDurationSeconds,
    int? relaxPeaksCount,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/data/assessments'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_install_id': clientInstallId,
              'trial_id': trialId,
              'phase': phase,
              if (heartbeatScore != null) 'heartbeat_score': heartbeatScore,
              if (questionnaireScore != null)
                'questionnaire_score': questionnaireScore,
              if (relaxMeanHrBpm != null) 'relax_mean_hr_bpm': relaxMeanHrBpm,
              if (relaxHrvRmssd != null) 'relax_hrv_rmssd': relaxHrvRmssd,
              if (relaxIbiCv != null) 'relax_ibi_cv': relaxIbiCv,
              if (relaxDurationSeconds != null)
                'relax_duration_seconds': relaxDurationSeconds,
              if (relaxPeaksCount != null) 'relax_peaks_count': relaxPeaksCount,
            }),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment saveAssessment failed: $e');
      return null;
    }
  }

  Future<ExperimentProgress?> saveSession({
    required String clientInstallId,
    required int trialId,
    required int sessionNumber,
    required int score,
    double? accuracy,
    double? avgHeartRate,
    double? durationSeconds,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/data/sessions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_install_id': clientInstallId,
              'trial_id': trialId,
              'session_number': sessionNumber,
              'score': score,
              if (accuracy != null) 'accuracy': accuracy,
              if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
              if (durationSeconds != null) 'duration_seconds': durationSeconds,
              'completed_at': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment saveSession failed: $e');
      return null;
    }
  }

  Future<ExperimentProgress?> updateParticipantProfile({
    required String clientInstallId,
    String? firstName,
    String? lastName,
    String? phone,
    String? name,
    int? age,
    String? trainingMode,
  }) async {
    try {
      final response = await http
          .patch(
            _uri('/data/participants/me'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_install_id': clientInstallId,
              if (firstName != null) 'first_name': firstName,
              if (lastName != null) 'last_name': lastName,
              if (phone != null) 'phone': phone,
              if (name != null) 'name': name,
              if (age != null) 'age': age,
              if (trainingMode != null) 'training_mode': trainingMode,
            }),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment updateParticipantProfile failed: $e');
      return null;
    }
  }

  Future<ExperimentProgress?> saveAppreciation({
    required String clientInstallId,
    required int trialId,
    required String phase,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/data/appreciations'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_install_id': clientInstallId,
              'trial_id': trialId,
              'phase': phase,
              'answers': answers,
            }),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment saveAppreciation failed: $e');
      return null;
    }
  }

  Future<ExperimentProgress?> saveSessionSchedule({
    required String clientInstallId,
    required int trialId,
    required List<Map<String, dynamic>> slots,
  }) async {
    try {
      final response = await http
          .put(
            _uri('/data/session-schedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_install_id': clientInstallId,
              'trial_id': trialId,
              'slots': slots,
            }),
          )
          .timeout(_timeout);
      return _decodeProgress(response);
    } catch (e) {
      debugPrint('experiment saveSessionSchedule failed: $e');
      return null;
    }
  }

  ExperimentProgress? _decodeProgress(http.Response response) {
    debugPrint('experiment API ${response.statusCode}: ${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return ExperimentProgress.fromJson(Map<String, dynamic>.from(decoded));
  }
}
