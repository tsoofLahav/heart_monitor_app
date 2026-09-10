import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/prep/prep_progress_store.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

/// Placeholder questionnaire until real content ships.
class AppreciationQuestionnaireScreen extends StatelessWidget {
  /// `before` | `after`
  final String phase;

  const AppreciationQuestionnaireScreen({
    super.key,
    required this.phase,
  });

  Future<void> _approve(BuildContext context) async {
    if (phase == 'before') {
      await PrepProgressStore.instance.markQuestionnaireBeforeCompleted();
    }
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          phase == 'before'
              ? l10n.appreciationTitleBefore
              : l10n.appreciationTitleAfter,
        ),
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem('Approve placeholder', () => _approve(context)),
              ],
            ),
        ],
      ),
      body: ProtocolCenteredScrollBody(
        action: ProtocolPrimaryButton(
          label: l10n.approveAction,
          onPressed: () => _approve(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined,
                color: AppColors.accent, size: 64),
            const SizedBox(height: 28),
            Text(
              l10n.questionnaireComingSoon,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.title,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
