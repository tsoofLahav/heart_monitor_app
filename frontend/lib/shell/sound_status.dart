import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

abstract class SoundStatusSource {
  bool get supportsSilentMode;
  Stream<double> get volumeChanges;
  Future<void> initialize();
  Future<double?> readVolume();
  Future<bool?> readSilent();
  void dispose();
}

class DeviceSoundStatus implements SoundStatusSource {
  static const _iosSound = MethodChannel('monitor/sound');
  final _volumes = StreamController<double>.broadcast();
  bool _disposed = false;

  @override
  bool get supportsSilentMode =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  @override
  Stream<double> get volumeChanges => _volumes.stream;

  @override
  Future<void> initialize() async {
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterVolumeController.setAndroidAudioStream(
          stream: AudioStream.music);
    }
    if (!kIsWeb && Platform.isIOS) {
      await FlutterVolumeController.setIOSAudioSessionCategory(
          category: AudioSessionCategory.soleAmbient);
    }
    if (_disposed) return;
    FlutterVolumeController.addListener((volume) {
      if (!_disposed) _volumes.add(volume);
    });
  }

  @override
  Future<double?> readVolume() {
    if (!kIsWeb && Platform.isIOS) {
      // Reading outputVolume does not activate/reconfigure the audio session.
      return _iosSound.invokeMethod<double>('readVolume');
    }
    return FlutterVolumeController.getVolume();
  }

  @override
  Future<bool?> readSilent() async {
    if (!supportsSilentMode) return false;
    if (Platform.isIOS) {
      // Await a new native probe rather than sound_mode's cached last value.
      return _iosSound.invokeMethod<bool>('readSilent');
    }
    final status = await SoundMode.ringerModeStatus;
    switch (status) {
      case RingerModeStatus.normal:
        return false;
      case RingerModeStatus.silent:
      case RingerModeStatus.vibrate:
        return true;
      case RingerModeStatus.unknown:
        return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    FlutterVolumeController.removeListener();
    _volumes.close();
  }
}
