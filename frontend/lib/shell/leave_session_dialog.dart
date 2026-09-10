import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/shell/app_colors.dart';

/// Confirm leaving a practice / assessment session mid-flow.
Future<bool> confirmLeaveSession(
  BuildContext context, {
  required int sessionNumber,
}) async {
  final l10n = context.l10n;
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 2.5),
      ),
      icon: const Icon(Icons.error_outline, color: Colors.white70),
      title: Text(
        l10n.leaveSessionTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        l10n.leaveSessionBody(sessionNumber),
        style: const TextStyle(color: Colors.white70, height: 1.4),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Row(children: [
          Expanded(
              child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              backgroundColor: AppColors.accent.withValues(alpha: 0.10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: AppType.secondary),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(
              child: TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.leaveSessionConfirm,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          )),
        ])
      ],
    ),
  );
  return leave == true;
}
