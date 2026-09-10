// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get profileGroup => 'קבוצה';

  @override
  String get profileGroupRegular => 'רגילה';

  @override
  String get profileGroupControl => 'ביקורת';

  @override
  String get sessionScoreTitle => 'ציון התרגול';

  @override
  String get matchingScore => 'ציון התאמה';

  @override
  String get formNext => 'הבא';

  @override
  String get soundStatusUnavailable =>
      'לא ניתן לאמת את הגדרות הקול. השאירו את האפליקציה פתוחה לבדיקה חוזרת.';

  @override
  String get recordingNoCountCaption =>
      'השאירו את האצבע יציבה עד להנחיה להרים אותה.';

  @override
  String get continueAction => 'המשך';

  @override
  String get tryAgain => 'נסו שוב';

  @override
  String get start => 'התחלה';

  @override
  String get done => 'סיום';

  @override
  String get cancel => 'ביטול';

  @override
  String get na => 'לא זמין';

  @override
  String get backToMenu => 'חזרה לתפריט';

  @override
  String get end => 'סיום';

  @override
  String get reset => 'איפוס';

  @override
  String get finish => 'סיום';

  @override
  String get nextRound => 'סיבוב הבא';

  @override
  String get startAgain => 'התחילו שוב';

  @override
  String get profile => 'פרופיל';

  @override
  String get language => 'שפה';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get languageSectionSubtitle => 'בחרו את שפת האפליקציה.';

  @override
  String get turnSoundOn => 'הפעילו את הצליל';

  @override
  String get soundGateBody =>
      'האפליקציה משתמשת בהנחיות קוליות ובצפצופים. כבו מצב שקט, העלו את עוצמת הקול וודאו שאתם שומעים את צליל הבדיקה.';

  @override
  String get phoneSilentVibrate => 'הטלפון במצב שקט / רטט';

  @override
  String get ringerSwitchOk => 'מתג השקט תקין';

  @override
  String get flipSilentSwitchHint => 'כבו את מתג השקט (או צאו ממצב רטט).';

  @override
  String get volumeUpHint => 'העלו את הווליום באמצעות הכפתורים בצד.';

  @override
  String get playTestBeep => 'השמע קול לבדיקה';

  @override
  String get waitingForSound => 'ממתינים לצליל…';

  @override
  String volumeLoudEnough(int percent) {
    return 'הווליום גבוה מספיק ($percent%)';
  }

  @override
  String volumeTooLow(int percent, int needPercent) {
    return 'הווליום נמוך מדי ($percent% — נדרש $needPercent%+)';
  }

  @override
  String get welcomeToHeartMonitor => 'ברוכים הבאים אל\nמוניטור הלב';

  @override
  String get personalHeartMonitor => 'מוניטור לב אישי';

  @override
  String get todaysPractice => 'התרגול של היום';

  @override
  String get notAvailableInFlightTest => 'לא זמין בבדיקת טיסה';

  @override
  String get moreFlows => 'עוד מסלולים';

  @override
  String get pulseReadingGuide => 'מדריך קריאת דופק';

  @override
  String get finishGuideBeforeStart =>
      'סיימו כאן את מדריך קריאת הדופק לפני שתתחילו.';

  @override
  String get moreTitle => 'עוד';

  @override
  String get otherTrainingAndTools => 'אימונים וכלים נוספים';

  @override
  String get forestTrail => 'שביל היער';

  @override
  String get forestTrailSubtitle =>
      'הערכה מקדימה, 8 תרגולי אימון, ואז הערכה מסכמת.';

  @override
  String get preAssessmentTitle => 'הערכה מקדימה';

  @override
  String get postAssessmentTitle => 'הערכה מסכמת';

  @override
  String get assessmentSessionHeaderPre => 'תרגול 1 — הערכה מקדימה';

  @override
  String get assessmentSessionHeaderPost => 'תרגול 10 — הערכה מסכמת';

  @override
  String get leaveSessionTitle => 'לצאת מהתרגול?';

  @override
  String leaveSessionBody(int number) {
    return 'אתם עוזבים את תרגול $number. אם לא סיימתם, תצטרכו להתחיל אותו מחדש.';
  }

  @override
  String get leaveSessionConfirm => 'יציאה';

  @override
  String get okAction => 'אישור';

  @override
  String get controlStartSoundWhenReady => 'הפעילו את הצליל כשאתם מוכנים';

  @override
  String get practiceIntroBody =>
      'הקליטו את הדופק כפי שלמדתם.\n\nספרו את פעימות הלב בלי לגעת בחזה או בדופק. התחילו בצפצוף הראשון ועצרו בשני.\n\nלאחר מכן הזינו את המספר והתאימו את הקצב. חזרו על כך בשני סבבים.';

  @override
  String get controlPracticeIntroBody =>
      'בתרגול הזה יש 2 סיבובים.\n\nבכל סיבוב עצמו עיניים, הקשיבו לצפצופים ונסו לספור אותם.\n\nאחר כך תתבקשו להזין את המספר ולהתאים את הקצב ששמעתם.';

  @override
  String sessionScoreLine(int score) {
    return 'ציון התרגול:\n$score%';
  }

  @override
  String trailSessionScoreBubble(int session, int score) {
    return 'ניקוד תרגול $session: $score';
  }

  @override
  String get preAssessmentIntro =>
      'תקליטו את הדופק, תספרו את הפעימות שחשתם, ותדרגו את הביטחון שלכם.\n\nההקלטה הראשונה נמשכת 15 שניות. אחר כך תחזרו על אותם צעדים עוד כמה פעמים (האורך ישתנה ולא יוצג).\n\nלבסוף תשמעו זוגות של מקצבים ותבחרו איזה מהם מתאים לכם.';

  @override
  String get postAssessmentIntro =>
      'אותה הערכה כמו בהתחלה: חמישה ניסיונות ספירת פעימות, ואז שישה בחירות מקצב.\n\nההקלטה הראשונה נמשכת 15 שניות; בשאר הזמן מוסתר.';

  @override
  String get assessmentGateBody =>
      'בתרגול זה יש 12 שלבים והוא נמשך כ־10 דקות.\n\nשימו לב: אחרי שמתחילים אי אפשר לסגור את התרגול — אחרת תצטרכו להתחיל מההתחלה.';

  @override
  String get assessmentStep1Body =>
      'הקליטו את הדופק כפי שלמדתם.\n\nספרו את פעימות הלב בזמן ההקלטה, בלי לגעת בחזה או בדופק.\n\nהתחילו לספור בצפצוף הראשון ועצרו בצפצוף השני.';

  @override
  String get assessmentAfterStep1Body =>
      'חזרו על המשימה בארבעה סבבים באורכים שונים. ספרו בין הצפצופים. הישארו בלי לזוז עד להנחיה להרים את האצבע.';

  @override
  String get assessmentHalfwayMatchBody =>
      'כעת: שש התאמות קצב. הרגישו את פעימות הלב בזמן המדידה — בלי לספור ובלי צפצופים. המתינו להנחיה הקולית ואז התאימו את הקצב.';

  @override
  String get assessmentRelaxBody =>
      'הירגעו למשך דקה. בלי לספור ובלי צפצופים. השאירו את האצבע יציבה עד להנחיה להרים אותה.';

  @override
  String get assessmentGoodJob => 'כל הכבוד';

  @override
  String assessmentStartStep(int current, int total) {
    return 'התחילו שלב $current/$total';
  }

  @override
  String assessmentGoodJobStartStep(int current, int total) {
    return 'כל הכבוד, התחילו שלב $current/$total.';
  }

  @override
  String assessmentStepProgress(int current, int total) {
    return 'שלב $current/$total';
  }

  @override
  String get assessmentAbandonTitle => 'לצאת מההערכה?';

  @override
  String get assessmentAbandonBody =>
      'אם תצאו עכשיו תצטרכו להתחיל את ההערכה מההתחלה.';

  @override
  String get assessmentAbandonConfirm => 'יציאה';

  @override
  String get assessmentPreFinishBody =>
      'סיימתם את השלב הראשון והארוך ביותר במסע שלכם.\n\nהשלבים הבאים יהיו קצרים בהרבה. צריך להשלים 9 תוך שבועיים, עם לפחות יום אחד בין כל שלב.';

  @override
  String get assessmentPostFinishBody =>
      'סיימתם את המסע.\n\nתודה שתרמתם למחקר שלנו — הוא משרת מטרה חשובה.';

  @override
  String get nextAction => 'הבא';

  @override
  String practiceSessionHeader(int number) {
    return 'תרגול $number';
  }

  @override
  String get assessmentRepeatBody =>
      'ספרו בין הצפצופים, ואז הזינו את המספר ואת מידת הביטחון שלכם.';

  @override
  String assessmentTrialProgress(int current, int total) {
    return 'ניסיון $current / $total';
  }

  @override
  String assessmentRhythmProgress(int current, int total) {
    return 'שאלת מקצב $current / $total';
  }

  @override
  String assessmentRhythmTitle(int current, int total) {
    return 'מקצב $current / $total';
  }

  @override
  String get assessmentListeningA => 'הקשיבו למקצב א׳';

  @override
  String get assessmentListeningB => 'הקשיבו למקצב ב׳';

  @override
  String get assessmentWhichRhythm => 'איזה מקצב מתאים לכם?';

  @override
  String get assessmentPickA => 'מקצב א׳';

  @override
  String get assessmentPickB => 'מקצב ב׳';

  @override
  String assessmentSecondsLeft(int seconds) {
    return '$seconds שנ׳';
  }

  @override
  String get assessmentPleaseWait => 'אנא המתינו…';

  @override
  String get assessmentSaveFailed =>
      'לא ניתן לשמור את ההערכה. בדקו את החיבור ונסו שוב.';

  @override
  String get experimentSessionSaveFailed =>
      'לא ניתן לשמור את התרגול בשרת. בדקו את החיבור ונסו שוב.';

  @override
  String get startPreAssessment => 'התחלת הערכה מקדימה';

  @override
  String get continueToPostAssessment => 'המשך להערכה מסכמת';

  @override
  String continueToTrainingSession(int number) {
    return 'המשך לתרגול $number';
  }

  @override
  String get startTodaysSession => 'התחלת תרגול היום';

  @override
  String get startSession => 'התחלת תרגול';

  @override
  String get trailOpensTomorrow => 'התרגול ייפתח מחר';

  @override
  String experimentStepsDone(int completed, int total) {
    return '$completed / $total שלבים הושלמו';
  }

  @override
  String get experimentBootstrapFailed =>
      'לא ניתן לסנכרן התקדמות ניסוי. משתמשים בהתקדמות שמורה אם קיימת.';

  @override
  String get quickProtocolTest => 'בדיקת פרוטוקול מהירה';

  @override
  String get quickProtocolTestSubtitle =>
      'תרגול הפרוטוקול המלא בלי לשמור התקדמות ניסוי.';

  @override
  String get saving => 'שומרים…';

  @override
  String get pilote => 'פיילוט';

  @override
  String get piloteSubtitle => 'הקלטה וייצוא נתוני מפגש.';

  @override
  String get setupAndQuality => 'הכנה ואיכות';

  @override
  String get setupAndQualitySubtitle => 'מדריך דופק ובדיקת איכות ML.';

  @override
  String get protocolTest => 'בדיקת פרוטוקול';

  @override
  String get protocolTestSubtitle =>
      'פרוטוקול מלא עם הקלטות אקראיות של 20–40 שניות.';

  @override
  String get sessions => 'תרגולים';

  @override
  String get sessionDetails => 'פרטי תרגול';

  @override
  String get bpmOverTime => 'BPM לאורך זמן';

  @override
  String get hrvOverTime => 'HRV לאורך זמן';

  @override
  String get calibrationHubIntro =>
      'למדו הנחת אצבע ובדקו איכות אות לפני התרגול.';

  @override
  String get pulseGuideTileSubtitle => 'הוראות ותרגול איכות.';

  @override
  String get qualityTest => 'בדיקת איכות';

  @override
  String get qualityTestSubtitle => 'הקלטה ארוכה יותר עם פירוט איכות ML.';

  @override
  String get pulseReadingGuideTitle => 'מדריך קריאת דופק';

  @override
  String get preparation => 'הכנה';

  @override
  String get completeEachStepOnce =>
      'השלימו כל שלב פעם אחת. אפשר לחזור לכל שלב אחר כך.';

  @override
  String get cameraStep => 'מצלמה';

  @override
  String get cameraStepSubtitle => 'מצאו איזו עדשה אחורית לכסות.';

  @override
  String get instructionsStep => 'הוראות';

  @override
  String get instructionsStepSubtitle => 'איך לבצע קריאה.';

  @override
  String get qualityPracticeStep => 'תרגול איכות';

  @override
  String get qualityPracticeStepSubtitle => 'השיגו 3 קריאות טובות ברצף.';

  @override
  String get findYourCamera => 'מצאו את המצלמה';

  @override
  String get findYourPulseCamera => 'מצאו את מצלמת הדופק';

  @override
  String get coverRearLensHint =>
      'כסו את המצלמה עד שהאצבע ממלאת את התצוגה. הישארו בלי לזוז והקשיבו להנחיה הקולית.';

  @override
  String get noChangeTryNextCamera =>
      'אין שינוי? נסו עדשה אחרת, או לחצו על נסו מצלמה הבאה.';

  @override
  String get holdStillOnLens => 'החזיקו יציב על העדשה…';

  @override
  String get tryNextCamera => 'נסו מצלמה הבאה';

  @override
  String get thisIsYourPulseCamera => 'זו מצלמת הדופק שלכם';

  @override
  String get remember => 'זכרו';

  @override
  String get whichLensYouCovered =>
      ' איזו עדשה כיסיתם — השתמשו באותה עדשה בכל הקריאה.';

  @override
  String get forgotLaterOpenCamera =>
      'שכחתם אחר כך? פתחו שוב את מצלמה במדריך קריאת הדופק.';

  @override
  String get noRearCameraFound => 'לא נמצאה מצלמה אחורית במכשיר זה.';

  @override
  String get couldNotOpenCamera =>
      'לא ניתן לפתוח את המצלמה. בדקו הרשאות ונסו שוב.';

  @override
  String get somethingWentWrong => 'משהו השתבש.';

  @override
  String get instructionCaption1 => 'מצאו מקום נוח ושקט עם Wi‑Fi.';

  @override
  String get instructionCaption2 => 'לחצו על התחלה, ואז הפכו את הטלפון.';

  @override
  String get instructionCaption3a =>
      'הניחו את היד על הטלפון וכסו את העדשה התחתונה באצבע.';

  @override
  String get instructionCaption3b =>
      'הקשיבו להנחיה הקולית והשאירו את האצבע יציבה.';

  @override
  String get instructionCaption4a => 'הרימו את האצבע רק לאחר ההנחיה הקולית.';

  @override
  String get instructionCaption4b => 'הפכו את הטלפון חזרה והמשיכו בהוראות.';

  @override
  String get readyForQualityPractice => 'תרגלו הקלטה נכונה של הדופק.';

  @override
  String get nextYoullTakeShortReadings =>
      'בשלב הבא תבצעו קריאות קצרות עד שתשיגו 3 קריאות טובות ברצף.';

  @override
  String get instructionsTitle => 'הוראות';

  @override
  String get qualityPracticeTitle => 'תרגול איכות';

  @override
  String get practiceResultTitle => 'תוצאת תרגול';

  @override
  String get tutorialCompleteTitle => 'המדריך הושלם';

  @override
  String get get3GoodReadings => 'השיגו 3 קריאות טובות ברצף.';

  @override
  String get startPractice => 'התחלת תרגול';

  @override
  String get practiceRetryHint =>
      'נסו שוב. שמרו על יד יציבה, אצבע על המצלמה, ואל תזוזו במהלך ההקלטה.';

  @override
  String get tutorialComplete => 'המדריך הושלם!';

  @override
  String get successful => 'הצלחה';

  @override
  String get notSuccessful => 'לא הצליח';

  @override
  String get qualityTestResult => 'תוצאת בדיקת איכות';

  @override
  String get noSignalData => 'אין נתוני אות';

  @override
  String get windowPredictions => 'תחזיות חלונות';

  @override
  String cameraOrdinalOfCount(int ordinal, int count) {
    return 'מצלמה $ordinal מתוך $count';
  }

  @override
  String streakProgress(int current, int required) {
    return 'רצף: $current / $required';
  }

  @override
  String tutorialCompleteBody(int required, int attempts) {
    return 'השלמתם $required קריאות מוצלחות ברצף אחרי $attempts ניסיונות.';
  }

  @override
  String readingQuality(String label) {
    return 'איכות קריאה: $label';
  }

  @override
  String probGoodBad(String good, String bad) {
    return 'P(טוב) = $good%  |  P(רע) = $bad%';
  }

  @override
  String durationAndPeaks(String duration, String peaks) {
    return 'משך: $duration שנ׳  |  פיקים: $peaks';
  }

  @override
  String windowTimeRange(String start, String end) {
    return '$start שנ׳ – $end שנ׳';
  }

  @override
  String windowLabelProb(String label, String prob) {
    return '$label  ($prob% טוב)';
  }

  @override
  String get pressStartThenFlip =>
      'כשתהיו מוכנים, לחצו על התחלה, הפכו את הטלפון וכסו את העדשה באצבע.\n\nעקבו אחר ההנחיות הקוליות.';

  @override
  String get flashOnPreparing => 'פלאש דולק — מתכוננים…';

  @override
  String get liftFingerMoment => 'הרימו את האצבע לרגע…';

  @override
  String get coverLensHoldStill => 'כסו את העדשה והחזיקו יציב.';

  @override
  String get holdStill => 'החזיקו יציב…';

  @override
  String get fingerNotDetected =>
      'האצבע לא זוהתה. התאימו את המיקום או לחצו על ביטול.';

  @override
  String get wrongCameraHint => 'מצלמה שגויה. נסו שוב עם מצלמה אחרת.';

  @override
  String get preferredCameraPlacementHint =>
      'כסו את אותה עדשה אחורית שזיהיתם והחזיקו יציב.';

  @override
  String get readingError => 'שגיאת קריאה';

  @override
  String get badReadingDialogBody =>
      'נסו שוב. ודאו שהיד יציבה, האצבע מכסה את המצלמה, ואתם לא זזים במהלך ההקלטה.';

  @override
  String get piloteRecording => 'הקלטת פיילוט';

  @override
  String get qualityTestTitle => 'בדיקת איכות';

  @override
  String get practiceReading => 'קריאת תרגול';

  @override
  String get protocolRecording => 'הקלטת פרוטוקול';

  @override
  String get processingDataWait => 'מעבדים נתונים, המתינו לתוצאות';

  @override
  String get stopping => 'עוצרים…';

  @override
  String get recordingInterrupted => 'ההקלטה הופסקה.';

  @override
  String get recordingErrorRetry => 'שגיאת הקלטה. נסו שוב.';

  @override
  String get serverErrorRetry => 'שגיאת שרת. נסו שוב.';

  @override
  String get networkErrorRetry => 'שגיאת רשת. נסו שוב.';

  @override
  String get first => 'ראשונה';

  @override
  String get second => 'שנייה';

  @override
  String protocolRecordingCaption(String which) {
    return 'הקלטה $which — לחצו על התחלה כשמוכנים.';
  }

  @override
  String get training => 'אימון';

  @override
  String get howThisWorks => 'איך זה עובד';

  @override
  String get twoRounds => 'שני סיבובים';

  @override
  String get twoRoundsBody =>
      'תבצעו שתי הקלטות קצרות.\n\nאחרי כל אחת תספרו את הפעימות שחשתם, תדרגו את הביטחון, ותתאימו את המקצב המוצג למקצב שלכם.';

  @override
  String get duringRecording => 'במהלך ההקלטה';

  @override
  String get duringRecordingBody =>
      'ספרו את פעימות הלב בין שני הצפצופים, בלי לגעת בדופק או בחזה. הישארו בלי לזוז עד להנחיה להרים את האצבע.';

  @override
  String get controlTwoRoundsTitle => 'שני סיבובים';

  @override
  String get controlTwoRoundsBody =>
      'תשמעו שני רצפי צפצופים.\n\nאחרי כל אחד הזינו כמה ספרתם, דרגו את הביטחון, ואז התאימו את הקצב ששמעתם.';

  @override
  String get controlDuringListeningTitle => 'בזמן האזנה';

  @override
  String get controlDuringListeningBody =>
      'עצמו עיניים.\n\nספרו כל צפצוף מההתחלה עד הסוף.\n\nאחר כך פתחו עיניים והמשיכו.';

  @override
  String get iUnderstand => 'הבנתי';

  @override
  String get howManyBeatsCounted => 'כמה פעימות ספרתם?';

  @override
  String get enterNumber => 'הזינו מספר';

  @override
  String get howConfident => 'כמה אתם בטוחים?';

  @override
  String get slideTillRhythmMatches => 'החליקו עד שהקצב תואם לשלכם.';

  @override
  String get controlSlideTillRhythmMatches =>
      'החליקו עד שהקצב תואם למה ששמעתם.';

  @override
  String controlListenTitle(int number) {
    return 'סיבוב $number — האזנה';
  }

  @override
  String get controlListeningBody =>
      'עצמו עיניים וספרו את הצפצופים עד שהם נעצרים.';

  @override
  String get protocolSummary => 'סיכום פרוטוקול';

  @override
  String get roundResults => 'תוצאות הסיבוב';

  @override
  String get targetNetDebug => 'יעד נטו (דיבוג)';

  @override
  String get actualBeats => 'פעימות בפועל';

  @override
  String get yourCount => 'הספירה שלכם';

  @override
  String get confidence => 'ביטחון';

  @override
  String get countScore => 'ניקוד ספירה';

  @override
  String get sliderBpm => 'BPM במחוון';

  @override
  String get measuredHr => 'דופק שנמדד';

  @override
  String get hrError => 'שגיאת דופק';

  @override
  String get hrAccuracy => 'דיוק דופק';

  @override
  String get roundScore => 'ניקוד סיבוב';

  @override
  String get preparingFinalScore => 'מכינים ניקוד סופי…';

  @override
  String roundFooter(int number, int total) {
    return 'סיבוב $number/$total';
  }

  @override
  String roundCountBeatsTitle(int number) {
    return 'סיבוב $number — ספירת פעימות';
  }

  @override
  String roundHeartRateTitle(int number) {
    return 'סיבוב $number — דופק';
  }

  @override
  String roundSummaryTitle(int number) {
    return 'סיכום סיבוב $number';
  }

  @override
  String roundLabel(int number) {
    return 'סיבוב $number';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String secondsValue(String value) {
    return '$value שנ׳';
  }

  @override
  String get yourJourney => 'המסע שלכם';

  @override
  String get youReachedTheEnd => 'הגעתם לסוף!';

  @override
  String get allDone => 'הכול הושלם!';

  @override
  String get startSession1 => 'התחלת תרגול 1';

  @override
  String get resetProgressTitle => 'לאפס התקדמות?';

  @override
  String get resetProgressBody =>
      'פעולה זו תמחק את כל התרגולים שהושלמו ותתחיל מההתחלה.';

  @override
  String get resetProgressTooltip => 'איפוס התקדמות';

  @override
  String allSessionsCompleted(int total) {
    return 'כל $total התרגולים הושלמו';
  }

  @override
  String sessionOfTotal(int current, int total) {
    return 'תרגול $current מתוך $total';
  }

  @override
  String sessionsDone(int completed, int total) {
    return '$completed / $total תרגולים הושלמו';
  }

  @override
  String continueToSession(int number) {
    return 'המשך לתרגול $number';
  }

  @override
  String sessionScoreCaption(int score) {
    return 'ניקוד התרגול שלכם הוא $score%.\nככל שהתמונה ברורה יותר, כך הניקוד גבוה יותר.';
  }

  @override
  String get noSessionData => 'אין נתוני מפגש.';

  @override
  String get saveShare => 'שמירה / שיתוף';

  @override
  String get sessionName => 'שם מפגש';

  @override
  String get fileNameWithoutPdf => 'שם קובץ (בלי .pdf)';

  @override
  String get sharePdf => 'שיתוף PDF';

  @override
  String get savePdfToPhone => 'שמירת PDF לטלפון';

  @override
  String get sendToWhatsApp => 'שליחה לוואטסאפ';

  @override
  String get openSessionDataList => 'פתיחת רשימת נתוני מפגש';

  @override
  String get sessionData => 'נתוני מפגש';

  @override
  String get viewSignal => 'הצגת אות';

  @override
  String get noCleanSignal => 'אין clean_signal במפגש זה.';

  @override
  String get signalRealPeaksMarked => 'אות (פיקים אמיתיים מסומנים)';

  @override
  String get prepProfile => 'פרופיל';

  @override
  String get prepQuestionnaires => 'שאלונים';

  @override
  String get prepCamera => 'מצלמה';

  @override
  String get prepQualityCheck => 'בדיקת איכות';

  @override
  String get prepTiming => 'תזמון';

  @override
  String get finishPrepBeforeStart =>
      'סיימו את ארבעת שלבי ההכנה למטה לפני שתתחילו.';

  @override
  String get prepOnboardingHint =>
      'השלימו כל שלב למטה. לחצו על האייקון הזוהר כדי להמשיך.';

  @override
  String get prepBubbleProfile => 'מלאו פרטים אישיים';

  @override
  String get prepBubbleQuestionnaire => 'מלאו שאלון';

  @override
  String get prepBubbleQuality => 'השלימו בדיקת איכות';

  @override
  String get prepBubbleTiming => 'קבעו לוח תרגולים';

  @override
  String get prepTrainingTitle => 'הכנה לאימון';

  @override
  String prepStepsProgress(int done, int total) {
    return 'השלימו $done מתוך $total שלבים';
  }

  @override
  String get prepCardProfileTitle => 'מילוי פרטים אישיים';

  @override
  String get prepCardProfileSubtitle => 'שם וטלפון';

  @override
  String get prepCardQuestionnaireTitle => 'שאלון';

  @override
  String get prepCardQuestionnaireSubtitle => 'יתווסף בהמשך';

  @override
  String get prepCardCameraTitle => 'הכנה לשימוש במצלמה';

  @override
  String get prepCardCameraSubtitle => 'הדרכה קצרה';

  @override
  String get prepCardQualityTitle => 'איך משתמשים במצלמה לקריאת הדופק?';

  @override
  String get prepCardQualitySubtitle => 'הוראות ותרגול';

  @override
  String get prepCardCompleted => 'הושלם';

  @override
  String get prepStartTraining => 'התחלת האימון';

  @override
  String get prepStartLockedHint => 'זמין לאחר השלמת ההכנה';

  @override
  String get questionnaireComingSoon => 'יתווסף בהמשך';

  @override
  String get approveAction => 'אישור';

  @override
  String get cameraFindTitle => 'מצאו את המצלמה שתשתמשו בה במהלך התרגול';

  @override
  String get cameraFindBody =>
      'בכל פעם כסו מצלמה אחרת (מצלמות אחוריות) עם האצבע עד שתראו שהאצבע מכסה את התצוגה.';

  @override
  String get cameraRememberTitle => 'זכרו: זו המצלמה לתרגול';

  @override
  String get cameraRememberHint =>
      'אם תשכחו אחר כך, תוכלו למצוא את החלק הזה בתפריט התחתון של האפליקציה.';

  @override
  String get pulseGuideComicsTitle => 'שלבי קריאת הדופק';

  @override
  String get trailCoachBubble1 =>
      'יש 10 שלבים להשלים תוך שבועיים. הראשון והאחרון אורכים כ־10 דקות כל אחד; האחרים כ־2 דקות.';

  @override
  String get trailCoachBubble2 =>
      'בכל פעם, השלב הבא ייפתח 24 שעות אחרי שתסיימו את הנוכחי.';

  @override
  String get trailCoachBubble3 =>
      'אפשר להשתמש במערכת ההתראות שלנו כדי לקבוע תזכורות לתרגולים.';

  @override
  String get trailStepOpensIn24h => 'נפתח 24 שעות אחרי השלב הקודם';

  @override
  String trailStepLockedHours(int hours, int minutes) {
    return 'השלב ייפתח בעוד $hours שע׳ ו־$minutes דק׳';
  }

  @override
  String get protocolRecordingReadyCaption =>
      'כשתהיו מוכנים, לחצו על התחלה, הפכו את הטלפון וכסו את העדשה באצבע.\n\nעקבו אחר ההנחיות הקוליות.';

  @override
  String get firstName => 'שם פרטי';

  @override
  String get lastName => 'שם משפחה';

  @override
  String get phoneNumber => 'מספר טלפון';

  @override
  String get profileSave => 'שמירת פרופיל';

  @override
  String get profileSaved => 'הפרופיל נשמר.';

  @override
  String get profileIncomplete => 'נא למלא שם פרטי, שם משפחה וטלפון.';

  @override
  String get profileSaveFailed =>
      'לא הצלחנו לסנכרן את הפרופיל לשרת. הפרטים נשמרו במכשיר.';

  @override
  String get appreciationTitleBefore => 'לפני התרגול';

  @override
  String get appreciationTitleAfter => 'אחרי התרגול';

  @override
  String get appreciationIntro =>
      'ענו על כמה שאלות קצרות. התשובות עוזרות לנו להבין את החוויה שלכם.';

  @override
  String get appreciationSubmit => 'שליחת תשובות';

  @override
  String get appreciationSaved => 'התשובות נשמרו.';

  @override
  String get appreciationSaveFailed =>
      'לא הצלחנו לשמור. בדקו את החיבור ונסו שוב.';

  @override
  String get appreciationQ1 => 'כמה מוטיבציה יש לכם לשים לב לדופק? (1–5)';

  @override
  String get appreciationQ2 =>
      'כמה אתם בטוחים שאתם יכולים להרגיש את הדופק? (1–5)';

  @override
  String get appreciationQ3 => 'הערה קצרה על איך אתם מרגישים היום (רשות)';

  @override
  String get timingTitle => 'לוח תרגולים';

  @override
  String get timingIntro =>
      'צריך לסיים 10 תרגולים של המשחק תוך שבועיים. התרגול הראשון והאחרון אורכים כ־10 דקות כל אחד; האחרים כ־2 דקות כל אחד.';

  @override
  String get timingNotificationsHint =>
      'אפשר להשתמש במערכת ההתראות שלנו כדי לקבוע תזכורות לתרגולים.';

  @override
  String get timingScrollToReminders => 'תזכורות רשות — גללו למטה';

  @override
  String get timingRemindersSection => 'זמני תזכורת';

  @override
  String get timingEnableReminders => 'הפעלת תזכורות וסיום';

  @override
  String get timingFinish => 'סיום';

  @override
  String get timingFinishedNoNotifs => 'ההכנה הסתיימה. התזכורות כבויות.';

  @override
  String get timingIsraelNote => 'כל הזמנים לפי שעון ישראל (Asia/Jerusalem).';

  @override
  String timingSessionLabel(int number) {
    return 'תרגול $number';
  }

  @override
  String get timingSessionKindPre => 'הערכה מקדימה (~10 דק׳)';

  @override
  String timingSessionKindTraining(int number) {
    return 'אימון $number (~2 דק׳)';
  }

  @override
  String get timingSessionKindPost => 'הערכה מסכמת (~10 דק׳)';

  @override
  String get timingPickDate => 'תאריך';

  @override
  String get timingPickTime => 'שעה';

  @override
  String get timingSave => 'שמירת לוח ותזכורות';

  @override
  String get timingSaved => 'הלוח נשמר.';

  @override
  String get timingSaveFailed =>
      'לא הצלחנו לסנכרן את הלוח לשרת. ייתכן שהתזכורות עדיין הוגדרו במכשיר.';

  @override
  String get timingNotifPermissionDenied =>
      'ההרשאה להתראות נדחתה. הלוח נשמר, אבל תזכורות לא יופיעו.';

  @override
  String get timingNotifTitle => 'תזכורת לתרגול דופק';

  @override
  String timingNotifBody(int number, int minutes) {
    return 'תרגול $number מתוכנן עכשיו (~$minutes דק׳).';
  }
}
