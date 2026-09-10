import 'package:heart_feedback/shell/app_design.dart';
import 'package:heart_feedback/protocols/round_score_panel.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/game/score_reveal_screen.dart';
import 'package:heart_feedback/game/session_score.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/control_beep_sequence.dart';
import 'package:heart_feedback/protocols/control_listen_screen.dart';
import 'package:heart_feedback/protocols/hr_slider_screen.dart';
import 'package:heart_feedback/protocols/protocol_guessing_screen.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/leave_session_dialog.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

class _ControlRound {
  final int roundIndex;
  final ControlBeepSequence sequence;
  final int guessedBeats;
  final double confidencePercent;
  final double sliderBpm;

  const _ControlRound({
    required this.roundIndex,
    required this.sequence,
    required this.guessedBeats,
    required this.confidencePercent,
    required this.sliderBpm,
  });

  double get countScoreFraction => computeCountScoreOnly(
        guessedBeats: guessedBeats,
        actualBeats: sequence.actualBeatCount,
        confidencePercent: confidencePercent,
      );

  double get hrScoreFraction =>
      hrAccuracyFromError((sliderBpm - sequence.meanBpm).abs());

  double get combinedScoreFraction =>
      0.5 * countScoreFraction + 0.5 * hrScoreFraction;
}

ProtocolSessionResult _resultFromControlRounds(List<_ControlRound> rounds) {
  if (rounds.isEmpty) {
    return const ProtocolSessionResult(score: 0);
  }
  final sum = rounds.fold<double>(0, (a, r) => a + r.combinedScoreFraction);
  final score = ((sum / rounds.length) * 100).round().clamp(0, 100);
  final hrs = rounds.map((r) => r.sequence.meanBpm).toList();
  final avgHr = hrs.reduce((a, b) => a + b) / hrs.length;
  final duration = rounds.fold<double>(0, (a, r) => a + r.sequence.durationSec);
  return ProtocolSessionResult(
    score: score,
    avgHeartRate: avgHr,
    durationSeconds: duration,
  );
}

/// Control-arm training: listen to variable beeps → count → match heard rhythm.
class ControlProtocolFlowScreen extends StatefulWidget {
  final bool returnScoreToCaller;
  final int? sessionNumber;

  const ControlProtocolFlowScreen({
    super.key,
    this.returnScoreToCaller = false,
    this.sessionNumber,
  });

  @override
  State<ControlProtocolFlowScreen> createState() =>
      _ControlProtocolFlowScreenState();
}

class _ControlProtocolFlowScreenState extends State<ControlProtocolFlowScreen> {
  final List<_ControlRound> _completedRounds = [];
  int _roundInProgress = 0;
  bool _introAcknowledged = false;
  bool _roundStarted = false;
  String? _phaseLabel;

  void _onIntroAcknowledged() {
    setState(() => _introAcknowledged = true);
    if (!_roundStarted) {
      _roundStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRound());
    }
  }

  Future<void> _qaSkipWholeSession() async {
    final seq0 = generateControlBeepSequence();
    final seq1 = generateControlBeepSequence();
    _completedRounds
      ..clear()
      ..addAll([
        _ControlRound(
          roundIndex: 0,
          sequence: seq0,
          guessedBeats: seq0.actualBeatCount,
          confidencePercent: 50,
          sliderBpm: seq0.meanBpm,
        ),
        _ControlRound(
          roundIndex: 1,
          sequence: seq1,
          guessedBeats: seq1.actualBeatCount,
          confidencePercent: 50,
          sliderBpm: seq1.meanBpm,
        ),
      ]);
    final sessionResult = _resultFromControlRounds(_completedRounds);
    if (!mounted) return;
    if (widget.returnScoreToCaller) {
      Navigator.of(context).pop(sessionResult);
    } else {
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (scoreCtx) => ScoreRevealScreen(
            roundScore: sessionResult.score,
            showBackToMenu: true,
            onBackToMenu: () {
              Navigator.of(scoreCtx).popUntil((r) => r.isFirst);
            },
          ),
        ),
      );
    }
  }

  Future<bool> _confirmLeave() => confirmLeaveSession(
        context,
        sessionNumber: widget.sessionNumber ?? 1,
      );

  String? get _sessionTitle {
    final n = widget.sessionNumber;
    if (n == null) return null;
    return context.l10n.practiceSessionHeader(n);
  }

  Future<void> _runRound() async {
    if (_roundInProgress >= 2 || !mounted) return;
    final l10n = context.l10n;
    setState(() => _phaseLabel = l10n.roundLabel(_roundInProgress + 1));

    ControlBeepSequence? played;
    final sequence = generateControlBeepSequence();
    while (mounted) {
      played = await Navigator.of(context).push<ControlBeepSequence>(
        MaterialPageRoute(
          builder: (_) => ControlListenScreen(
            sequence: sequence,
            roundIndex: _roundInProgress,
            sessionTitle: _sessionTitle,
          ),
        ),
      );
      if (!mounted) return;
      if (played != null) break;
      final leave = await _confirmLeave();
      if (leave) {
        Navigator.of(context).pop();
        return;
      }
    }
    if (played == null) return;

    (int, double)? guess;
    while (mounted) {
      guess = await Navigator.of(context).push<(int, double)>(
        MaterialPageRoute(
          builder: (_) => ProtocolGuessingScreen(
            roundIndex: _roundInProgress,
            title: _sessionTitle,
          ),
        ),
      );
      if (!mounted) return;
      if (guess != null) break;
      final leave = await _confirmLeave();
      if (leave) {
        Navigator.of(context).pop();
        return;
      }
    }
    if (guess == null) return;

    double? sliderBpm;
    while (mounted) {
      sliderBpm = await Navigator.of(context).push<double>(
        MaterialPageRoute(
          builder: (_) => HrSliderScreen(
            roundIndex: _roundInProgress,
            matchPrompt: l10n.controlSlideTillRhythmMatches,
            sessionTitle: _sessionTitle,
          ),
        ),
      );
      if (!mounted) return;
      if (sliderBpm != null) break;
      final leave = await _confirmLeave();
      if (leave) {
        Navigator.of(context).pop();
        return;
      }
    }
    if (sliderBpm == null) return;

    final round = _ControlRound(
      roundIndex: _roundInProgress,
      sequence: played,
      guessedBeats: guess.$1,
      confidencePercent: guess.$2,
      sliderBpm: sliderBpm,
    );
    _completedRounds.add(round);
    final finished = _roundInProgress;
    _roundInProgress++;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (summaryCtx) => _ControlRoundSummaryScreen(
          round: round,
          sessionTitle: _sessionTitle,
          onContinue: () => Navigator.of(summaryCtx).pop(),
        ),
      ),
    );
    if (!mounted) return;

    if (finished >= 1) {
      final sessionResult = _resultFromControlRounds(_completedRounds);
      if (widget.returnScoreToCaller) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (scoreCtx) => ScoreRevealScreen(
              roundScore: sessionResult.score,
              onSessionComplete: (_) {
                Navigator.of(scoreCtx).pop();
                Navigator.of(context).pop(sessionResult);
              },
            ),
          ),
        );
      } else {
        await Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute(
            builder: (scoreCtx) => ScoreRevealScreen(
              roundScore: sessionResult.score,
              onSessionComplete: (_) {
                Navigator.of(scoreCtx).popUntil((r) => r.isFirst);
              },
            ),
          ),
        );
      }
    } else {
      await _runRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_introAcknowledged) {
      return _ControlIntroScreen(
        onUnderstand: _onIntroAcknowledged,
        onQaSkipSession: qaSkipEnabled ? _qaSkipWholeSession : null,
        sessionNumber: widget.sessionNumber,
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              _phaseLabel ?? l10n.roundLabel(_roundInProgress + 1),
              style: const TextStyle(
                  color: Colors.white70, fontSize: AppType.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlIntroScreen extends StatelessWidget {
  final VoidCallback onUnderstand;
  final VoidCallback? onQaSkipSession;
  final int? sessionNumber;

  const _ControlIntroScreen({
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
                l10n.controlPracticeIntroBody,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppType.secondary,
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

class _ControlRoundSummaryScreen extends StatelessWidget {
  final _ControlRound round;
  final VoidCallback onContinue;
  final String? sessionTitle;

  const _ControlRoundSummaryScreen({
    required this.round,
    required this.onContinue,
    this.sessionTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countPct = (round.countScoreFraction * 100).round();
    final hrPct = (round.hrScoreFraction * 100).round();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          sessionTitle ?? l10n.roundSummaryTitle(round.roundIndex + 1),
        ),
      ),
      body: ProtocolRoundShell(
        action: ProtocolPrimaryButton(
          label: l10n.continueAction,
          onPressed: onContinue,
        ),
        roundNumber: round.roundIndex + 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoundScorePanel(
              actualBeats: round.sequence.actualBeatCount,
              countedBeats: round.guessedBeats,
              countingScore: countPct,
              matchingScore: hrPct,
            ),
          ],
        ),
      ),
    );
  }
}
