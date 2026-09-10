import 'package:heart_feedback/shell/app_design.dart';
import 'package:heart_feedback/protocols/round_score_panel.dart';
import 'package:flutter/material.dart';

import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';

class ProtocolSummaryScreen extends StatelessWidget {
  final List<ProtocolRound> rounds;
  final VoidCallback? onContinue;
  final String? sessionTitle;

  const ProtocolSummaryScreen({
    super.key,
    required this.rounds,
    this.onContinue,
    this.sessionTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final singleRound = rounds.length == 1 ? rounds.first : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          sessionTitle ??
              (singleRound != null
                  ? l10n.roundSummaryTitle(singleRound.roundIndex + 1)
                  : l10n.protocolSummary),
        ),
      ),
      body: ProtocolRoundShell(
        action: ProtocolPrimaryButton(
          label: onContinue != null ? l10n.continueAction : l10n.done,
          onPressed: () {
            if (onContinue != null) {
              onContinue!();
            } else {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
        ),
        roundNumber:
            singleRound?.roundIndex != null ? singleRound!.roundIndex + 1 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (singleRound == null)
              Text(
                l10n.roundResults,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppType.title,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            if (singleRound == null) const SizedBox(height: 16),
            ...rounds.map((round) => _roundCard(round, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _roundCard(ProtocolRound round, AppLocalizations l10n) {
    return RoundScorePanel(
      actualBeats: round.actualPeaks,
      countedBeats: round.guessedBeats,
      countingScore: (round.countScoreFraction * 100).round(),
      matchingScore: (round.hrScoreFraction * 100).round(),
    );
  }
}
