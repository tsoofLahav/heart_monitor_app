import 'package:heart_feedback/shell/app_design.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/pulse_guide_assets.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/shell/app_colors.dart';

/// Step illustration used on recording screens (idle / finger-wait).
class RecordingStepIllustration extends StatelessWidget {
  final String assetPath;
  final double height;

  const RecordingStepIllustration({
    super.key,
    required this.assetPath,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: brightenGuideImage(
        Image.asset(
          assetPath,
          height: height,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Small step 3 image for bad-reading notes.
class BadReadingStepHint extends StatelessWidget {
  final double height;
  final double? width;

  const BadReadingStepHint({super.key, this.height = 110, this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: brightenGuideImage(
        Image.asset(
          PulseGuideAssets.step3,
          height: height,
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

Future<void> showBadReadingNote(
  BuildContext context, {
  String? actionLabel,
}) {
  final l10n = context.l10n;
  final label = actionLabel ?? l10n.tryAgain;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.grey[900],
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.readingError,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.body,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            const BadReadingStepHint(width: 260),
            const SizedBox(height: 12),
            Text(
              l10n.badReadingDialogBody,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppType.secondary,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(label),
        ),
      ],
    ),
  );
}

/// Circular camera preview for recording screens.
class RecordingCornerPreview extends StatelessWidget {
  final CameraController controller;
  final double size;

  const RecordingCornerPreview({
    super.key,
    required this.controller,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.7), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? size,
            height: controller.value.previewSize?.width ?? size,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

/// Camera preview above the step illustration (not overlapping).
class RecordingGuideWithPreview extends StatelessWidget {
  final String assetPath;
  final CameraController? controller;
  final double imageHeight;
  final double previewSize;

  const RecordingGuideWithPreview({
    super.key,
    required this.assetPath,
    this.controller,
    this.imageHeight = 175,
    this.previewSize = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller != null) ...[
          RecordingCornerPreview(controller: controller!, size: previewSize),
          const SizedBox(height: 22),
        ],
        RecordingStepIllustration(
          assetPath: assetPath,
          height: imageHeight,
        ),
      ],
    );
  }
}
