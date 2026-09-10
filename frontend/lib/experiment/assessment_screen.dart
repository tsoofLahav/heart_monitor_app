import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/experiment/assessment_models.dart';
import 'package:heart_feedback/experiment/experiment_store.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/hr_slider_screen.dart';
import 'package:heart_feedback/protocols/protocol_guessing_screen.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/recording/recording_guide_widgets.dart';
import 'package:heart_feedback/recording/recording_screens.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/leave_session_dialog.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

/// Full PRE/POST evaluation: 5 count + 6 slider match + 1 relax (12 steps).
class AssessmentScreen extends StatefulWidget {
  final String phase; // 'pre' | 'post'

  const AssessmentScreen({super.key, required this.phase});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  /// 0 = gate, 1 = step-1 instructions, 2 = running/waiting, 3 = done-error
  int _page = 0;
  bool _lockedIn = false;
  bool _running = false;
  bool _saving = false;
  String? _statusLabel;
  String? _error;

  bool get _isPre => widget.phase == 'pre';
  int get _trailSessionNumber => _isPre ? 1 : 10;

  String _sessionHeader(AppLocalizations l10n) => _isPre
      ? l10n.assessmentSessionHeaderPre
      : l10n.assessmentSessionHeaderPost;

  Future<bool> _confirmLeave(BuildContext ctx) =>
      confirmLeaveSession(ctx, sessionNumber: _trailSessionNumber);

  late final List<int> _countSchedule = buildAssessmentNetSchedule();
  late final List<int> _matchSigns = buildMatchStartOffsetSigns();
  final List<AssessmentTrialResult> _trials = [];
  final List<AssessmentMatchResult> _matches = [];
  AssessmentRelaxVitals? _relaxVitals;

  AssessmentTrialResult _fakeTrial(int netSec) {
    final peaks = (netSec * 72 / 60).round().clamp(8, 120);
    return AssessmentTrialResult(
      netStableSec: netSec,
      sessionData: qaFakeSessionData(peaksCount: peaks, meanHrBpm: 72),
      guessedBeats: peaks,
      confidencePercent: 50,
    );
  }

  AssessmentMatchResult _fakeMatch(int sign) {
    const hr = 72.0;
    final start = matchStartBpm(hr, sign);
    return AssessmentMatchResult(
      sessionData: qaFakeSessionData(peaksCount: 24, meanHrBpm: hr),
      measuredHrBpm: hr,
      startBpm: start,
      matchedBpm: hr,
    );
  }

  Future<void> _startFlow() async {
    if (_running) return;
    setState(() {
      _page = 2;
      _lockedIn = true;
      _running = true;
      _error = null;
      _trials.clear();
      _matches.clear();
      _relaxVitals = null;
    });

    // Steps 1–5: count trials
    for (var i = 0; i < _countSchedule.length; i++) {
      if (!mounted) return;
      final step = i + 1;
      if (i == 0) {
        // Step 1 instructions already shown as page 1 before start.
      } else if (i == 1) {
        final go = await _showInstruction(
          body: context.l10n.assessmentAfterStep1Body,
          step: step,
          showGoodJob: true,
        );
        if (!go) {
          _abort();
          return;
        }
      } else {
        final go = await _showInstruction(
          body: '',
          step: step,
          showGoodJob: true,
        );
        if (!go) {
          _abort();
          return;
        }
      }

      final trial = await _runCountTrial(i, _countSchedule[i]);
      if (!mounted) return;
      if (trial == null) {
        _abort();
        return;
      }
      _trials.add(trial);
    }

    // Steps 6–11: match trials
    for (var i = 0; i < assessmentMatchTrialCount; i++) {
      if (!mounted) return;
      final step = assessmentCountTrialCount + i + 1;
      if (i == 0) {
        final go = await _showInstruction(
          body: context.l10n.assessmentHalfwayMatchBody,
          step: step,
          showGoodJob: false,
        );
        if (!go) {
          _abort();
          return;
        }
      } else {
        final go = await _showInstruction(
          body: '',
          step: step,
          showGoodJob: true,
        );
        if (!go) {
          _abort();
          return;
        }
      }

      final match = await _runMatchTrial(i, _matchSigns[i]);
      if (!mounted) return;
      if (match == null) {
        _abort();
        return;
      }
      _matches.add(match);
    }

    // Step 12: relax
    if (!mounted) return;
    final goRelax = await _showInstruction(
      body: context.l10n.assessmentRelaxBody,
      step: assessmentTotalSteps,
      showGoodJob: false,
    );
    if (!goRelax) {
      _abort();
      return;
    }

    final relaxSession = await _runRecordingOnly(
      netSec: assessmentRelaxNetSec,
      recordingNumber: assessmentTotalSteps,
    );
    if (!mounted) return;
    if (relaxSession == null) {
      _abort();
      return;
    }
    _relaxVitals = AssessmentRelaxVitals.fromSession(relaxSession);

    await _saveAndFinish();
  }

  Future<bool> _showInstruction({
    required String body,
    required int step,
    bool showGoodJob = false,
  }) async {
    final l10n = context.l10n;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmLeave(ctx);
            if (leave && ctx.mounted) Navigator.of(ctx).pop(false);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: Text(
                _sessionHeader(l10n),
                style: const TextStyle(
                  fontSize: AppType.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  final leave = await _confirmLeave(ctx);
                  if (leave && ctx.mounted) Navigator.of(ctx).pop(false);
                },
              ),
              actions: [
                if (qaSkipEnabled)
                  QaSkipMenuButton(
                    entries: [
                      qaSkipItem(
                        'Continue (skip reading)',
                        () => Navigator.of(ctx).pop(true),
                      ),
                      qaSkipItem(
                        'Abort assessment',
                        () => Navigator.of(ctx).pop(false),
                      ),
                    ],
                  ),
              ],
            ),
            body: ProtocolCenteredScrollBody(
              action: ProtocolPrimaryButton(
                label: l10n.assessmentStartStep(
                  step,
                  assessmentTotalSteps,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showGoodJob) ...[
                    const Icon(
                      Icons.thumb_up_alt_rounded,
                      color: AppColors.accent,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.assessmentGoodJob,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppType.title,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (body.trim().isNotEmpty) const SizedBox(height: 20),
                  ],
                  if (body.trim().isNotEmpty)
                    _InstructionParagraphs(text: body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return result == true;
  }

  Future<void> _showFinishScreen() async {
    final l10n = context.l10n;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: ProtocolCenteredScrollBody(
            action: ProtocolPrimaryButton(
              label: l10n.continueAction,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isPre ? '🎉' : '❤️',
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 20),
                _InstructionParagraphs(
                  text: _isPre
                      ? l10n.assessmentPreFinishBody
                      : l10n.assessmentPostFinishBody,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _runRecordingOnly({
    required int netSec,
    required int recordingNumber,
  }) async {
    final videoSec = videoSecondsForNetStable(netSec);
    setState(() {
      _statusLabel = context.l10n.assessmentStepProgress(
        recordingNumber,
        assessmentTotalSteps,
      );
    });

    while (mounted) {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (ctx) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final leave = await _confirmLeave(ctx);
              if (leave && ctx.mounted) Navigator.of(ctx).pop();
            },
            child: ProtocolRecordingScreen(
              maxSessionSeconds: videoSec,
              recordingNumber: recordingNumber,
              totalRounds: assessmentTotalSteps,
              countingBeeps: recordingNumber <= assessmentCountTrialCount,
              sessionTitle: _sessionHeader(context.l10n),
              footerLabel: context.l10n.assessmentStepProgress(
                recordingNumber,
                assessmentTotalSteps,
              ),
            ),
          ),
        ),
      );
      if (!mounted) return null;
      if (result == null) return null;
      if (isBadProtocolReading(result)) {
        await showBadReadingNote(context);
        continue;
      }
      return result;
    }
    return null;
  }

  Future<AssessmentTrialResult?> _runCountTrial(int index, int netSec) async {
    final l10n = context.l10n;
    final step = index + 1;
    final sessionData = await _runRecordingOnly(
      netSec: netSec,
      recordingNumber: step,
    );
    if (sessionData == null || !mounted) return null;

    final guess = await Navigator.of(context).push<(int, double)>(
      MaterialPageRoute(
        builder: (_) => ProtocolGuessingScreen(
          roundIndex: index,
          totalRounds: assessmentTotalSteps,
          title: _sessionHeader(l10n),
          footerLabel: l10n.assessmentStepProgress(
            step,
            assessmentTotalSteps,
          ),
        ),
      ),
    );
    if (!mounted || guess == null) return null;

    return AssessmentTrialResult(
      netStableSec: netSec,
      sessionData: sessionData,
      guessedBeats: guess.$1,
      confidencePercent: guess.$2,
    );
  }

  Future<AssessmentMatchResult?> _runMatchTrial(
    int index,
    int sign, {
    int attempt = 0,
  }) async {
    final step = assessmentCountTrialCount + index + 1;
    final sessionData = await _runRecordingOnly(
      netSec: assessmentMatchNetSec,
      recordingNumber: step,
    );
    if (sessionData == null || !mounted) return null;

    final measured = meanHrFromSession(sessionData);
    if (measured == null || !measured.isFinite || measured <= 0) {
      if (attempt >= 2) return null;
      await showBadReadingNote(context);
      return _runMatchTrial(index, sign, attempt: attempt + 1);
    }

    final start = matchStartBpm(measured, sign);
    final matched = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => HrSliderScreen(
          roundIndex: index,
          initialBpm: start,
          totalRounds: assessmentTotalSteps,
          sessionTitle: _sessionHeader(context.l10n),
          footerLabel: context.l10n.assessmentStepProgress(
            step,
            assessmentTotalSteps,
          ),
        ),
      ),
    );
    if (!mounted || matched == null) return null;

    return AssessmentMatchResult(
      sessionData: sessionData,
      measuredHrBpm: measured,
      startBpm: start,
      matchedBpm: matched,
    );
  }

  Future<void> _saveAndFinish() async {
    setState(() {
      _saving = true;
      _statusLabel = context.l10n.saving;
      _error = null;
    });

    final heartbeat = heartbeatScoreFromTrials(_trials);
    final questionnaire = questionnaireScoreFromMatches(_matches);
    final relax = _relaxVitals;

    final progress = await ExperimentStore.instance.saveAssessment(
      phase: widget.phase,
      heartbeatScore: heartbeat,
      questionnaireScore: questionnaire,
      relaxMeanHrBpm: relax?.meanHrBpm,
      relaxHrvRmssd: relax?.hrvRmssd,
      relaxIbiCv: relax?.ibiCv,
      relaxDurationSeconds: relax?.durationSeconds,
      relaxPeaksCount: relax?.peaksCount,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (progress == null) {
      setState(() {
        _running = false;
        _error = context.l10n.assessmentSaveFailed;
      });
      return;
    }
    await _showFinishScreen();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _abort() {
    if (!mounted) return;
    setState(() {
      _running = false;
      _lockedIn = false;
      _page = 0;
      _statusLabel = null;
    });
    Navigator.of(context).pop(false);
  }

  Future<void> _qaSkipWholeAssessment() async {
    _trials
      ..clear()
      ..addAll([
        _fakeTrial(15),
        _fakeTrial(25),
        _fakeTrial(35),
        _fakeTrial(45),
        _fakeTrial(60),
      ]);
    _matches
      ..clear()
      ..addAll(List.generate(6, (i) => _fakeMatch(_matchSigns[i])));
    _relaxVitals = AssessmentRelaxVitals.fromSession(
      qaFakeSessionData(
        peaksCount: 72,
        meanHrBpm: 72,
        rmssd: 40,
        ibiCv: 0.05,
        durationSec: 60,
      ),
    );
    setState(() {
      _page = 2;
      _lockedIn = true;
      _running = true;
      _error = null;
    });
    await _saveAndFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: !_lockedIn,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_lockedIn) return;
        final leave = await _confirmLeave(context);
        if (leave && mounted) _abort();
      },
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_page == 0) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(''),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final leave = await _confirmLeave(context);
              if (leave && mounted) Navigator.of(context).pop(false);
            },
          ),
          actions: [
            if (qaSkipEnabled)
              QaSkipMenuButton(
                entries: [
                  qaSkipItem(
                    'Skip whole assessment (fake + save)',
                    _qaSkipWholeAssessment,
                  ),
                ],
              ),
          ],
        ),
        body: ProtocolCenteredScrollBody(
          action: ProtocolPrimaryButton(
            label: l10n.continueAction,
            onPressed: () => setState(() => _page = 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _sessionHeader(l10n),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppType.title,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _InstructionParagraphs(text: l10n.assessmentGateBody),
            ],
          ),
        ),
      );
    }

    if (_page == 1) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            _sessionHeader(l10n),
            style: const TextStyle(
              fontSize: AppType.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _page = 0),
          ),
        ),
        body: ProtocolCenteredScrollBody(
          action: ProtocolPrimaryButton(
            label: l10n.assessmentStartStep(1, assessmentTotalSteps),
            onPressed: _startFlow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InstructionParagraphs(text: l10n.assessmentStep1Body),
              if (qaSkipEnabled) ...[
                const SizedBox(height: 16),
                const Text(
                  'QA: use ✈ on recording / guess / slider screens to skip parts.',
                  style: TextStyle(
                      color: Colors.orangeAccent, fontSize: AppType.secondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ProtocolCenteredScrollBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 24),
            Text(
              _statusLabel ??
                  (_saving ? l10n.saving : l10n.assessmentPleaseWait),
              style: const TextStyle(
                  color: Colors.white70, fontSize: AppType.secondary),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.orangeAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ProtocolPrimaryButton(
                label: l10n.tryAgain,
                onPressed: () {
                  setState(() {
                    _error = null;
                    _running = true;
                  });
                  _saveAndFinish();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InstructionParagraphs extends StatelessWidget {
  final String text;

  const _InstructionParagraphs({required this.text});

  @override
  Widget build(BuildContext context) {
    final parts = text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          Text(
            parts[i],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppType.body,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
