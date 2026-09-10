import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/shell/app_colors.dart';

/// Shared feedback for both experimental groups; calculations stay in the flows.
class RoundScorePanel extends StatelessWidget {
  final int actualBeats;
  final int countedBeats;
  final int countingScore;
  final int matchingScore;

  const RoundScorePanel(
      {super.key,
      required this.actualBeats,
      required this.countedBeats,
      required this.countingScore,
      required this.matchingScore});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _panel(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _beats(l10n.actualBeats, actualBeats)),
        const SizedBox(width: 20),
        Expanded(child: _beats(l10n.yourCount, countedBeats)),
      ])),
      const SizedBox(height: 16),
      _score(l10n.countScore, l10n.percentValue('$countingScore')),
      const SizedBox(height: 16),
      _score(l10n.matchingScore, l10n.percentValue('$matchingScore')),
    ]);
  }

  Widget _panel(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF191919),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12)),
        child: child,
      );

  Widget _beats(String label, int value) => Column(children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: AppType.secondary,
                height: 1.4)),
        const SizedBox(height: 12),
        Text('$value',
            style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.metric,
                fontWeight: FontWeight.w600)),
      ]);

  Widget _score(String label, String value) => _panel(Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: AppType.secondary,
                    height: 1.4))),
        const SizedBox(width: 16),
        Text(value,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: AppType.title,
                fontWeight: FontWeight.w600)),
      ]));
}
