import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';
import 'package:heart_feedback/shell/locale_controller.dart';
import 'package:heart_feedback/shell/sound_ready_gate.dart';
import 'package:heart_feedback/shell/sound_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSoundStatus implements SoundStatusSource {
  double? volume = 0.8;
  bool? silent = false;
  final changes = StreamController<double>.broadcast();
  Completer<double?>? pendingVolume;
  @override
  bool get supportsSilentMode => true;
  @override
  Stream<double> get volumeChanges => changes.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<double?> readVolume() => pendingVolume?.future ?? Future.value(volume);
  @override
  Future<bool?> readSilent() async => silent;
  @override
  void dispose() {
    changes.close();
  }
}

Future<void> pollTwice(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }
}

Future<void> mountGuard(WidgetTester tester, FakeSoundStatus source) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'app_locale_code': 'en'});
  await LocaleController.instance.load();
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        body: SoundGuard(source: source, child: const Text('App content'))),
  ));
  await tester.pumpAndSettle();
}

Finder get continueButton => find.byType(ElevatedButton);
bool canContinue(WidgetTester tester) =>
    tester.widget<ElevatedButton>(continueButton).onPressed != null;

void main() {
  testWidgets('low volume blocks on launch and can reopen at 50 percent',
      (tester) async {
    final source = FakeSoundStatus()..volume = .3;
    await mountGuard(tester, source);
    expect(canContinue(tester), isFalse);
    source.volume = .6;
    source.changes.add(.6);
    await tester.pumpAndSettle();
    expect(canContinue(tester), isTrue);
    await tester.tap(continueButton);
    await tester.pump();
    expect(continueButton, findsNothing);
    source.volume = .5;
    source.changes.add(.5);
    await tester.pumpAndSettle();
    expect(canContinue(tester), isFalse);
  });

  testWidgets('valid launch does not prompt, silent mode changes do',
      (tester) async {
    final source = FakeSoundStatus();
    await mountGuard(tester, source);
    expect(continueButton, findsNothing);
    source.silent = true;
    await pollTwice(tester);
    expect(canContinue(tester), isFalse);
    source.silent = false;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(canContinue(tester), isTrue);
    await tester.tap(continueButton);
    await tester.pump();
    source.silent = true;
    await pollTwice(tester);
    expect(canContinue(tester), isFalse);
  });

  testWidgets('background sound changes are checked again on every resume',
      (tester) async {
    final source = FakeSoundStatus();
    await mountGuard(tester, source);
    for (final change in [0, 1]) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      source.volume = change == 0 ? .2 : .8;
      source.silent = change == 1;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await pollTwice(tester);
      expect(canContinue(tester), isFalse);
      source.volume = .8;
      source.silent = false;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pump();
    }
  });

  testWidgets(
      'a transient probe failure after playback does not reopen the dialog',
      (tester) async {
    final source = FakeSoundStatus()..volume = .3;
    await mountGuard(tester, source);
    source.volume = .8;
    source.changes.add(.8);
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pump();
    for (final transient in [true, null]) {
      source.silent = transient;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(continueButton, findsNothing);
      source.silent = false;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(continueButton, findsNothing);
    }
  });

  testWidgets('unknown sound settings cannot pass as ready', (tester) async {
    final source = FakeSoundStatus()..silent = null;
    await mountGuard(tester, source);
    await pollTwice(tester);
    expect(canContinue(tester), isFalse);
    source.silent = false;
    source.volume = null;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(canContinue(tester), isFalse);
  });

  testWidgets('new volume events win over an older in-flight read',
      (tester) async {
    final source = FakeSoundStatus();
    await mountGuard(tester, source);
    final oldRead = Completer<double?>();
    source.pendingVolume = oldRead;
    await tester.pump(const Duration(seconds: 1));
    source.changes.add(.4);
    await tester.pump();
    oldRead.complete(.8);
    source.pendingVolume = null;
    source.volume = .4;
    await tester.pumpAndSettle();
    expect(canContinue(tester), isFalse);
  });
}
