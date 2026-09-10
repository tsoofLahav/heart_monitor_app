import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:heart_feedback/prep/session_reminder_service.dart';
import 'package:heart_feedback/shell/app.dart';
import 'package:heart_feedback/shell/locale_controller.dart';

Future<void> _configureBeepAudio() async {
  await AudioPlayer.global.setAudioContext(
    AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.soloAmbient,
        options: const {},
      ),
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.load();
  try {
    await SessionReminderService.instance.ensureInitialized();
  } catch (_) {}
  try {
    await _configureBeepAudio();
  } catch (_) {}
  runApp(const MyApp());
}
