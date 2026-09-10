class ExperimentProgress {
  final String participantCode;
  final int trialId;
  final String status;
  final int currentSession;
  final int trailStep;
  final List<int> completedSessionNumbers;
  final bool hasPreAssessment;
  final bool hasPostAssessment;

  /// Neutral training arm from server: `ppg` (real) or `audio` (control).
  /// Never stores or displays Condition wording.
  final String trainingMode;

  const ExperimentProgress({
    required this.participantCode,
    required this.trialId,
    required this.status,
    required this.currentSession,
    required this.trailStep,
    required this.completedSessionNumbers,
    required this.hasPreAssessment,
    required this.hasPostAssessment,
    this.trainingMode = 'ppg',
  });

  bool get usesAudioTraining => trainingMode == 'audio';

  bool get isCompleted =>
      status == 'completed' ||
      (hasPreAssessment &&
          hasPostAssessment &&
          completedSessionNumbers.length >= 8);

  /// Steps fully done for trail UI (0–10).
  int get completedTrailSteps {
    if (isCompleted) return 10;
    if (!hasPreAssessment) return 0;
    var n = 1;
    for (var s = 1; s <= 8; s++) {
      if (completedSessionNumbers.contains(s)) {
        n = s + 1;
      } else {
        break;
      }
    }
    if (hasPostAssessment) return 10;
    return n;
  }

  factory ExperimentProgress.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['completed_session_numbers'];
    final sessions = <int>[];
    if (rawSessions is List) {
      for (final item in rawSessions) {
        if (item is num) sessions.add(item.toInt());
      }
    }
    final mode = json['training_mode']?.toString().toLowerCase();
    return ExperimentProgress(
      participantCode: json['participant_code']?.toString() ?? '',
      trialId: (json['trial_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'not_started',
      currentSession: (json['current_session'] as num?)?.toInt() ?? 0,
      trailStep: (json['trail_step'] as num?)?.toInt() ?? 1,
      completedSessionNumbers: sessions,
      hasPreAssessment: json['has_pre_assessment'] == true,
      hasPostAssessment: json['has_post_assessment'] == true,
      trainingMode: mode == 'audio' ? 'audio' : 'ppg',
    );
  }

  Map<String, dynamic> toJson() => {
        'participant_code': participantCode,
        'trial_id': trialId,
        'status': status,
        'current_session': currentSession,
        'trail_step': trailStep,
        'completed_session_numbers': completedSessionNumbers,
        'has_pre_assessment': hasPreAssessment,
        'has_post_assessment': hasPostAssessment,
        'training_mode': trainingMode,
      };
}

/// Convert trail step (1–10) to training session number (1–8), or null for assessments.
int? trainingSessionForTrailStep(int trailStep) {
  if (trailStep >= 2 && trailStep <= 9) return trailStep - 1;
  return null;
}

bool isPreTrailStep(int trailStep) => trailStep == 1;

bool isPostTrailStep(int trailStep) => trailStep == 10;
