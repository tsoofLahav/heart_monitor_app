import 'dart:io';
import 'dart:convert';
import 'package:heart_feedback/calibration/pulse_guide_step_image.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';
import 'package:heart_feedback/shell/profile_screen.dart';
import 'package:heart_feedback/shell/leave_session_dialog.dart';
import 'package:heart_feedback/prep/session_timing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final captureKey = GlobalKey();
Widget host(Widget child, {String language = 'en'}) => RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'PreviewArial',
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FFFF), surface: Colors.black)),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ));

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PREP_UI')) return;
  await tester.runAsync(() async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/design-preview').create(recursive: true);
    await File('build/design-preview/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_PREP_UI')) {
      final loader = FontLoader('PreviewArial');
      loader.addFont(Future.value(ByteData.sublistView(
          File('/System/Library/Fonts/Supplemental/Arial.ttf')
              .readAsBytesSync())));
      await loader.load();
      final fallback = FontLoader('Ahem');
      fallback.addFont(Future.value(ByteData.sublistView(
          File('/System/Library/Fonts/Supplemental/Arial.ttf')
              .readAsBytesSync())));
      await fallback.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(Future.value(ByteData.sublistView(File(
              '${Platform.environment["FLUTTER_ROOT"]}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
          .readAsBytesSync())));
      await icons.load();
    }
  });
  testWidgets('saved reminder switches are restored independently',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'session_schedule_v1': jsonEncode(List.generate(
          10,
          (i) => {
                'trail_step': i + 1,
                'local_wall_time': '2026-10-01T18:00',
                'enabled': i == 1,
              }))
    });
    await tester
        .pumpWidget(host(const SessionTimingScreen(remindersOnly: true)));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isTrue);
  });

  testWidgets('Hebrew tutorial offers direct practice above page dots',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var started = false;
    await tester.pumpWidget(host(
        Scaffold(
            body:
                PulseGuideInstructionsPager(onFinished: () => started = true)),
        language: 'he'));
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(PageView), const Offset(350, 0));
      await tester.pumpAndSettle();
    }
    final button = find.byType(ElevatedButton);
    expect(button, findsOneWidget);
    final dots = find.byType(AnimatedContainer);
    expect(tester.getBottomLeft(button).dy,
        lessThan(tester.getTopLeft(dots.first).dy));
    await capture(tester, 'hebrew_practice_instructions');
    await tester.tap(button);
    expect(started, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next skips completed fields, keeps focus, then dismisses',
      (tester) async {
    SharedPreferences.setMockInitialValues({'profile_last_name': 'Existing'});
    await tester.pumpWidget(host(const ProfileScreen()));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'First');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(2)).focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    final phoneFocus = tester.widget<TextField>(fields.at(2)).focusNode!;
    await tester.enterText(fields.at(2), '0501234567');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(phoneFocus.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets(
      'reminders default off and choosing a time enables only that slot',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(host(const SessionTimingScreen(remindersOnly: true)));
    await tester.pumpAndSettle();
    expect(
        tester.widgetList<Switch>(find.byType(Switch)).every((s) => !s.value),
        isTrue);
    await tester.tap(find.byType(OutlinedButton).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isFalse);
    await capture(tester, 'reminder_toggles');
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
  });

  testWidgets('leave warning actions share a row and cancel keeps session',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool? left;
    await tester.pumpWidget(host(Builder(
        builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () async {
                    left = await confirmLeaveSession(context, sessionNumber: 1);
                  },
                  child: const Text('Open')),
            ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    final actions = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextButton));
    expect(
        tester.getCenter(actions.first).dy, tester.getCenter(actions.last).dy);
    await capture(tester, 'leave_session_warning');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(left, isFalse);
  });
}
