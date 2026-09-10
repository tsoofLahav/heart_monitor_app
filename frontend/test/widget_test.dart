import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/shell/app.dart';
import 'package:heart_feedback/shell/locale_controller.dart';
import 'package:heart_feedback/shell/language_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_feedback/shell/selection_screen.dart';

void main() {
  testWidgets('first launch shows language onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.load();
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(LanguageOnboardingScreen), findsOneWidget);
    expect(find.byType(SelectionScreen), findsNothing);
    // Widget tests return HTTP 400; let all warmup retry timers finish.
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.pump(const Duration(seconds: 2));
    }
  });

  testWidgets('app builds and welcome navigates to selection',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_locale_code': 'en'});
    await LocaleController.instance.load();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(SelectionScreen), findsOneWidget);
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.pump(const Duration(seconds: 2));
    }
  });
}
