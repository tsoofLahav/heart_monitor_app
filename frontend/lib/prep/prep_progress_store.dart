import 'dart:convert';

import 'package:heart_feedback/calibration/pulse_guide_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local prep-step flags (profile, questionnaire).
/// Camera / quality completion is read live from [PulseGuideProgressStore].
/// Timing is optional and does not gate start.
class PrepProgressStore {
  PrepProgressStore._();
  static final PrepProgressStore instance = PrepProgressStore._();

  static const _key = 'prep_progress_v1';

  Future<PrepProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await PulseGuideProgressStore.instance.getDeviceId();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return PrepProgress(deviceId: deviceId);
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['deviceId']?.toString() != deviceId) {
        return PrepProgress(deviceId: deviceId);
      }
      return PrepProgress.fromJson(map);
    } catch (_) {
      return PrepProgress(deviceId: deviceId);
    }
  }

  Future<void> _save(PrepProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<void> markProfileCompleted() async {
    final progress = await load();
    if (progress.profileCompleted) return;
    await _save(progress.copyWith(profileCompleted: true));
  }

  Future<void> markQuestionnaireBeforeCompleted() async {
    final progress = await load();
    if (progress.questionnaireBeforeCompleted) return;
    await _save(progress.copyWith(questionnaireBeforeCompleted: true));
  }

  Future<void> markTimingCompleted() async {
    final progress = await load();
    if (progress.timingCompleted) return;
    await _save(progress.copyWith(timingCompleted: true));
  }

  Future<PrepStepStatus> status() async {
    final progress = await load();
    final camera =
        await PulseGuideProgressStore.instance.isCameraIdentifyCompleted();
    final quality = await PulseGuideProgressStore.instance.isGuideCompleted();
    return PrepStepStatus(
      profileCompleted: progress.profileCompleted,
      questionnaireBeforeCompleted: progress.questionnaireBeforeCompleted,
      cameraCompleted: camera,
      qualityCompleted: quality,
      timingCompleted: progress.timingCompleted,
    );
  }
}

class PrepProgress {
  final String deviceId;
  final bool profileCompleted;
  final bool questionnaireBeforeCompleted;
  final bool timingCompleted;

  const PrepProgress({
    required this.deviceId,
    this.profileCompleted = false,
    this.questionnaireBeforeCompleted = false,
    this.timingCompleted = false,
  });

  PrepProgress copyWith({
    bool? profileCompleted,
    bool? questionnaireBeforeCompleted,
    bool? timingCompleted,
  }) {
    return PrepProgress(
      deviceId: deviceId,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      questionnaireBeforeCompleted:
          questionnaireBeforeCompleted ?? this.questionnaireBeforeCompleted,
      timingCompleted: timingCompleted ?? this.timingCompleted,
    );
  }

  factory PrepProgress.fromJson(Map<String, dynamic> json) {
    return PrepProgress(
      deviceId: json['deviceId']?.toString() ?? '',
      profileCompleted: json['profileCompleted'] == true,
      questionnaireBeforeCompleted:
          json['questionnaireBeforeCompleted'] == true,
      timingCompleted: json['timingCompleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'profileCompleted': profileCompleted,
        'questionnaireBeforeCompleted': questionnaireBeforeCompleted,
        'timingCompleted': timingCompleted,
      };
}

class PrepStepStatus {
  final bool profileCompleted;
  final bool questionnaireBeforeCompleted;
  final bool cameraCompleted;
  final bool qualityCompleted;

  /// Optional; never required for [isComplete].
  final bool timingCompleted;

  const PrepStepStatus({
    required this.profileCompleted,
    required this.questionnaireBeforeCompleted,
    required this.cameraCompleted,
    required this.qualityCompleted,
    this.timingCompleted = false,
  });

  bool get isComplete =>
      profileCompleted &&
      questionnaireBeforeCompleted &&
      cameraCompleted &&
      qualityCompleted;

  int get completedMandatoryCount {
    var n = 0;
    if (profileCompleted) n++;
    if (questionnaireBeforeCompleted) n++;
    if (cameraCompleted) n++;
    if (qualityCompleted) n++;
    return n;
  }

  static const mandatoryTotal = 4;

  /// First incomplete mandatory step index 0..3, or null if all done.
  int? get firstIncompleteIndex {
    if (!profileCompleted) return 0;
    if (!questionnaireBeforeCompleted) return 1;
    if (!cameraCompleted) return 2;
    if (!qualityCompleted) return 3;
    return null;
  }
}
