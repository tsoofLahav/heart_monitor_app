import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local pulse-guide progress keyed by a stable per-install device id (no backend yet).
class PulseGuideProgressStore {
  PulseGuideProgressStore._();
  static final PulseGuideProgressStore instance = PulseGuideProgressStore._();

  static const _deviceIdKey = 'app_device_id';
  static const _progressKey = 'pulse_guide_progress_v1';

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<PulseGuideProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await getDeviceId();
    final raw = prefs.getString(_progressKey);
    if (raw == null || raw.isEmpty) {
      return PulseGuideProgress(
          deviceId: deviceId, completed: false, attempts: []);
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['deviceId']?.toString() != deviceId) {
        return PulseGuideProgress(
            deviceId: deviceId, completed: false, attempts: []);
      }
      return PulseGuideProgress.fromJson(map);
    } catch (_) {
      return PulseGuideProgress(
          deviceId: deviceId, completed: false, attempts: []);
    }
  }

  Future<bool> isGuideCompleted() async {
    final progress = await load();
    return progress.completed;
  }

  Future<bool> isInstructionsCompleted() async {
    final progress = await load();
    return progress.instructionsCompleted;
  }

  Future<bool> isCameraIdentifyCompleted() async {
    final progress = await load();
    return progress.cameraIdentifyCompleted;
  }

  Future<String?> getPreferredCameraName() async {
    final progress = await load();
    final name = progress.preferredCameraName;
    if (name == null || name.isEmpty) return null;
    return name;
  }

  Future<void> markInstructionsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await load();
    if (progress.instructionsCompleted) return;
    final updated = progress.copyWith(instructionsCompleted: true);
    await prefs.setString(_progressKey, jsonEncode(updated.toJson()));
  }

  Future<void> markCameraIdentified({required String cameraName}) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await load();
    final updated = progress.copyWith(
      cameraIdentifyCompleted: true,
      preferredCameraName: cameraName,
    );
    await prefs.setString(_progressKey, jsonEncode(updated.toJson()));
  }

  Future<void> recordAttempt({
    required int attemptNumber,
    required bool success,
    required int successStreakAfter,
    String? qualityLabel,
    bool notReading = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await load();
    final attempts = List<PulseGuideAttempt>.from(progress.attempts)
      ..add(
        PulseGuideAttempt(
          atUtc: DateTime.now().toUtc().toIso8601String(),
          attemptNumber: attemptNumber,
          success: success,
          successStreakAfter: successStreakAfter,
          qualityLabel: qualityLabel,
          notReading: notReading,
        ),
      );
    final updated = progress.copyWith(attempts: attempts);
    await prefs.setString(_progressKey, jsonEncode(updated.toJson()));
  }

  Future<void> markCompleted({required int totalAttempts}) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await load();
    final updated = progress.copyWith(
      completed: true,
      completedAtUtc: DateTime.now().toUtc().toIso8601String(),
      totalAttemptsAtCompletion: totalAttempts,
    );
    await prefs.setString(_progressKey, jsonEncode(updated.toJson()));
  }
}

class PulseGuideProgress {
  final String deviceId;
  final bool completed;
  final bool instructionsCompleted;
  final bool cameraIdentifyCompleted;
  final String? preferredCameraName;
  final String? completedAtUtc;
  final int? totalAttemptsAtCompletion;
  final List<PulseGuideAttempt> attempts;

  const PulseGuideProgress({
    required this.deviceId,
    required this.completed,
    this.instructionsCompleted = false,
    this.cameraIdentifyCompleted = false,
    this.preferredCameraName,
    this.completedAtUtc,
    this.totalAttemptsAtCompletion,
    this.attempts = const [],
  });

  factory PulseGuideProgress.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'];
    final attempts = <PulseGuideAttempt>[];
    if (rawAttempts is List) {
      for (final item in rawAttempts) {
        if (item is Map) {
          attempts
              .add(PulseGuideAttempt.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final qualityDone = json['completed'] == true;
    final preferred = json['preferredCameraName']?.toString();
    final cameraDone = json['cameraIdentifyCompleted'] == true ||
        (preferred != null && preferred.isNotEmpty);
    return PulseGuideProgress(
      deviceId: json['deviceId']?.toString() ?? '',
      completed: qualityDone,
      instructionsCompleted:
          json['instructionsCompleted'] == true || qualityDone,
      cameraIdentifyCompleted: cameraDone,
      preferredCameraName:
          preferred != null && preferred.isNotEmpty ? preferred : null,
      completedAtUtc: json['completedAtUtc']?.toString(),
      totalAttemptsAtCompletion:
          (json['totalAttemptsAtCompletion'] as num?)?.toInt(),
      attempts: attempts,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'completed': completed,
        'instructionsCompleted': instructionsCompleted,
        'cameraIdentifyCompleted': cameraIdentifyCompleted,
        if (preferredCameraName != null)
          'preferredCameraName': preferredCameraName,
        if (completedAtUtc != null) 'completedAtUtc': completedAtUtc,
        if (totalAttemptsAtCompletion != null)
          'totalAttemptsAtCompletion': totalAttemptsAtCompletion,
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };

  PulseGuideProgress copyWith({
    bool? completed,
    bool? instructionsCompleted,
    bool? cameraIdentifyCompleted,
    String? preferredCameraName,
    String? completedAtUtc,
    int? totalAttemptsAtCompletion,
    List<PulseGuideAttempt>? attempts,
  }) {
    return PulseGuideProgress(
      deviceId: deviceId,
      completed: completed ?? this.completed,
      instructionsCompleted:
          instructionsCompleted ?? this.instructionsCompleted,
      cameraIdentifyCompleted:
          cameraIdentifyCompleted ?? this.cameraIdentifyCompleted,
      preferredCameraName: preferredCameraName ?? this.preferredCameraName,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      totalAttemptsAtCompletion:
          totalAttemptsAtCompletion ?? this.totalAttemptsAtCompletion,
      attempts: attempts ?? this.attempts,
    );
  }
}

class PulseGuideAttempt {
  final String atUtc;
  final int attemptNumber;
  final bool success;
  final int successStreakAfter;
  final String? qualityLabel;
  final bool notReading;

  const PulseGuideAttempt({
    required this.atUtc,
    required this.attemptNumber,
    required this.success,
    required this.successStreakAfter,
    this.qualityLabel,
    this.notReading = false,
  });

  factory PulseGuideAttempt.fromJson(Map<String, dynamic> json) {
    return PulseGuideAttempt(
      atUtc: json['atUtc']?.toString() ?? '',
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 0,
      success: json['success'] == true,
      successStreakAfter: (json['successStreakAfter'] as num?)?.toInt() ?? 0,
      qualityLabel: json['qualityLabel']?.toString(),
      notReading: json['notReading'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'atUtc': atUtc,
        'attemptNumber': attemptNumber,
        'success': success,
        'successStreakAfter': successStreakAfter,
        if (qualityLabel != null) 'qualityLabel': qualityLabel,
        'notReading': notReading,
      };
}
