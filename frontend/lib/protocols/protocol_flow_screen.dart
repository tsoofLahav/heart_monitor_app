import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/game/score_reveal_screen.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/recording/recording_guide_widgets.dart';
import 'package:heart_feedback/recording/recording_screens.dart';
import 'package:heart_feedback/shell/leave_session_dialog.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

import 'hr_slider_screen.dart';
import 'protocol_guessing_screen.dart';
import 'protocol_intro_screen.dart';
import 'protocol_models.dart';
import 'protocol_summary_screen.dart';

/// Runs one full protocol cycle (2× record → guess → slider → round summary).
class ProtocolFlowScreen extends StatefulWidget {
  /// When true, pops this route with the final step score after score reveal (e.g. forest trail).
  final bool returnScoreToCaller;

  /// Training session number 1–8 for intro header (optional).
  final int? sessionNumber;

  const ProtocolFlowScreen({
    super.key,
    this.returnScoreToCaller = false,
    this.sessionNumber,
  });

  @override
  State<ProtocolFlowScreen> createState() => _ProtocolFlowScreenState();
}

class _ProtocolFlowScreenState extends State<ProtocolFlowScreen> {
  final List<ProtocolRound> _completedRounds = [];
  int _roundInProgress = 0;

  int? _roundNetSec;
  int? _roundVideoSec;

  Map<String, dynamic>? _pendingSessionData;
  int? _pendingGuess;
  double? _pendingConfidence;

  bool _introAcknowledged = false;
  bool _roundStarted = false;

  int get _leaveSessionNumber => widget.sessionNumber ?? 1;

  Future<bool> _confirmLeave() =>
      confirmLeaveSession(context, sessionNumber: _leaveSessionNumber);

  void _onIntroAcknowledged() {
    setState(() => _introAcknowledged = true);
    if (!_roundStarted) {
      _roundStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRound());
    }
  }

  Future<void> _qaSkipWholeSession() async {
    _completedRounds
      ..clear()
      ..addAll([
        ProtocolRound(
          roundIndex: 0,
          netStableSec: 20,
          sessionData: qaFakeSessionData(peaksCount: 26, meanHrBpm: 70),
          guessedBeats: 26,
          confidencePercent: 50,
          sliderBpm: 70,
        ),
        ProtocolRound(
          roundIndex: 1,
          netStableSec: 25,
          sessionData: qaFakeSessionData(peaksCount: 32, meanHrBpm: 74),
          guessedBeats: 32,
          confidencePercent: 50,
          sliderBpm: 74,
        ),
      ]);
    final sessionResult = protocolSessionResultFromRounds(_completedRounds);
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

  Future<void> _showBadReadingDialog() async {
    if (!mounted) return;
    await showBadReadingNote(context);
  }

  String? get _sessionTitle {
    final n = widget.sessionNumber;
    if (n == null) return null;
    return context.l10n.practiceSessionHeader(n);
  }

  Future<Map<String, dynamic>?> _recordForCurrentRound() async {
    if (_roundVideoSec == null || _roundNetSec == null) {
      _roundNetSec = drawRandomNetStableSec();
      _roundVideoSec = videoSecondsForNetStable(_roundNetSec!);
    }

    final videoSec = _roundVideoSec!;
    debugPrint(
      'Protocol round $_roundInProgress: net=$_roundNetSec video=$videoSec',
    );

    while (mounted) {
      if (mounted) setState(() {});
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => ProtocolRecordingScreen(
            maxSessionSeconds: videoSec,
            recordingNumber: _roundInProgress + 1,
            sessionTitle: _sessionTitle,
          ),
        ),
      );

      if (!mounted) return null;
      if (result != null) {
        if (isBadProtocolReading(result)) {
          await _showBadReadingDialog();
          continue;
        }
        return result;
      }
      final leave = await _confirmLeave();
      if (leave) return null;
    }
    return null;
  }

  Future<void> _runRound() async {
    if (_roundInProgress >= 2 || !mounted) return;

    final sessionData = await _recordForCurrentRound();
    if (!mounted) return;
    if (sessionData == null) {
      Navigator.of(context).pop();
      return;
    }

    _pendingSessionData = sessionData;
    if (mounted) setState(() {});

    (int, double)? guessResult;
    while (mounted) {
      guessResult = await Navigator.of(context).push<(int, double)>(
        MaterialPageRoute(
          builder: (_) => ProtocolGuessingScreen(
            roundIndex: _roundInProgress,
            title: _sessionTitle,
          ),
        ),
      );
      if (!mounted) return;
      if (guessResult != null) break;
      final leave = await _confirmLeave();
      if (leave) {
        Navigator.of(context).pop();
        return;
      }
    }
    if (guessResult == null) return;
    _pendingGuess = guessResult.$1;
    _pendingConfidence = guessResult.$2;

    if (mounted) setState(() {});

    double? sliderBpm;
    while (mounted) {
      sliderBpm = await Navigator.of(context).push<double>(
        MaterialPageRoute(
          builder: (_) => HrSliderScreen(
            roundIndex: _roundInProgress,
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
    if (sliderBpm == null || _pendingSessionData == null) {
      Navigator.of(context).pop();
      return;
    }

    final round = ProtocolRound(
      roundIndex: _roundInProgress,
      netStableSec: _roundNetSec!,
      sessionData: _pendingSessionData!,
      guessedBeats: _pendingGuess!,
      confidencePercent: _pendingConfidence!,
      sliderBpm: sliderBpm,
    );

    _completedRounds.add(round);
    _pendingSessionData = null;
    _pendingGuess = null;
    _pendingConfidence = null;

    final finishedRoundIndex = _roundInProgress;
    _roundInProgress++;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (summaryCtx) => ProtocolSummaryScreen(
          rounds: [round],
          sessionTitle: _sessionTitle,
          onContinue: () => Navigator.of(summaryCtx).pop(),
        ),
      ),
    );

    if (!mounted) return;

    if (finishedRoundIndex >= 1) {
      final sessionResult = protocolSessionResultFromRounds(_completedRounds);
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
      _roundNetSec = null;
      _roundVideoSec = null;
      if (mounted) setState(() {});
      await _runRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_introAcknowledged) {
      return ProtocolIntroScreen(
        onUnderstand: _onIntroAcknowledged,
        onQaSkipSession: qaSkipEnabled ? _qaSkipWholeSession : null,
        sessionNumber: widget.sessionNumber,
      );
    }

    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              _phaseLabel(l10n),
              style: const TextStyle(
                  color: Colors.white70, fontSize: AppType.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(AppLocalizations l10n) {
    if (_roundInProgress >= 2) return l10n.preparingFinalScore;
    // Intermediate phase status has no dedicated ARB keys yet.
    return l10n.roundLabel(_roundInProgress + 1);
  }
}
