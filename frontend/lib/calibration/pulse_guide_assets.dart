import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/app_localizations.dart';

/// Illustration assets for the pulse-reading guide (fingerprint tutorial).
class PulseGuideAssets {
  PulseGuideAssets._();

  static const step1 = 'assets/step1.png';
  static const step2 = 'assets/step2.png';
  static const step3 = 'assets/step3.png';
  static const step4 = 'assets/step4.png';

  static const List<String> instructionSteps = [step1, step2, step3, step4];

  static List<List<String>> instructionCaptionLines(AppLocalizations l10n) => [
        [l10n.instructionCaption1],
        [l10n.instructionCaption2],
        [l10n.instructionCaption3a, l10n.instructionCaption3b],
        [l10n.instructionCaption4a, l10n.instructionCaption4b],
      ];
}

/// Brightens dark step illustrations without remaking assets.
Widget brightenGuideImage(Widget image) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      1.25,
      0,
      0,
      0,
      28,
      0,
      1.25,
      0,
      0,
      28,
      0,
      0,
      1.25,
      0,
      28,
      0,
      0,
      0,
      1,
      0,
    ]),
    child: image,
  );
}
