import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @profileGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get profileGroup;

  /// No description provided for @profileGroupRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get profileGroupRegular;

  /// No description provided for @profileGroupControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get profileGroupControl;

  /// No description provided for @sessionScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Session score'**
  String get sessionScoreTitle;

  /// No description provided for @matchingScore.
  ///
  /// In en, this message translates to:
  /// **'Matching score'**
  String get matchingScore;

  /// No description provided for @formNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get formNext;

  /// No description provided for @soundStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sound settings could not be verified. Keep the app open while we check again.'**
  String get soundStatusUnavailable;

  /// No description provided for @recordingNoCountCaption.
  ///
  /// In en, this message translates to:
  /// **'Keep your finger still until you are told to lift it.'**
  String get recordingNoCountCaption;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to menu'**
  String get backToMenu;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get nextRound;

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHebrew.
  ///
  /// In en, this message translates to:
  /// **'עברית'**
  String get languageHebrew;

  /// No description provided for @languageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get languageSectionSubtitle;

  /// No description provided for @turnSoundOn.
  ///
  /// In en, this message translates to:
  /// **'Turn sound on'**
  String get turnSoundOn;

  /// No description provided for @soundGateBody.
  ///
  /// In en, this message translates to:
  /// **'This app uses voice instructions and beeps. Turn off Silent mode, raise the volume, and check that you can hear the test sound.'**
  String get soundGateBody;

  /// No description provided for @phoneSilentVibrate.
  ///
  /// In en, this message translates to:
  /// **'Phone is on Silent / Vibrate'**
  String get phoneSilentVibrate;

  /// No description provided for @ringerSwitchOk.
  ///
  /// In en, this message translates to:
  /// **'Ring / Silent switch is OK'**
  String get ringerSwitchOk;

  /// No description provided for @flipSilentSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Flip the Silent switch off (or leave Vibrate).'**
  String get flipSilentSwitchHint;

  /// No description provided for @volumeUpHint.
  ///
  /// In en, this message translates to:
  /// **'Use the side buttons to turn volume up.'**
  String get volumeUpHint;

  /// No description provided for @playTestBeep.
  ///
  /// In en, this message translates to:
  /// **'Play test voice'**
  String get playTestBeep;

  /// No description provided for @waitingForSound.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sound…'**
  String get waitingForSound;

  /// No description provided for @volumeLoudEnough.
  ///
  /// In en, this message translates to:
  /// **'Volume is loud enough ({percent}%)'**
  String volumeLoudEnough(int percent);

  /// No description provided for @volumeTooLow.
  ///
  /// In en, this message translates to:
  /// **'Volume too low ({percent}% — need {needPercent}%+)'**
  String volumeTooLow(int percent, int needPercent);

  /// No description provided for @welcomeToHeartMonitor.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nHeart Monitor'**
  String get welcomeToHeartMonitor;

  /// No description provided for @personalHeartMonitor.
  ///
  /// In en, this message translates to:
  /// **'Personal Heart Monitor'**
  String get personalHeartMonitor;

  /// No description provided for @todaysPractice.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Practice'**
  String get todaysPractice;

  /// No description provided for @notAvailableInFlightTest.
  ///
  /// In en, this message translates to:
  /// **'Not available in flight test'**
  String get notAvailableInFlightTest;

  /// No description provided for @moreFlows.
  ///
  /// In en, this message translates to:
  /// **'More flows'**
  String get moreFlows;

  /// No description provided for @pulseReadingGuide.
  ///
  /// In en, this message translates to:
  /// **'Pulse reading guide'**
  String get pulseReadingGuide;

  /// No description provided for @finishGuideBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Finish the pulse reading guide here before you start.'**
  String get finishGuideBeforeStart;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @otherTrainingAndTools.
  ///
  /// In en, this message translates to:
  /// **'Other training and tools'**
  String get otherTrainingAndTools;

  /// No description provided for @forestTrail.
  ///
  /// In en, this message translates to:
  /// **'Forest trail'**
  String get forestTrail;

  /// No description provided for @forestTrailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PRE assessment, 8 training sessions, then POST.'**
  String get forestTrailSubtitle;

  /// No description provided for @preAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre assessment'**
  String get preAssessmentTitle;

  /// No description provided for @postAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Post assessment'**
  String get postAssessmentTitle;

  /// No description provided for @assessmentSessionHeaderPre.
  ///
  /// In en, this message translates to:
  /// **'Session 1 — Pre assessment'**
  String get assessmentSessionHeaderPre;

  /// No description provided for @assessmentSessionHeaderPost.
  ///
  /// In en, this message translates to:
  /// **'Session 10 — Post assessment'**
  String get assessmentSessionHeaderPost;

  /// No description provided for @leaveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this session?'**
  String get leaveSessionTitle;

  /// No description provided for @leaveSessionBody.
  ///
  /// In en, this message translates to:
  /// **'You are leaving session {number}. If you have not finished, you will have to start it over.'**
  String leaveSessionBody(int number);

  /// No description provided for @leaveSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveSessionConfirm;

  /// No description provided for @okAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okAction;

  /// No description provided for @controlStartSoundWhenReady.
  ///
  /// In en, this message translates to:
  /// **'Start sound when ready'**
  String get controlStartSoundWhenReady;

  /// No description provided for @practiceIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Record your pulse as you learned.\n\nCount your heartbeats without touching your chest or pulse. Start at the first beep and stop at the second.\n\nThen enter your count and match the rhythm. Repeat for two rounds.'**
  String get practiceIntroBody;

  /// No description provided for @controlPracticeIntroBody.
  ///
  /// In en, this message translates to:
  /// **'In this practice there are 2 rounds.\n\nIn each round close your eyes, listen to the beeps, and try to count them.\n\nAfterwards you will be asked to enter the number and match the rhythm you heard.'**
  String get controlPracticeIntroBody;

  /// No description provided for @sessionScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Session score:\n{score}%'**
  String sessionScoreLine(int score);

  /// No description provided for @trailSessionScoreBubble.
  ///
  /// In en, this message translates to:
  /// **'Score session {session}: {score}'**
  String trailSessionScoreBubble(int session, int score);

  /// No description provided for @preAssessmentIntro.
  ///
  /// In en, this message translates to:
  /// **'You will record your pulse, count the beats you felt, and rate your confidence.\n\nThe first recording lasts 15 seconds. After that you will repeat the same steps a few more times (the length will vary and will not be shown).\n\nThen you will hear pairs of rhythms and choose which one matches yours.'**
  String get preAssessmentIntro;

  /// No description provided for @postAssessmentIntro.
  ///
  /// In en, this message translates to:
  /// **'Same evaluation as at the start: five pulse-count trials, then six rhythm choices.\n\nThe first recording lasts 15 seconds; the rest vary and hide the timer.'**
  String get postAssessmentIntro;

  /// No description provided for @assessmentGateBody.
  ///
  /// In en, this message translates to:
  /// **'This session has 12 steps and lasts around 10 minutes.\n\nNotice: once you start the session you cannot close it, or you will have to start from the beginning.'**
  String get assessmentGateBody;

  /// No description provided for @assessmentStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Record your pulse as you learned.\n\nCount your heartbeats while recording, without touching your chest or pulse.\n\nStart counting at the first beep and stop at the second.'**
  String get assessmentStep1Body;

  /// No description provided for @assessmentAfterStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Repeat for four rounds of different lengths. Count between the beeps. Keep still until you are told to lift your finger.'**
  String get assessmentAfterStep1Body;

  /// No description provided for @assessmentHalfwayMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Next: six rhythm matches. Feel your heartbeat during each measurement—no counting or beeps. Wait for the voice, then match the rhythm.'**
  String get assessmentHalfwayMatchBody;

  /// No description provided for @assessmentRelaxBody.
  ///
  /// In en, this message translates to:
  /// **'Relax for one minute. No counting or beeps. Keep your finger still until you are told to lift it.'**
  String get assessmentRelaxBody;

  /// No description provided for @assessmentGoodJob.
  ///
  /// In en, this message translates to:
  /// **'Good job'**
  String get assessmentGoodJob;

  /// No description provided for @assessmentStartStep.
  ///
  /// In en, this message translates to:
  /// **'Start step {current}/{total}'**
  String assessmentStartStep(int current, int total);

  /// No description provided for @assessmentGoodJobStartStep.
  ///
  /// In en, this message translates to:
  /// **'Good job, start step {current}/{total}.'**
  String assessmentGoodJobStartStep(int current, int total);

  /// No description provided for @assessmentStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String assessmentStepProgress(int current, int total);

  /// No description provided for @assessmentAbandonTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave assessment?'**
  String get assessmentAbandonTitle;

  /// No description provided for @assessmentAbandonBody.
  ///
  /// In en, this message translates to:
  /// **'If you leave now you will have to start this assessment from the beginning.'**
  String get assessmentAbandonBody;

  /// No description provided for @assessmentAbandonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get assessmentAbandonConfirm;

  /// No description provided for @assessmentPreFinishBody.
  ///
  /// In en, this message translates to:
  /// **'You have finished the first and longest step in your journey.\n\nNext steps will be much shorter. You need to finish 9 in two weeks, with at least one day gap between each step.'**
  String get assessmentPreFinishBody;

  /// No description provided for @assessmentPostFinishBody.
  ///
  /// In en, this message translates to:
  /// **'You have finished your journey.\n\nWe thank you for contributing to our study — it serves a great purpose.'**
  String get assessmentPostFinishBody;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// No description provided for @practiceSessionHeader.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String practiceSessionHeader(int number);

  /// No description provided for @assessmentRepeatBody.
  ///
  /// In en, this message translates to:
  /// **'Count between the beeps, then enter your count and confidence.'**
  String get assessmentRepeatBody;

  /// No description provided for @assessmentTrialProgress.
  ///
  /// In en, this message translates to:
  /// **'Trial {current} / {total}'**
  String assessmentTrialProgress(int current, int total);

  /// No description provided for @assessmentRhythmProgress.
  ///
  /// In en, this message translates to:
  /// **'Rhythm question {current} / {total}'**
  String assessmentRhythmProgress(int current, int total);

  /// No description provided for @assessmentRhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Rhythm {current} / {total}'**
  String assessmentRhythmTitle(int current, int total);

  /// No description provided for @assessmentListeningA.
  ///
  /// In en, this message translates to:
  /// **'Listen to rhythm A'**
  String get assessmentListeningA;

  /// No description provided for @assessmentListeningB.
  ///
  /// In en, this message translates to:
  /// **'Listen to rhythm B'**
  String get assessmentListeningB;

  /// No description provided for @assessmentWhichRhythm.
  ///
  /// In en, this message translates to:
  /// **'Which rhythm matches yours?'**
  String get assessmentWhichRhythm;

  /// No description provided for @assessmentPickA.
  ///
  /// In en, this message translates to:
  /// **'Rhythm A'**
  String get assessmentPickA;

  /// No description provided for @assessmentPickB.
  ///
  /// In en, this message translates to:
  /// **'Rhythm B'**
  String get assessmentPickB;

  /// No description provided for @assessmentSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String assessmentSecondsLeft(int seconds);

  /// No description provided for @assessmentPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get assessmentPleaseWait;

  /// No description provided for @assessmentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save assessment. Check your connection and try again.'**
  String get assessmentSaveFailed;

  /// No description provided for @experimentSessionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this session to the server. Check your connection and try again.'**
  String get experimentSessionSaveFailed;

  /// No description provided for @startPreAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start pre assessment'**
  String get startPreAssessment;

  /// No description provided for @continueToPostAssessment.
  ///
  /// In en, this message translates to:
  /// **'Continue to post assessment'**
  String get continueToPostAssessment;

  /// No description provided for @continueToTrainingSession.
  ///
  /// In en, this message translates to:
  /// **'Continue to session {number}'**
  String continueToTrainingSession(int number);

  /// No description provided for @startTodaysSession.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s session'**
  String get startTodaysSession;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSession;

  /// No description provided for @trailOpensTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Your session will open tomorrow'**
  String get trailOpensTomorrow;

  /// No description provided for @experimentStepsDone.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} steps done'**
  String experimentStepsDone(int completed, int total);

  /// No description provided for @experimentBootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync experiment progress. Using saved progress if available.'**
  String get experimentBootstrapFailed;

  /// No description provided for @quickProtocolTest.
  ///
  /// In en, this message translates to:
  /// **'Quick protocol test'**
  String get quickProtocolTest;

  /// No description provided for @quickProtocolTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice the full protocol without saving experiment progress.'**
  String get quickProtocolTestSubtitle;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @pilote.
  ///
  /// In en, this message translates to:
  /// **'Pilote'**
  String get pilote;

  /// No description provided for @piloteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record and export session data.'**
  String get piloteSubtitle;

  /// No description provided for @setupAndQuality.
  ///
  /// In en, this message translates to:
  /// **'Setup & quality'**
  String get setupAndQuality;

  /// No description provided for @setupAndQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pulse guide and ML quality test.'**
  String get setupAndQualitySubtitle;

  /// No description provided for @protocolTest.
  ///
  /// In en, this message translates to:
  /// **'Protocol test'**
  String get protocolTest;

  /// No description provided for @protocolTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full protocol with random 20–40s recordings.'**
  String get protocolTestSubtitle;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @bpmOverTime.
  ///
  /// In en, this message translates to:
  /// **'BPM Over Time'**
  String get bpmOverTime;

  /// No description provided for @hrvOverTime.
  ///
  /// In en, this message translates to:
  /// **'HRV Over Time'**
  String get hrvOverTime;

  /// No description provided for @calibrationHubIntro.
  ///
  /// In en, this message translates to:
  /// **'Learn finger placement and check signal quality before practice.'**
  String get calibrationHubIntro;

  /// No description provided for @pulseGuideTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instructions and quality practice.'**
  String get pulseGuideTileSubtitle;

  /// No description provided for @qualityTest.
  ///
  /// In en, this message translates to:
  /// **'Quality test'**
  String get qualityTest;

  /// No description provided for @qualityTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One longer capture with ML quality breakdown.'**
  String get qualityTestSubtitle;

  /// No description provided for @pulseReadingGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Pulse Reading Guide'**
  String get pulseReadingGuideTitle;

  /// No description provided for @preparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get preparation;

  /// No description provided for @completeEachStepOnce.
  ///
  /// In en, this message translates to:
  /// **'Complete each step once. You can reopen any step later.'**
  String get completeEachStepOnce;

  /// No description provided for @cameraStep.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraStep;

  /// No description provided for @cameraStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find which rear lens to cover.'**
  String get cameraStepSubtitle;

  /// No description provided for @instructionsStep.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsStep;

  /// No description provided for @instructionsStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How to take a reading.'**
  String get instructionsStepSubtitle;

  /// No description provided for @qualityPracticeStep.
  ///
  /// In en, this message translates to:
  /// **'Quality practice'**
  String get qualityPracticeStep;

  /// No description provided for @qualityPracticeStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get 3 good readings in a row.'**
  String get qualityPracticeStepSubtitle;

  /// No description provided for @findYourCamera.
  ///
  /// In en, this message translates to:
  /// **'Find your camera'**
  String get findYourCamera;

  /// No description provided for @findYourPulseCamera.
  ///
  /// In en, this message translates to:
  /// **'Find your pulse camera'**
  String get findYourPulseCamera;

  /// No description provided for @coverRearLensHint.
  ///
  /// In en, this message translates to:
  /// **'Cover the camera until your finger fills the preview. Keep still and follow the voice.'**
  String get coverRearLensHint;

  /// No description provided for @noChangeTryNextCamera.
  ///
  /// In en, this message translates to:
  /// **'No change? Try another lens, or tap Try next camera.'**
  String get noChangeTryNextCamera;

  /// No description provided for @holdStillOnLens.
  ///
  /// In en, this message translates to:
  /// **'Hold still on the lens…'**
  String get holdStillOnLens;

  /// No description provided for @tryNextCamera.
  ///
  /// In en, this message translates to:
  /// **'Try next camera'**
  String get tryNextCamera;

  /// No description provided for @thisIsYourPulseCamera.
  ///
  /// In en, this message translates to:
  /// **'This is your pulse camera'**
  String get thisIsYourPulseCamera;

  /// No description provided for @remember.
  ///
  /// In en, this message translates to:
  /// **'Remember'**
  String get remember;

  /// No description provided for @whichLensYouCovered.
  ///
  /// In en, this message translates to:
  /// **' which lens you covered — use that same one for every reading.'**
  String get whichLensYouCovered;

  /// No description provided for @forgotLaterOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Forgot later? Open Camera again in the Pulse Reading Guide.'**
  String get forgotLaterOpenCamera;

  /// No description provided for @noRearCameraFound.
  ///
  /// In en, this message translates to:
  /// **'No rear camera found on this device.'**
  String get noRearCameraFound;

  /// No description provided for @couldNotOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera. Check permissions and try again.'**
  String get couldNotOpenCamera;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @instructionCaption1.
  ///
  /// In en, this message translates to:
  /// **'Find a comfortable, quiet place with Wi‑Fi.'**
  String get instructionCaption1;

  /// No description provided for @instructionCaption2.
  ///
  /// In en, this message translates to:
  /// **'Press Start, then flip the phone over.'**
  String get instructionCaption2;

  /// No description provided for @instructionCaption3a.
  ///
  /// In en, this message translates to:
  /// **'Rest your hand on the phone and cover the bottom lens with your finger.'**
  String get instructionCaption3a;

  /// No description provided for @instructionCaption3b.
  ///
  /// In en, this message translates to:
  /// **'Listen to the voice and keep your finger still.'**
  String get instructionCaption3b;

  /// No description provided for @instructionCaption4a.
  ///
  /// In en, this message translates to:
  /// **'Lift your finger only when the voice tells you to.'**
  String get instructionCaption4a;

  /// No description provided for @instructionCaption4b.
  ///
  /// In en, this message translates to:
  /// **'Flip the phone back and continue with instructions.'**
  String get instructionCaption4b;

  /// No description provided for @readyForQualityPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice recording your pulse correctly.'**
  String get readyForQualityPractice;

  /// No description provided for @nextYoullTakeShortReadings.
  ///
  /// In en, this message translates to:
  /// **'Next you’ll take short readings until you get 3 good ones in a row.'**
  String get nextYoullTakeShortReadings;

  /// No description provided for @instructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsTitle;

  /// No description provided for @qualityPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality Practice'**
  String get qualityPracticeTitle;

  /// No description provided for @practiceResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Result'**
  String get practiceResultTitle;

  /// No description provided for @tutorialCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial Complete'**
  String get tutorialCompleteTitle;

  /// No description provided for @get3GoodReadings.
  ///
  /// In en, this message translates to:
  /// **'Get 3 good readings in a row.'**
  String get get3GoodReadings;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// No description provided for @practiceRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Try again. Keep your hand stable, finger on the camera, and don\'t move during recording.'**
  String get practiceRetryHint;

  /// No description provided for @tutorialComplete.
  ///
  /// In en, this message translates to:
  /// **'Tutorial complete!'**
  String get tutorialComplete;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'SUCCESSFUL'**
  String get successful;

  /// No description provided for @notSuccessful.
  ///
  /// In en, this message translates to:
  /// **'NOT SUCCESSFUL'**
  String get notSuccessful;

  /// No description provided for @qualityTestResult.
  ///
  /// In en, this message translates to:
  /// **'Quality Test Result'**
  String get qualityTestResult;

  /// No description provided for @noSignalData.
  ///
  /// In en, this message translates to:
  /// **'No signal data'**
  String get noSignalData;

  /// No description provided for @windowPredictions.
  ///
  /// In en, this message translates to:
  /// **'Window predictions'**
  String get windowPredictions;

  /// No description provided for @cameraOrdinalOfCount.
  ///
  /// In en, this message translates to:
  /// **'Camera {ordinal} of {count}'**
  String cameraOrdinalOfCount(int ordinal, int count);

  /// No description provided for @streakProgress.
  ///
  /// In en, this message translates to:
  /// **'Streak: {current} / {required}'**
  String streakProgress(int current, int required);

  /// No description provided for @tutorialCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You completed {required} successful readings in a row after {attempts} attempts.'**
  String tutorialCompleteBody(int required, int attempts);

  /// No description provided for @readingQuality.
  ///
  /// In en, this message translates to:
  /// **'Reading quality: {label}'**
  String readingQuality(String label);

  /// No description provided for @probGoodBad.
  ///
  /// In en, this message translates to:
  /// **'P(good) = {good}%  |  P(bad) = {bad}%'**
  String probGoodBad(String good, String bad);

  /// No description provided for @durationAndPeaks.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}s  |  Peaks: {peaks}'**
  String durationAndPeaks(String duration, String peaks);

  /// No description provided for @windowTimeRange.
  ///
  /// In en, this message translates to:
  /// **'{start}s – {end}s'**
  String windowTimeRange(String start, String end);

  /// No description provided for @windowLabelProb.
  ///
  /// In en, this message translates to:
  /// **'{label}  ({prob}% good)'**
  String windowLabelProb(String label, String prob);

  /// No description provided for @pressStartThenFlip.
  ///
  /// In en, this message translates to:
  /// **'Press Start when you are ready, then flip the phone and cover the lens with your finger.\n\nFollow the voice instructions.'**
  String get pressStartThenFlip;

  /// No description provided for @flashOnPreparing.
  ///
  /// In en, this message translates to:
  /// **'Flash on — preparing…'**
  String get flashOnPreparing;

  /// No description provided for @liftFingerMoment.
  ///
  /// In en, this message translates to:
  /// **'Lift your finger for a moment…'**
  String get liftFingerMoment;

  /// No description provided for @coverLensHoldStill.
  ///
  /// In en, this message translates to:
  /// **'Cover the lens and hold still.'**
  String get coverLensHoldStill;

  /// No description provided for @holdStill.
  ///
  /// In en, this message translates to:
  /// **'Hold still…'**
  String get holdStill;

  /// No description provided for @fingerNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Finger not detected. Adjust placement or tap Cancel.'**
  String get fingerNotDetected;

  /// No description provided for @wrongCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Wrong camera. Try again with another camera.'**
  String get wrongCameraHint;

  /// No description provided for @preferredCameraPlacementHint.
  ///
  /// In en, this message translates to:
  /// **'Cover the same rear lens you identified and hold still.'**
  String get preferredCameraPlacementHint;

  /// No description provided for @readingError.
  ///
  /// In en, this message translates to:
  /// **'Reading error'**
  String get readingError;

  /// No description provided for @badReadingDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Try again. Make sure your hand is resting stable, your finger is covering the camera, and you are not moving during recording.'**
  String get badReadingDialogBody;

  /// No description provided for @piloteRecording.
  ///
  /// In en, this message translates to:
  /// **'Pilote recording'**
  String get piloteRecording;

  /// No description provided for @qualityTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality Test'**
  String get qualityTestTitle;

  /// No description provided for @practiceReading.
  ///
  /// In en, this message translates to:
  /// **'Practice Reading'**
  String get practiceReading;

  /// No description provided for @protocolRecording.
  ///
  /// In en, this message translates to:
  /// **'Protocol recording'**
  String get protocolRecording;

  /// No description provided for @processingDataWait.
  ///
  /// In en, this message translates to:
  /// **'Processing data, wait for results'**
  String get processingDataWait;

  /// No description provided for @stopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get stopping;

  /// No description provided for @recordingInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Recording was interrupted.'**
  String get recordingInterrupted;

  /// No description provided for @recordingErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Recording error. Please try again.'**
  String get recordingErrorRetry;

  /// No description provided for @serverErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again.'**
  String get serverErrorRetry;

  /// No description provided for @networkErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkErrorRetry;

  /// No description provided for @first.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get first;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get second;

  /// No description provided for @protocolRecordingCaption.
  ///
  /// In en, this message translates to:
  /// **'{which} recording — press Start when ready.'**
  String protocolRecordingCaption(String which);

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @howThisWorks.
  ///
  /// In en, this message translates to:
  /// **'How this works'**
  String get howThisWorks;

  /// No description provided for @twoRounds.
  ///
  /// In en, this message translates to:
  /// **'Two rounds'**
  String get twoRounds;

  /// No description provided for @twoRoundsBody.
  ///
  /// In en, this message translates to:
  /// **'You will do two short recordings.\n\nAfter each one, you will count the beats you felt, rate your confidence, and match the presented rhythm to your own.'**
  String get twoRoundsBody;

  /// No description provided for @duringRecording.
  ///
  /// In en, this message translates to:
  /// **'During recording'**
  String get duringRecording;

  /// No description provided for @duringRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'Count your heartbeats between the two beeps, without touching your pulse or chest. Keep still until you are told to lift your finger.'**
  String get duringRecordingBody;

  /// No description provided for @controlTwoRoundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Two rounds'**
  String get controlTwoRoundsTitle;

  /// No description provided for @controlTwoRoundsBody.
  ///
  /// In en, this message translates to:
  /// **'You will hear two beep sequences.\n\nAfter each one, enter how many beeps you counted, rate your confidence, then match the rhythm you heard.'**
  String get controlTwoRoundsBody;

  /// No description provided for @controlDuringListeningTitle.
  ///
  /// In en, this message translates to:
  /// **'While listening'**
  String get controlDuringListeningTitle;

  /// No description provided for @controlDuringListeningBody.
  ///
  /// In en, this message translates to:
  /// **'Close your eyes.\n\nCount every beep from start to finish.\n\nThen open your eyes and continue.'**
  String get controlDuringListeningBody;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get iUnderstand;

  /// No description provided for @howManyBeatsCounted.
  ///
  /// In en, this message translates to:
  /// **'How many beats did you count?'**
  String get howManyBeatsCounted;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get enterNumber;

  /// No description provided for @howConfident.
  ///
  /// In en, this message translates to:
  /// **'How confident are you?'**
  String get howConfident;

  /// No description provided for @slideTillRhythmMatches.
  ///
  /// In en, this message translates to:
  /// **'Slide till the rhythm matches your own.'**
  String get slideTillRhythmMatches;

  /// No description provided for @controlSlideTillRhythmMatches.
  ///
  /// In en, this message translates to:
  /// **'Slide till the rhythm matches what you heard.'**
  String get controlSlideTillRhythmMatches;

  /// No description provided for @controlListenTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {number} — Listen'**
  String controlListenTitle(int number);

  /// No description provided for @controlListeningBody.
  ///
  /// In en, this message translates to:
  /// **'Close your eyes and count the beeps until they stop.'**
  String get controlListeningBody;

  /// No description provided for @protocolSummary.
  ///
  /// In en, this message translates to:
  /// **'Protocol summary'**
  String get protocolSummary;

  /// No description provided for @roundResults.
  ///
  /// In en, this message translates to:
  /// **'Round results'**
  String get roundResults;

  /// No description provided for @targetNetDebug.
  ///
  /// In en, this message translates to:
  /// **'Target net (debug)'**
  String get targetNetDebug;

  /// No description provided for @actualBeats.
  ///
  /// In en, this message translates to:
  /// **'Actual beats'**
  String get actualBeats;

  /// No description provided for @yourCount.
  ///
  /// In en, this message translates to:
  /// **'Your count'**
  String get yourCount;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @countScore.
  ///
  /// In en, this message translates to:
  /// **'Count score'**
  String get countScore;

  /// No description provided for @sliderBpm.
  ///
  /// In en, this message translates to:
  /// **'Slider BPM'**
  String get sliderBpm;

  /// No description provided for @measuredHr.
  ///
  /// In en, this message translates to:
  /// **'Measured HR'**
  String get measuredHr;

  /// No description provided for @hrError.
  ///
  /// In en, this message translates to:
  /// **'HR error'**
  String get hrError;

  /// No description provided for @hrAccuracy.
  ///
  /// In en, this message translates to:
  /// **'HR accuracy'**
  String get hrAccuracy;

  /// No description provided for @roundScore.
  ///
  /// In en, this message translates to:
  /// **'Round score'**
  String get roundScore;

  /// No description provided for @preparingFinalScore.
  ///
  /// In en, this message translates to:
  /// **'Preparing final score…'**
  String get preparingFinalScore;

  /// No description provided for @roundFooter.
  ///
  /// In en, this message translates to:
  /// **'Round {number}/{total}'**
  String roundFooter(int number, int total);

  /// No description provided for @roundCountBeatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {number} — Count beats'**
  String roundCountBeatsTitle(int number);

  /// No description provided for @roundHeartRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {number} — Heart rate'**
  String roundHeartRateTitle(int number);

  /// No description provided for @roundSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {number} summary'**
  String roundSummaryTitle(int number);

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundLabel(int number);

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(String value);

  /// No description provided for @secondsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String secondsValue(String value);

  /// No description provided for @yourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get yourJourney;

  /// No description provided for @youReachedTheEnd.
  ///
  /// In en, this message translates to:
  /// **'You reached the end!'**
  String get youReachedTheEnd;

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All done!'**
  String get allDone;

  /// No description provided for @startSession1.
  ///
  /// In en, this message translates to:
  /// **'Start session 1'**
  String get startSession1;

  /// No description provided for @resetProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset progress?'**
  String get resetProgressTitle;

  /// No description provided for @resetProgressBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear all completed sessions and start from the beginning.'**
  String get resetProgressBody;

  /// No description provided for @resetProgressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgressTooltip;

  /// No description provided for @allSessionsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All {total} sessions completed'**
  String allSessionsCompleted(int total);

  /// No description provided for @sessionOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Session {current} of {total}'**
  String sessionOfTotal(int current, int total);

  /// No description provided for @sessionsDone.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} sessions done'**
  String sessionsDone(int completed, int total);

  /// No description provided for @continueToSession.
  ///
  /// In en, this message translates to:
  /// **'Continue to session {number}'**
  String continueToSession(int number);

  /// No description provided for @sessionScoreCaption.
  ///
  /// In en, this message translates to:
  /// **'Your session score is {score}%.\nThe clearer the image, the higher your score.'**
  String sessionScoreCaption(int score);

  /// No description provided for @noSessionData.
  ///
  /// In en, this message translates to:
  /// **'No session data.'**
  String get noSessionData;

  /// No description provided for @saveShare.
  ///
  /// In en, this message translates to:
  /// **'Save / share'**
  String get saveShare;

  /// No description provided for @sessionName.
  ///
  /// In en, this message translates to:
  /// **'Session name'**
  String get sessionName;

  /// No description provided for @fileNameWithoutPdf.
  ///
  /// In en, this message translates to:
  /// **'File name (without .pdf)'**
  String get fileNameWithoutPdf;

  /// No description provided for @sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get sharePdf;

  /// No description provided for @savePdfToPhone.
  ///
  /// In en, this message translates to:
  /// **'Save PDF to phone'**
  String get savePdfToPhone;

  /// No description provided for @sendToWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Send to WhatsApp'**
  String get sendToWhatsApp;

  /// No description provided for @openSessionDataList.
  ///
  /// In en, this message translates to:
  /// **'Open Session Data list'**
  String get openSessionDataList;

  /// No description provided for @sessionData.
  ///
  /// In en, this message translates to:
  /// **'Session Data'**
  String get sessionData;

  /// No description provided for @viewSignal.
  ///
  /// In en, this message translates to:
  /// **'View signal'**
  String get viewSignal;

  /// No description provided for @noCleanSignal.
  ///
  /// In en, this message translates to:
  /// **'No clean_signal in this session.'**
  String get noCleanSignal;

  /// No description provided for @signalRealPeaksMarked.
  ///
  /// In en, this message translates to:
  /// **'Signal (real peaks marked)'**
  String get signalRealPeaksMarked;

  /// No description provided for @prepProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get prepProfile;

  /// No description provided for @prepQuestionnaires.
  ///
  /// In en, this message translates to:
  /// **'Questionnaires'**
  String get prepQuestionnaires;

  /// No description provided for @prepCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get prepCamera;

  /// No description provided for @prepQualityCheck.
  ///
  /// In en, this message translates to:
  /// **'Quality check'**
  String get prepQualityCheck;

  /// No description provided for @prepTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get prepTiming;

  /// No description provided for @finishPrepBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Finish all four preparation steps below before you start.'**
  String get finishPrepBeforeStart;

  /// No description provided for @prepOnboardingHint.
  ///
  /// In en, this message translates to:
  /// **'Complete each step below. Tap the glowing icon to continue.'**
  String get prepOnboardingHint;

  /// No description provided for @prepBubbleProfile.
  ///
  /// In en, this message translates to:
  /// **'Fill personal details'**
  String get prepBubbleProfile;

  /// No description provided for @prepBubbleQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Fill questionnaire'**
  String get prepBubbleQuestionnaire;

  /// No description provided for @prepBubbleQuality.
  ///
  /// In en, this message translates to:
  /// **'Complete quality check'**
  String get prepBubbleQuality;

  /// No description provided for @prepBubbleTiming.
  ///
  /// In en, this message translates to:
  /// **'Set your session schedule'**
  String get prepBubbleTiming;

  /// No description provided for @prepTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation for training'**
  String get prepTrainingTitle;

  /// No description provided for @prepStepsProgress.
  ///
  /// In en, this message translates to:
  /// **'Completed {done} of {total} steps'**
  String prepStepsProgress(int done, int total);

  /// No description provided for @prepCardProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Fill personal details'**
  String get prepCardProfileTitle;

  /// No description provided for @prepCardProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name and phone'**
  String get prepCardProfileSubtitle;

  /// No description provided for @prepCardQuestionnaireTitle.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get prepCardQuestionnaireTitle;

  /// No description provided for @prepCardQuestionnaireSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Will be added later'**
  String get prepCardQuestionnaireSubtitle;

  /// No description provided for @prepCardCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare the camera'**
  String get prepCardCameraTitle;

  /// No description provided for @prepCardCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short setup'**
  String get prepCardCameraSubtitle;

  /// No description provided for @prepCardQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use the camera to read your pulse?'**
  String get prepCardQualityTitle;

  /// No description provided for @prepCardQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instructions and practice'**
  String get prepCardQualitySubtitle;

  /// No description provided for @prepCardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get prepCardCompleted;

  /// No description provided for @prepStartTraining.
  ///
  /// In en, this message translates to:
  /// **'Start training'**
  String get prepStartTraining;

  /// No description provided for @prepStartLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Available after preparation is complete'**
  String get prepStartLockedHint;

  /// No description provided for @questionnaireComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Will be added later'**
  String get questionnaireComingSoon;

  /// No description provided for @approveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveAction;

  /// No description provided for @cameraFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find the camera you will be using during the practice'**
  String get cameraFindTitle;

  /// No description provided for @cameraFindBody.
  ///
  /// In en, this message translates to:
  /// **'Cover each rear camera in turn with your finger until your finger fills the preview.'**
  String get cameraFindBody;

  /// No description provided for @cameraRememberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remember this is the camera for the practice'**
  String get cameraRememberTitle;

  /// No description provided for @cameraRememberHint.
  ///
  /// In en, this message translates to:
  /// **'If you forget later you can find this section in the bottom menu of the app.'**
  String get cameraRememberHint;

  /// No description provided for @pulseGuideComicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pulse reading steps'**
  String get pulseGuideComicsTitle;

  /// No description provided for @trailCoachBubble1.
  ///
  /// In en, this message translates to:
  /// **'There are 10 steps to do in 2 weeks. The first and last take about 10 minutes each; the others about 2 minutes.'**
  String get trailCoachBubble1;

  /// No description provided for @trailCoachBubble2.
  ///
  /// In en, this message translates to:
  /// **'Each time, the next step will open 24 hours after you finish the current one.'**
  String get trailCoachBubble2;

  /// No description provided for @trailCoachBubble3.
  ///
  /// In en, this message translates to:
  /// **'You may use our notifications system to set reminders for your sessions.'**
  String get trailCoachBubble3;

  /// No description provided for @trailStepOpensIn24h.
  ///
  /// In en, this message translates to:
  /// **'Opens 24 hours after previous step'**
  String get trailStepOpensIn24h;

  /// No description provided for @trailStepLockedHours.
  ///
  /// In en, this message translates to:
  /// **'This step unlocks in {hours}h {minutes}m'**
  String trailStepLockedHours(int hours, int minutes);

  /// No description provided for @protocolRecordingReadyCaption.
  ///
  /// In en, this message translates to:
  /// **'Press Start when you are ready, then flip the phone and cover the lens with your finger.\n\nFollow the voice instructions.'**
  String get protocolRecordingReadyCaption;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @profileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please fill first name, last name, and phone.'**
  String get profileIncomplete;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync profile to the server. Details are saved on this device.'**
  String get profileSaveFailed;

  /// No description provided for @appreciationTitleBefore.
  ///
  /// In en, this message translates to:
  /// **'Before practice'**
  String get appreciationTitleBefore;

  /// No description provided for @appreciationTitleAfter.
  ///
  /// In en, this message translates to:
  /// **'After practice'**
  String get appreciationTitleAfter;

  /// No description provided for @appreciationIntro.
  ///
  /// In en, this message translates to:
  /// **'Please answer a few short questions. Your answers help us understand your experience.'**
  String get appreciationIntro;

  /// No description provided for @appreciationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get appreciationSubmit;

  /// No description provided for @appreciationSaved.
  ///
  /// In en, this message translates to:
  /// **'Answers saved.'**
  String get appreciationSaved;

  /// No description provided for @appreciationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save answers. Check your connection and try again.'**
  String get appreciationSaveFailed;

  /// No description provided for @appreciationQ1.
  ///
  /// In en, this message translates to:
  /// **'How motivated do you feel to notice your heartbeat? (1–5)'**
  String get appreciationQ1;

  /// No description provided for @appreciationQ2.
  ///
  /// In en, this message translates to:
  /// **'How confident are you that you can feel your pulse? (1–5)'**
  String get appreciationQ2;

  /// No description provided for @appreciationQ3.
  ///
  /// In en, this message translates to:
  /// **'Any brief note about how you feel today (optional)'**
  String get appreciationQ3;

  /// No description provided for @timingTitle.
  ///
  /// In en, this message translates to:
  /// **'Session schedule'**
  String get timingTitle;

  /// No description provided for @timingIntro.
  ///
  /// In en, this message translates to:
  /// **'You need to finish 10 sessions of the game in 2 weeks. The first and last sessions are approximately 10 minutes each; the others are approximately 2 minutes each.'**
  String get timingIntro;

  /// No description provided for @timingNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'You may use our notifications system to schedule reminders for your sessions.'**
  String get timingNotificationsHint;

  /// No description provided for @timingScrollToReminders.
  ///
  /// In en, this message translates to:
  /// **'Optional reminders — scroll down'**
  String get timingScrollToReminders;

  /// No description provided for @timingRemindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get timingRemindersSection;

  /// No description provided for @timingEnableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders & finish'**
  String get timingEnableReminders;

  /// No description provided for @timingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get timingFinish;

  /// No description provided for @timingFinishedNoNotifs.
  ///
  /// In en, this message translates to:
  /// **'Preparation finished. Reminders are off.'**
  String get timingFinishedNoNotifs;

  /// No description provided for @timingIsraelNote.
  ///
  /// In en, this message translates to:
  /// **'All times are in Israel time (Asia/Jerusalem).'**
  String get timingIsraelNote;

  /// No description provided for @timingSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String timingSessionLabel(int number);

  /// No description provided for @timingSessionKindPre.
  ///
  /// In en, this message translates to:
  /// **'PRE assessment (~10 min)'**
  String get timingSessionKindPre;

  /// No description provided for @timingSessionKindTraining.
  ///
  /// In en, this message translates to:
  /// **'Training {number} (~2 min)'**
  String timingSessionKindTraining(int number);

  /// No description provided for @timingSessionKindPost.
  ///
  /// In en, this message translates to:
  /// **'POST assessment (~10 min)'**
  String get timingSessionKindPost;

  /// No description provided for @timingPickDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get timingPickDate;

  /// No description provided for @timingPickTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timingPickTime;

  /// No description provided for @timingSave.
  ///
  /// In en, this message translates to:
  /// **'Save schedule & reminders'**
  String get timingSave;

  /// No description provided for @timingSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved.'**
  String get timingSaved;

  /// No description provided for @timingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync schedule to the server. Reminders may still be set on this device.'**
  String get timingSaveFailed;

  /// No description provided for @timingNotifPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications were denied. Schedule is saved, but reminders will not appear.'**
  String get timingNotifPermissionDenied;

  /// No description provided for @timingNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart practice reminder'**
  String get timingNotifTitle;

  /// No description provided for @timingNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Session {number} is scheduled now (~{minutes} min).'**
  String timingNotifBody(int number, int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
