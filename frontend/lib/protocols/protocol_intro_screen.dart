import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/leave_session_dialog.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

/// Shown once at the start of a protocol session, before the first recording.
class ProtocolIntroScreen extends StatelessWidget {
  final VoidCallback onUnderstand;
  final VoidCallback? onQaSkipSession;
  final int? sessionNumber;

  const ProtocolIntroScreen({
    super.key,
    required this.onUnderstand,
    this.onQaSkipSession,
    this.sessionNumber,
  });

  Future<void> _onLeave(BuildContext context) async {
    final n = sessionNumber ?? 1;
    final leave = await confirmLeaveSession(context, sessionNumber: n);
    if (leave && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onLeave(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(''),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onLeave(context),
          ),
          actions: [
            if (qaSkipEnabled && onQaSkipSession != null)
              QaSkipMenuButton(
                entries: [
                  qaSkipItem(
                      'Skip whole session (fake score)', onQaSkipSession!),
                ],
              ),
          ],
        ),
        body: ProtocolCenteredScrollBody(
          action: ProtocolPrimaryButton(
            label: l10n.iUnderstand,
            onPressed: onUnderstand,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sessionNumber != null) ...[
                Text(
                  l10n.practiceSessionHeader(sessionNumber!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppType.title,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
              ],
              Text(
                l10n.practiceIntroBody,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppType.body,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
