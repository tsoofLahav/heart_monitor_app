import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/app_config.dart';

/// Bottom round / step indicator during protocol or assessment.
class ProtocolRoundFooter extends StatelessWidget {
  final int roundNumber;
  final int totalRounds;

  /// When set, shown instead of [roundFooter].
  final String? label;

  const ProtocolRoundFooter({
    super.key,
    required this.roundNumber,
    this.totalRounds = 2,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          label ?? context.l10n.roundFooter(roundNumber, totalRounds),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: AppType.secondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Wraps a protocol step body with centered content and the round footer.
class ProtocolRoundShell extends StatelessWidget {
  final int roundNumber;
  final int totalRounds;
  final String? footerLabel;
  final Widget child;
  final Widget? action;

  const ProtocolRoundShell({
    super.key,
    required this.roundNumber,
    this.totalRounds = 2,
    this.footerLabel,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ProtocolCenteredScrollBody(
            padding: kCenteredBodyPadding,
            child: child,
            action: action,
            actionSafeBottom: false,
          ),
        ),
        ProtocolRoundFooter(
          roundNumber: roundNumber,
          totalRounds: totalRounds,
          label: footerLabel,
        ),
      ],
    );
  }
}

/// Vertically centers step content; scrolls when the keyboard or content exceeds height.
class ProtocolCenteredScrollBody extends StatelessWidget {
  final Widget child;
  final Widget? action;
  final bool actionSafeBottom;
  final EdgeInsets padding;

  const ProtocolCenteredScrollBody({
    super.key,
    required this.child,
    this.action,
    this.actionSafeBottom = true,
    this.padding = kCenteredBodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.maxHeight;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minH > 0
                  ? (minH - padding.vertical).clamp(0.0, double.infinity)
                  : 0,
            ),
            child: Center(
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: AppLayout.contentWidth),
                    child: child)),
          ),
        );
      },
    );
    if (action == null) return content;
    return Column(children: [
      Expanded(child: content),
      AppActionArea(safeBottom: actionSafeBottom, child: action!)
    ]);
  }
}

ButtonStyle appPrimaryButtonStyle() => primaryActionStyle();

/// @deprecated Use [appPrimaryButtonStyle].
ButtonStyle protocolPrimaryButtonStyle() => appPrimaryButtonStyle();

class ProtocolPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ProtocolPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: appPrimaryButtonStyle(),
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
