import 'package:heart_feedback/l10n/app_localizations.dart';

/// User-facing copy for recording / finger wait (lower lens wording).
class RecordingFingerCopy {
  RecordingFingerCopy._();

  static String idleCaption(AppLocalizations l10n) => l10n.pressStartThenFlip;

  static String idlePrompt(AppLocalizations l10n) => idleCaption(l10n);

  static String learnIdlePrompt(AppLocalizations l10n) => idleCaption(l10n);

  static String baselineHint(AppLocalizations l10n) => l10n.flashOnPreparing;

  static String baselineFingerOnHint(AppLocalizations l10n) =>
      l10n.liftFingerMoment;

  static String waitingFingerHint(AppLocalizations l10n) =>
      l10n.coverLensHoldStill;

  static String holdingFingerHint(AppLocalizations l10n) => l10n.holdStill;

  static String fingerWaitTimeoutHint(AppLocalizations l10n) =>
      l10n.fingerNotDetected;

  static String wrongCameraHint(AppLocalizations l10n) => l10n.wrongCameraHint;

  static String preferredCameraPlacementHint(AppLocalizations l10n) =>
      l10n.preferredCameraPlacementHint;

  static String protocolShortCaption(
      AppLocalizations l10n, int recordingNumber) {
    return l10n.protocolRecordingReadyCaption;
  }

  static String protocolInstruction(
          AppLocalizations l10n, int recordingNumber) =>
      protocolShortCaption(l10n, recordingNumber);
}
