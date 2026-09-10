import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heart_feedback/l10n/l10n.dart';

/// Soft sage header title color — menu icons match the trail header.
const Color kTrailHeaderIconColor = Color(0xFFD4E8B0);

/// Bottom menu: profile / camera / pulse guide / schedule.
/// Lucide thin-line SVGs (same stroke family as fingerprint).
class PrepIconBar extends StatelessWidget {
  final double iconSize;
  final VoidCallback onProfile;
  final VoidCallback onCamera;
  final VoidCallback onQuality;
  final VoidCallback onTiming;
  final GlobalKey? timingKey;
  final bool highlightTiming;

  const PrepIconBar({
    super.key,
    required this.onProfile,
    required this.onCamera,
    required this.onQuality,
    required this.onTiming,
    this.iconSize = 36,
    this.timingKey,
    this.highlightTiming = false,
  });

  static const _color = kTrailHeaderIconColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconBtn(
          tooltip: l10n.prepProfile,
          onPressed: onProfile,
          asset: 'assets/icons/user.svg',
        ),
        _iconBtn(
          tooltip: l10n.prepCamera,
          onPressed: onCamera,
          asset: 'assets/icons/camera.svg',
        ),
        _iconBtn(
          tooltip: l10n.prepCardQualityTitle,
          onPressed: onQuality,
          asset: 'assets/icons/fingerprint.svg',
        ),
        _iconBtn(
          key: timingKey,
          tooltip: l10n.prepTiming,
          onPressed: onTiming,
          asset: 'assets/icons/timer.svg',
          glow: highlightTiming,
        ),
      ],
    );
  }

  Widget _iconBtn({
    Key? key,
    required String tooltip,
    required VoidCallback onPressed,
    required String asset,
    bool glow = false,
  }) {
    final child = SvgPicture.asset(
      asset,
      width: iconSize,
      height: iconSize,
      colorFilter: const ColorFilter.mode(_color, BlendMode.srcIn),
    );
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: iconSize,
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(
        minWidth: iconSize + 20,
        minHeight: iconSize + 20,
      ),
      icon: glow
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            )
          : child,
    );
  }
}
