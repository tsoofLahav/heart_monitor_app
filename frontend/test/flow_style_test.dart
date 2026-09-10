import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/game/forest_trail_screen.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';
import 'package:heart_feedback/shell/app_design.dart';
import 'package:heart_feedback/shell/app_navigation.dart';
import 'package:heart_feedback/shell/language_onboarding_screen.dart';
import 'package:heart_feedback/protocols/protocol_intro_screen.dart';
import 'package:heart_feedback/protocols/protocol_summary_screen.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/calibration/pulse_guide_step_image.dart';
import 'package:heart_feedback/prep/session_timing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final boundaryKey = GlobalKey();
Widget host(Widget child, {String language = 'en', double scale = 1}) =>
    RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          navigatorObservers: [appRouteObserver],
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: child,
        ));

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_FLOW_UI')) {
      final loader = FontLoader('MaterialIcons');
      loader.addFont(Future.value(ByteData.sublistView(File(
              '${Platform.environment["FLUTTER_ROOT"]}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
          .readAsBytesSync())));
      await loader.load();
    }
  });
  testWidgets(
      'current circle starts session and centers at every progress position',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var starts = 0;
    for (final completed in [0, 4, 9]) {
      final step = completed + 1;
      await tester.pumpWidget(host(Scaffold(
          body: TrailMap(
        currentSession: completed,
        totalSessions: 10,
        sessionScores: const {},
        ctaStep: step,
        ctaLabel: 'Start session $step',
        onCtaPressed: () => starts++,
      ))));
      await tester.pump();
      final control = find.byKey(ValueKey('trail-start-$step'));
      expect(tester.getCenter(control).dy, closeTo(350, 1));
      expect(find.text('Start session $step'), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(tester.getSize(control).width, greaterThanOrEqualTo(64));
      await tester.tap(control);
      await tester.pump();
    }
    expect(starts, 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('trail recenters after another route and background return',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(Scaffold(
        body: TrailMap(
      currentSession: 4,
      totalSessions: 10,
      sessionScores: const {},
      lockedSteps: const {6, 7, 8, 9, 10},
      ctaStep: 5,
      ctaLabel: 'Start session',
      onCtaPressed: () {},
    ))));
    await tester.pump();
    final scroll =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    scroll.jumpTo(0);
    final context = tester.element(find.byType(TrailMap));
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Profile'))));
    await tester.pump(const Duration(seconds: 1));
    Navigator.of(context).pop();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.getCenter(find.byKey(const ValueKey('trail-start-5'))).dy,
        closeTo(350, 1));
    scroll.jumpTo(0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(tester.getCenter(find.byKey(const ValueKey('trail-start-5'))).dy,
        closeTo(350, 1));
    if (const bool.fromEnvironment('CAPTURE_FLOW_UI')) {
      await tester.pump();
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/design-preview').create(recursive: true);
        await File('build/design-preview/focused_trail.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('locked level has no start control', (tester) async {
    await tester.pumpWidget(host(const Scaffold(
        body: TrailMap(
      currentSession: 2,
      totalSessions: 10,
      sessionScores: {},
      lockedSteps: {3, 4, 5, 6, 7, 8, 9, 10},
    ))));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('trail coaching fits a narrow phone with enlarged text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(host(const ForestTrailHome(), language: 'he', scale: 1.5));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final language in ['en', 'he']) {
    testWidgets('$language enlarged text stays usable on a narrow phone',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const round = ProtocolRound(
          roundIndex: 0,
          netStableSec: 20,
          sessionData: {
            'peaks_count': 30,
            'quality': {'mean_hr_bpm': 90}
          },
          guessedBeats: 28,
          confidencePercent: 70,
          sliderBpm: 85);
      for (final page in <Widget>[
        const LanguageOnboardingScreen(),
        ProtocolIntroScreen(sessionNumber: 1, onUnderstand: () {}),
        ProtocolSummaryScreen(rounds: const [round], onContinue: () {}),
        const SessionTimingScreen(remindersOnly: true),
        Scaffold(body: PulseGuideInstructionsPager(onFinished: () {})),
      ]) {
        await tester.pumpWidget(host(page, language: language, scale: 1.5));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: page.runtimeType.toString());
        final actions = find.byType(ElevatedButton);
        if (actions.evaluate().isNotEmpty) {
          final box = tester.getRect(actions.last);
          expect(box.bottom, lessThanOrEqualTo(640));
          expect(box.height, greaterThanOrEqualTo(56));
        }
      }
    });
  }
}
