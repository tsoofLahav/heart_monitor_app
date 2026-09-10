import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';
import 'package:heart_feedback/recording/recording_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('camera failure offers retry and resume retries safely',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    var cameraAttempts = 0;
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/camera'), (call) async {
      if (call.method == 'availableCameras') {
        cameraAttempts++;
        throw PlatformException(code: 'CameraAccessDenied');
      }
      return null;
    });
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events'
    ]) {
      messenger.setMockMethodCallHandler(
          MethodChannel(name), (_) async => null);
    }
    messenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'), (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null);
      }
      return null;
    });
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LearnPracticeRecordingScreen(),
    ));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Could not open the camera. Check permissions and try again.'),
        findsOneWidget);
    expect(cameraAttempts, 1);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(cameraAttempts, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(cameraAttempts, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
