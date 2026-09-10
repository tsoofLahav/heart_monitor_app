import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/camera_identify_screen.dart';
import 'package:heart_feedback/calibration/pulse_guide_step_image.dart';
import 'package:heart_feedback/calibration/pulse_reading_tutorial_screen.dart';
import 'package:heart_feedback/l10n/l10n.dart';

/// Camera identification (prep step 3 / bottom menu).
Future<bool?> openCameraIdentify(BuildContext context) {
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const CameraIdentifyScreen()),
  );
}

/// Prep quality: instructions then practice as one continuous flow.
Future<bool?> openQualityCheckFlow(BuildContext context) {
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => const PulseReadingTutorialScreen(
        mode: PulseReadingTutorialMode.full,
      ),
    ),
  );
}

/// Bottom-menu quality: instruction images only, ending with comics collage.
Future<bool?> openPulseGuideComics(BuildContext context) {
  return Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const _PulseGuideComicsScreen()),
  );
}

class _PulseGuideComicsScreen extends StatelessWidget {
  const _PulseGuideComicsScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(l10n.prepCardQualityTitle)),
      body: PulseGuideInstructionsPager(
        finale: PulseGuideInstructionsFinale.comics,
        onFinished: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
