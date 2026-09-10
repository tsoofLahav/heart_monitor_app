// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileGroup => 'Group';

  @override
  String get profileGroupRegular => 'Regular';

  @override
  String get profileGroupControl => 'Control';

  @override
  String get sessionScoreTitle => 'Session score';

  @override
  String get matchingScore => 'Matching score';

  @override
  String get formNext => 'Next';

  @override
  String get soundStatusUnavailable =>
      'Sound settings could not be verified. Keep the app open while we check again.';

  @override
  String get recordingNoCountCaption =>
      'Keep your finger still until you are told to lift it.';

  @override
  String get continueAction => 'Continue';

  @override
  String get tryAgain => 'Try again';

  @override
  String get start => 'Start';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get na => 'N/A';

  @override
  String get backToMenu => 'Back to menu';

  @override
  String get end => 'End';

  @override
  String get reset => 'Reset';

  @override
  String get finish => 'Finish';

  @override
  String get nextRound => 'Next round';

  @override
  String get startAgain => 'Start again';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageSectionSubtitle => 'Choose the app language.';

  @override
  String get turnSoundOn => 'Turn sound on';

  @override
  String get soundGateBody =>
      'This app uses voice instructions and beeps. Turn off Silent mode, raise the volume, and check that you can hear the test sound.';

  @override
  String get phoneSilentVibrate => 'Phone is on Silent / Vibrate';

  @override
  String get ringerSwitchOk => 'Ring / Silent switch is OK';

  @override
  String get flipSilentSwitchHint =>
      'Flip the Silent switch off (or leave Vibrate).';

  @override
  String get volumeUpHint => 'Use the side buttons to turn volume up.';

  @override
  String get playTestBeep => 'Play test voice';

  @override
  String get waitingForSound => 'Waiting for sound…';

  @override
  String volumeLoudEnough(int percent) {
    return 'Volume is loud enough ($percent%)';
  }

  @override
  String volumeTooLow(int percent, int needPercent) {
    return 'Volume too low ($percent% — need $needPercent%+)';
  }

  @override
  String get welcomeToHeartMonitor => 'Welcome to\nHeart Monitor';

  @override
  String get personalHeartMonitor => 'Personal Heart Monitor';

  @override
  String get todaysPractice => 'Today\'s Practice';

  @override
  String get notAvailableInFlightTest => 'Not available in flight test';

  @override
  String get moreFlows => 'More flows';

  @override
  String get pulseReadingGuide => 'Pulse reading guide';

  @override
  String get finishGuideBeforeStart =>
      'Finish the pulse reading guide here before you start.';

  @override
  String get moreTitle => 'More';

  @override
  String get otherTrainingAndTools => 'Other training and tools';

  @override
  String get forestTrail => 'Forest trail';

  @override
  String get forestTrailSubtitle =>
      'PRE assessment, 8 training sessions, then POST.';

  @override
  String get preAssessmentTitle => 'Pre assessment';

  @override
  String get postAssessmentTitle => 'Post assessment';

  @override
  String get assessmentSessionHeaderPre => 'Session 1 — Pre assessment';

  @override
  String get assessmentSessionHeaderPost => 'Session 10 — Post assessment';

  @override
  String get leaveSessionTitle => 'Leave this session?';

  @override
  String leaveSessionBody(int number) {
    return 'You are leaving session $number. If you have not finished, you will have to start it over.';
  }

  @override
  String get leaveSessionConfirm => 'Leave';

  @override
  String get okAction => 'OK';

  @override
  String get controlStartSoundWhenReady => 'Start sound when ready';

  @override
  String get practiceIntroBody =>
      'Record your pulse as you learned.\n\nCount your heartbeats without touching your chest or pulse. Start at the first beep and stop at the second.\n\nThen enter your count and match the rhythm. Repeat for two rounds.';

  @override
  String get controlPracticeIntroBody =>
      'In this practice there are 2 rounds.\n\nIn each round close your eyes, listen to the beeps, and try to count them.\n\nAfterwards you will be asked to enter the number and match the rhythm you heard.';

  @override
  String sessionScoreLine(int score) {
    return 'Session score:\n$score%';
  }

  @override
  String trailSessionScoreBubble(int session, int score) {
    return 'Score session $session: $score';
  }

  @override
  String get preAssessmentIntro =>
      'You will record your pulse, count the beats you felt, and rate your confidence.\n\nThe first recording lasts 15 seconds. After that you will repeat the same steps a few more times (the length will vary and will not be shown).\n\nThen you will hear pairs of rhythms and choose which one matches yours.';

  @override
  String get postAssessmentIntro =>
      'Same evaluation as at the start: five pulse-count trials, then six rhythm choices.\n\nThe first recording lasts 15 seconds; the rest vary and hide the timer.';

  @override
  String get assessmentGateBody =>
      'This session has 12 steps and lasts around 10 minutes.\n\nNotice: once you start the session you cannot close it, or you will have to start from the beginning.';

  @override
  String get assessmentStep1Body =>
      'Record your pulse as you learned.\n\nCount your heartbeats while recording, without touching your chest or pulse.\n\nStart counting at the first beep and stop at the second.';

  @override
  String get assessmentAfterStep1Body =>
      'Repeat for four rounds of different lengths. Count between the beeps. Keep still until you are told to lift your finger.';

  @override
  String get assessmentHalfwayMatchBody =>
      'Next: six rhythm matches. Feel your heartbeat during each measurement—no counting or beeps. Wait for the voice, then match the rhythm.';

  @override
  String get assessmentRelaxBody =>
      'Relax for one minute. No counting or beeps. Keep your finger still until you are told to lift it.';

  @override
  String get assessmentGoodJob => 'Good job';

  @override
  String assessmentStartStep(int current, int total) {
    return 'Start step $current/$total';
  }

  @override
  String assessmentGoodJobStartStep(int current, int total) {
    return 'Good job, start step $current/$total.';
  }

  @override
  String assessmentStepProgress(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get assessmentAbandonTitle => 'Leave assessment?';

  @override
  String get assessmentAbandonBody =>
      'If you leave now you will have to start this assessment from the beginning.';

  @override
  String get assessmentAbandonConfirm => 'Leave';

  @override
  String get assessmentPreFinishBody =>
      'You have finished the first and longest step in your journey.\n\nNext steps will be much shorter. You need to finish 9 in two weeks, with at least one day gap between each step.';

  @override
  String get assessmentPostFinishBody =>
      'You have finished your journey.\n\nWe thank you for contributing to our study — it serves a great purpose.';

  @override
  String get nextAction => 'Next';

  @override
  String practiceSessionHeader(int number) {
    return 'Session $number';
  }

  @override
  String get assessmentRepeatBody =>
      'Count between the beeps, then enter your count and confidence.';

  @override
  String assessmentTrialProgress(int current, int total) {
    return 'Trial $current / $total';
  }

  @override
  String assessmentRhythmProgress(int current, int total) {
    return 'Rhythm question $current / $total';
  }

  @override
  String assessmentRhythmTitle(int current, int total) {
    return 'Rhythm $current / $total';
  }

  @override
  String get assessmentListeningA => 'Listen to rhythm A';

  @override
  String get assessmentListeningB => 'Listen to rhythm B';

  @override
  String get assessmentWhichRhythm => 'Which rhythm matches yours?';

  @override
  String get assessmentPickA => 'Rhythm A';

  @override
  String get assessmentPickB => 'Rhythm B';

  @override
  String assessmentSecondsLeft(int seconds) {
    return '${seconds}s';
  }

  @override
  String get assessmentPleaseWait => 'Please wait…';

  @override
  String get assessmentSaveFailed =>
      'Could not save assessment. Check your connection and try again.';

  @override
  String get experimentSessionSaveFailed =>
      'Could not save this session to the server. Check your connection and try again.';

  @override
  String get startPreAssessment => 'Start pre assessment';

  @override
  String get continueToPostAssessment => 'Continue to post assessment';

  @override
  String continueToTrainingSession(int number) {
    return 'Continue to session $number';
  }

  @override
  String get startTodaysSession => 'Start today\'s session';

  @override
  String get startSession => 'Start session';

  @override
  String get trailOpensTomorrow => 'Your session will open tomorrow';

  @override
  String experimentStepsDone(int completed, int total) {
    return '$completed / $total steps done';
  }

  @override
  String get experimentBootstrapFailed =>
      'Could not sync experiment progress. Using saved progress if available.';

  @override
  String get quickProtocolTest => 'Quick protocol test';

  @override
  String get quickProtocolTestSubtitle =>
      'Practice the full protocol without saving experiment progress.';

  @override
  String get saving => 'Saving…';

  @override
  String get pilote => 'Pilote';

  @override
  String get piloteSubtitle => 'Record and export session data.';

  @override
  String get setupAndQuality => 'Setup & quality';

  @override
  String get setupAndQualitySubtitle => 'Pulse guide and ML quality test.';

  @override
  String get protocolTest => 'Protocol test';

  @override
  String get protocolTestSubtitle =>
      'Full protocol with random 20–40s recordings.';

  @override
  String get sessions => 'Sessions';

  @override
  String get sessionDetails => 'Session Details';

  @override
  String get bpmOverTime => 'BPM Over Time';

  @override
  String get hrvOverTime => 'HRV Over Time';

  @override
  String get calibrationHubIntro =>
      'Learn finger placement and check signal quality before practice.';

  @override
  String get pulseGuideTileSubtitle => 'Instructions and quality practice.';

  @override
  String get qualityTest => 'Quality test';

  @override
  String get qualityTestSubtitle =>
      'One longer capture with ML quality breakdown.';

  @override
  String get pulseReadingGuideTitle => 'Pulse Reading Guide';

  @override
  String get preparation => 'Preparation';

  @override
  String get completeEachStepOnce =>
      'Complete each step once. You can reopen any step later.';

  @override
  String get cameraStep => 'Camera';

  @override
  String get cameraStepSubtitle => 'Find which rear lens to cover.';

  @override
  String get instructionsStep => 'Instructions';

  @override
  String get instructionsStepSubtitle => 'How to take a reading.';

  @override
  String get qualityPracticeStep => 'Quality practice';

  @override
  String get qualityPracticeStepSubtitle => 'Get 3 good readings in a row.';

  @override
  String get findYourCamera => 'Find your camera';

  @override
  String get findYourPulseCamera => 'Find your pulse camera';

  @override
  String get coverRearLensHint =>
      'Cover the camera until your finger fills the preview. Keep still and follow the voice.';

  @override
  String get noChangeTryNextCamera =>
      'No change? Try another lens, or tap Try next camera.';

  @override
  String get holdStillOnLens => 'Hold still on the lens…';

  @override
  String get tryNextCamera => 'Try next camera';

  @override
  String get thisIsYourPulseCamera => 'This is your pulse camera';

  @override
  String get remember => 'Remember';

  @override
  String get whichLensYouCovered =>
      ' which lens you covered — use that same one for every reading.';

  @override
  String get forgotLaterOpenCamera =>
      'Forgot later? Open Camera again in the Pulse Reading Guide.';

  @override
  String get noRearCameraFound => 'No rear camera found on this device.';

  @override
  String get couldNotOpenCamera =>
      'Could not open the camera. Check permissions and try again.';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get instructionCaption1 =>
      'Find a comfortable, quiet place with Wi‑Fi.';

  @override
  String get instructionCaption2 => 'Press Start, then flip the phone over.';

  @override
  String get instructionCaption3a =>
      'Rest your hand on the phone and cover the bottom lens with your finger.';

  @override
  String get instructionCaption3b =>
      'Listen to the voice and keep your finger still.';

  @override
  String get instructionCaption4a =>
      'Lift your finger only when the voice tells you to.';

  @override
  String get instructionCaption4b =>
      'Flip the phone back and continue with instructions.';

  @override
  String get readyForQualityPractice =>
      'Practice recording your pulse correctly.';

  @override
  String get nextYoullTakeShortReadings =>
      'Next you’ll take short readings until you get 3 good ones in a row.';

  @override
  String get instructionsTitle => 'Instructions';

  @override
  String get qualityPracticeTitle => 'Quality Practice';

  @override
  String get practiceResultTitle => 'Practice Result';

  @override
  String get tutorialCompleteTitle => 'Tutorial Complete';

  @override
  String get get3GoodReadings => 'Get 3 good readings in a row.';

  @override
  String get startPractice => 'Start Practice';

  @override
  String get practiceRetryHint =>
      'Try again. Keep your hand stable, finger on the camera, and don\'t move during recording.';

  @override
  String get tutorialComplete => 'Tutorial complete!';

  @override
  String get successful => 'SUCCESSFUL';

  @override
  String get notSuccessful => 'NOT SUCCESSFUL';

  @override
  String get qualityTestResult => 'Quality Test Result';

  @override
  String get noSignalData => 'No signal data';

  @override
  String get windowPredictions => 'Window predictions';

  @override
  String cameraOrdinalOfCount(int ordinal, int count) {
    return 'Camera $ordinal of $count';
  }

  @override
  String streakProgress(int current, int required) {
    return 'Streak: $current / $required';
  }

  @override
  String tutorialCompleteBody(int required, int attempts) {
    return 'You completed $required successful readings in a row after $attempts attempts.';
  }

  @override
  String readingQuality(String label) {
    return 'Reading quality: $label';
  }

  @override
  String probGoodBad(String good, String bad) {
    return 'P(good) = $good%  |  P(bad) = $bad%';
  }

  @override
  String durationAndPeaks(String duration, String peaks) {
    return 'Duration: ${duration}s  |  Peaks: $peaks';
  }

  @override
  String windowTimeRange(String start, String end) {
    return '${start}s – ${end}s';
  }

  @override
  String windowLabelProb(String label, String prob) {
    return '$label  ($prob% good)';
  }

  @override
  String get pressStartThenFlip =>
      'Press Start when you are ready, then flip the phone and cover the lens with your finger.\n\nFollow the voice instructions.';

  @override
  String get flashOnPreparing => 'Flash on — preparing…';

  @override
  String get liftFingerMoment => 'Lift your finger for a moment…';

  @override
  String get coverLensHoldStill => 'Cover the lens and hold still.';

  @override
  String get holdStill => 'Hold still…';

  @override
  String get fingerNotDetected =>
      'Finger not detected. Adjust placement or tap Cancel.';

  @override
  String get wrongCameraHint => 'Wrong camera. Try again with another camera.';

  @override
  String get preferredCameraPlacementHint =>
      'Cover the same rear lens you identified and hold still.';

  @override
  String get readingError => 'Reading error';

  @override
  String get badReadingDialogBody =>
      'Try again. Make sure your hand is resting stable, your finger is covering the camera, and you are not moving during recording.';

  @override
  String get piloteRecording => 'Pilote recording';

  @override
  String get qualityTestTitle => 'Quality Test';

  @override
  String get practiceReading => 'Practice Reading';

  @override
  String get protocolRecording => 'Protocol recording';

  @override
  String get processingDataWait => 'Processing data, wait for results';

  @override
  String get stopping => 'Stopping…';

  @override
  String get recordingInterrupted => 'Recording was interrupted.';

  @override
  String get recordingErrorRetry => 'Recording error. Please try again.';

  @override
  String get serverErrorRetry => 'Server error. Please try again.';

  @override
  String get networkErrorRetry => 'Network error. Please try again.';

  @override
  String get first => 'First';

  @override
  String get second => 'Second';

  @override
  String protocolRecordingCaption(String which) {
    return '$which recording — press Start when ready.';
  }

  @override
  String get training => 'Training';

  @override
  String get howThisWorks => 'How this works';

  @override
  String get twoRounds => 'Two rounds';

  @override
  String get twoRoundsBody =>
      'You will do two short recordings.\n\nAfter each one, you will count the beats you felt, rate your confidence, and match the presented rhythm to your own.';

  @override
  String get duringRecording => 'During recording';

  @override
  String get duringRecordingBody =>
      'Count your heartbeats between the two beeps, without touching your pulse or chest. Keep still until you are told to lift your finger.';

  @override
  String get controlTwoRoundsTitle => 'Two rounds';

  @override
  String get controlTwoRoundsBody =>
      'You will hear two beep sequences.\n\nAfter each one, enter how many beeps you counted, rate your confidence, then match the rhythm you heard.';

  @override
  String get controlDuringListeningTitle => 'While listening';

  @override
  String get controlDuringListeningBody =>
      'Close your eyes.\n\nCount every beep from start to finish.\n\nThen open your eyes and continue.';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get howManyBeatsCounted => 'How many beats did you count?';

  @override
  String get enterNumber => 'Enter number';

  @override
  String get howConfident => 'How confident are you?';

  @override
  String get slideTillRhythmMatches =>
      'Slide till the rhythm matches your own.';

  @override
  String get controlSlideTillRhythmMatches =>
      'Slide till the rhythm matches what you heard.';

  @override
  String controlListenTitle(int number) {
    return 'Round $number — Listen';
  }

  @override
  String get controlListeningBody =>
      'Close your eyes and count the beeps until they stop.';

  @override
  String get protocolSummary => 'Protocol summary';

  @override
  String get roundResults => 'Round results';

  @override
  String get targetNetDebug => 'Target net (debug)';

  @override
  String get actualBeats => 'Actual beats';

  @override
  String get yourCount => 'Your count';

  @override
  String get confidence => 'Confidence';

  @override
  String get countScore => 'Count score';

  @override
  String get sliderBpm => 'Slider BPM';

  @override
  String get measuredHr => 'Measured HR';

  @override
  String get hrError => 'HR error';

  @override
  String get hrAccuracy => 'HR accuracy';

  @override
  String get roundScore => 'Round score';

  @override
  String get preparingFinalScore => 'Preparing final score…';

  @override
  String roundFooter(int number, int total) {
    return 'Round $number/$total';
  }

  @override
  String roundCountBeatsTitle(int number) {
    return 'Round $number — Count beats';
  }

  @override
  String roundHeartRateTitle(int number) {
    return 'Round $number — Heart rate';
  }

  @override
  String roundSummaryTitle(int number) {
    return 'Round $number summary';
  }

  @override
  String roundLabel(int number) {
    return 'Round $number';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String secondsValue(String value) {
    return '$value s';
  }

  @override
  String get yourJourney => 'Your Journey';

  @override
  String get youReachedTheEnd => 'You reached the end!';

  @override
  String get allDone => 'All done!';

  @override
  String get startSession1 => 'Start session 1';

  @override
  String get resetProgressTitle => 'Reset progress?';

  @override
  String get resetProgressBody =>
      'This will clear all completed sessions and start from the beginning.';

  @override
  String get resetProgressTooltip => 'Reset progress';

  @override
  String allSessionsCompleted(int total) {
    return 'All $total sessions completed';
  }

  @override
  String sessionOfTotal(int current, int total) {
    return 'Session $current of $total';
  }

  @override
  String sessionsDone(int completed, int total) {
    return '$completed / $total sessions done';
  }

  @override
  String continueToSession(int number) {
    return 'Continue to session $number';
  }

  @override
  String sessionScoreCaption(int score) {
    return 'Your session score is $score%.\nThe clearer the image, the higher your score.';
  }

  @override
  String get noSessionData => 'No session data.';

  @override
  String get saveShare => 'Save / share';

  @override
  String get sessionName => 'Session name';

  @override
  String get fileNameWithoutPdf => 'File name (without .pdf)';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get savePdfToPhone => 'Save PDF to phone';

  @override
  String get sendToWhatsApp => 'Send to WhatsApp';

  @override
  String get openSessionDataList => 'Open Session Data list';

  @override
  String get sessionData => 'Session Data';

  @override
  String get viewSignal => 'View signal';

  @override
  String get noCleanSignal => 'No clean_signal in this session.';

  @override
  String get signalRealPeaksMarked => 'Signal (real peaks marked)';

  @override
  String get prepProfile => 'Profile';

  @override
  String get prepQuestionnaires => 'Questionnaires';

  @override
  String get prepCamera => 'Camera';

  @override
  String get prepQualityCheck => 'Quality check';

  @override
  String get prepTiming => 'Timing';

  @override
  String get finishPrepBeforeStart =>
      'Finish all four preparation steps below before you start.';

  @override
  String get prepOnboardingHint =>
      'Complete each step below. Tap the glowing icon to continue.';

  @override
  String get prepBubbleProfile => 'Fill personal details';

  @override
  String get prepBubbleQuestionnaire => 'Fill questionnaire';

  @override
  String get prepBubbleQuality => 'Complete quality check';

  @override
  String get prepBubbleTiming => 'Set your session schedule';

  @override
  String get prepTrainingTitle => 'Preparation for training';

  @override
  String prepStepsProgress(int done, int total) {
    return 'Completed $done of $total steps';
  }

  @override
  String get prepCardProfileTitle => 'Fill personal details';

  @override
  String get prepCardProfileSubtitle => 'Name and phone';

  @override
  String get prepCardQuestionnaireTitle => 'Questionnaire';

  @override
  String get prepCardQuestionnaireSubtitle => 'Will be added later';

  @override
  String get prepCardCameraTitle => 'Prepare the camera';

  @override
  String get prepCardCameraSubtitle => 'Short setup';

  @override
  String get prepCardQualityTitle =>
      'How to use the camera to read your pulse?';

  @override
  String get prepCardQualitySubtitle => 'Instructions and practice';

  @override
  String get prepCardCompleted => 'Completed';

  @override
  String get prepStartTraining => 'Start training';

  @override
  String get prepStartLockedHint => 'Available after preparation is complete';

  @override
  String get questionnaireComingSoon => 'Will be added later';

  @override
  String get approveAction => 'Approve';

  @override
  String get cameraFindTitle =>
      'Find the camera you will be using during the practice';

  @override
  String get cameraFindBody =>
      'Cover each rear camera in turn with your finger until your finger fills the preview.';

  @override
  String get cameraRememberTitle =>
      'Remember this is the camera for the practice';

  @override
  String get cameraRememberHint =>
      'If you forget later you can find this section in the bottom menu of the app.';

  @override
  String get pulseGuideComicsTitle => 'Your pulse reading steps';

  @override
  String get trailCoachBubble1 =>
      'There are 10 steps to do in 2 weeks. The first and last take about 10 minutes each; the others about 2 minutes.';

  @override
  String get trailCoachBubble2 =>
      'Each time, the next step will open 24 hours after you finish the current one.';

  @override
  String get trailCoachBubble3 =>
      'You may use our notifications system to set reminders for your sessions.';

  @override
  String get trailStepOpensIn24h => 'Opens 24 hours after previous step';

  @override
  String trailStepLockedHours(int hours, int minutes) {
    return 'This step unlocks in ${hours}h ${minutes}m';
  }

  @override
  String get protocolRecordingReadyCaption =>
      'Press Start when you are ready, then flip the phone and cover the lens with your finger.\n\nFollow the voice instructions.';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profileIncomplete =>
      'Please fill first name, last name, and phone.';

  @override
  String get profileSaveFailed =>
      'Could not sync profile to the server. Details are saved on this device.';

  @override
  String get appreciationTitleBefore => 'Before practice';

  @override
  String get appreciationTitleAfter => 'After practice';

  @override
  String get appreciationIntro =>
      'Please answer a few short questions. Your answers help us understand your experience.';

  @override
  String get appreciationSubmit => 'Submit answers';

  @override
  String get appreciationSaved => 'Answers saved.';

  @override
  String get appreciationSaveFailed =>
      'Could not save answers. Check your connection and try again.';

  @override
  String get appreciationQ1 =>
      'How motivated do you feel to notice your heartbeat? (1–5)';

  @override
  String get appreciationQ2 =>
      'How confident are you that you can feel your pulse? (1–5)';

  @override
  String get appreciationQ3 =>
      'Any brief note about how you feel today (optional)';

  @override
  String get timingTitle => 'Session schedule';

  @override
  String get timingIntro =>
      'You need to finish 10 sessions of the game in 2 weeks. The first and last sessions are approximately 10 minutes each; the others are approximately 2 minutes each.';

  @override
  String get timingNotificationsHint =>
      'You may use our notifications system to schedule reminders for your sessions.';

  @override
  String get timingScrollToReminders => 'Optional reminders — scroll down';

  @override
  String get timingRemindersSection => 'Reminder times';

  @override
  String get timingEnableReminders => 'Enable reminders & finish';

  @override
  String get timingFinish => 'Finish';

  @override
  String get timingFinishedNoNotifs =>
      'Preparation finished. Reminders are off.';

  @override
  String get timingIsraelNote =>
      'All times are in Israel time (Asia/Jerusalem).';

  @override
  String timingSessionLabel(int number) {
    return 'Session $number';
  }

  @override
  String get timingSessionKindPre => 'PRE assessment (~10 min)';

  @override
  String timingSessionKindTraining(int number) {
    return 'Training $number (~2 min)';
  }

  @override
  String get timingSessionKindPost => 'POST assessment (~10 min)';

  @override
  String get timingPickDate => 'Date';

  @override
  String get timingPickTime => 'Time';

  @override
  String get timingSave => 'Save schedule & reminders';

  @override
  String get timingSaved => 'Schedule saved.';

  @override
  String get timingSaveFailed =>
      'Could not sync schedule to the server. Reminders may still be set on this device.';

  @override
  String get timingNotifPermissionDenied =>
      'Notifications were denied. Schedule is saved, but reminders will not appear.';

  @override
  String get timingNotifTitle => 'Heart practice reminder';

  @override
  String timingNotifBody(int number, int minutes) {
    return 'Session $number is scheduled now (~$minutes min).';
  }
}
