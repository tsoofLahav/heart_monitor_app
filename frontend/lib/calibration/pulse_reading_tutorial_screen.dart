import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/pulse_guide_progress_store.dart';
import 'package:heart_feedback/calibration/pulse_guide_step_image.dart';
import 'package:heart_feedback/game/signal_chart_painter.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/recording/recording_guide_widgets.dart';
import 'package:heart_feedback/recording/recording_screens.dart';
import 'package:heart_feedback/shell/app_colors.dart';

const int _requiredStreak = 3;

enum PulseReadingTutorialMode { instructions, practice, full }

enum _TutorialStep { instructions, practiceHome, practiceResult, complete }

class PulseReadingTutorialScreen extends StatefulWidget {
  final PulseReadingTutorialMode mode;

  const PulseReadingTutorialScreen({
    super.key,
    this.mode = PulseReadingTutorialMode.instructions,
  });

  @override
  State<PulseReadingTutorialScreen> createState() =>
      _PulseReadingTutorialScreenState();
}

class _PulseReadingTutorialScreenState
    extends State<PulseReadingTutorialScreen> {
  late _TutorialStep _step;
  int _successStreak = 0;
  int _attemptCount = 0;
  Map<String, dynamic>? _lastResult;
  bool _lastSuccess = false;
  bool _completionPersisted = false;

  @override
  void initState() {
    super.initState();
    _step = widget.mode == PulseReadingTutorialMode.practice
        ? _TutorialStep.practiceHome
        : _TutorialStep.instructions;
  }

  Future<void> _markInstructionsSeen() async {
    await PulseGuideProgressStore.instance.markInstructionsCompleted();
  }

  Future<void> _persistAttempt({
    required bool success,
    required int streakAfter,
    String? qualityLabel,
    bool notReading = false,
  }) async {
    await PulseGuideProgressStore.instance.recordAttempt(
      attemptNumber: _attemptCount,
      success: success,
      successStreakAfter: streakAfter,
      qualityLabel: qualityLabel,
      notReading: notReading,
    );
  }

  Future<void> _persistCompletionIfNeeded() async {
    if (_completionPersisted || _step != _TutorialStep.complete) return;
    _completionPersisted = true;
    await PulseGuideProgressStore.instance
        .markCompleted(totalAttempts: _attemptCount);
  }

  Future<void> _startPracticeRound() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const LearnPracticeRecordingScreen()),
    );

    if (!mounted) return;

    if (result == null || result['not_reading'] == true) {
      setState(() {
        _attemptCount += 1;
        _successStreak = 0;
        _lastSuccess = false;
        _lastResult = null;
        _step = _TutorialStep.practiceResult;
      });
      await _persistAttempt(
        success: false,
        streakAfter: 0,
        notReading: result == null || result['not_reading'] == true,
      );
      return;
    }

    final label = (result['quality_label'] as String?) ?? 'bad';
    final success = label == 'good';

    setState(() {
      _attemptCount += 1;
      _lastResult = result;
      _lastSuccess = success;
      _successStreak = success ? _successStreak + 1 : 0;
      _step = success && _successStreak >= _requiredStreak
          ? _TutorialStep.complete
          : _TutorialStep.practiceResult;
    });

    final streakAfter = _successStreak;
    await _persistAttempt(
      success: success,
      streakAfter: streakAfter,
      qualityLabel: label,
    );
    if (_step == _TutorialStep.complete) {
      await _persistCompletionIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_appBarTitle(l10n)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.of(context).pop(_step == _TutorialStep.complete),
        ),
      ),
      body: switch (_step) {
        _TutorialStep.instructions => PulseGuideInstructionsPager(
            onFinished: () async {
              await _markInstructionsSeen();
              if (!mounted) return;
              if (widget.mode == PulseReadingTutorialMode.full) {
                await _startPracticeRound();
              } else {
                Navigator.of(context).pop(true);
              }
            },
            onPracticeOfferReached: _markInstructionsSeen,
          ),
        _TutorialStep.practiceHome => ProtocolCenteredScrollBody(
            child: _buildPracticeHome(l10n),
          ),
        _TutorialStep.practiceResult => _buildPracticeResult(l10n),
        _TutorialStep.complete => ProtocolCenteredScrollBody(
            action: ProtocolPrimaryButton(
                label: l10n.continueAction,
                onPressed: () => Navigator.of(context).pop(true)),
            child: _buildComplete(l10n),
          ),
      },
    );
  }

  String _appBarTitle(AppLocalizations l10n) {
    return switch (_step) {
      _TutorialStep.instructions => l10n.instructionsTitle,
      _TutorialStep.practiceHome => l10n.qualityPracticeTitle,
      _TutorialStep.practiceResult => l10n.practiceResultTitle,
      _TutorialStep.complete => l10n.tutorialCompleteTitle,
    };
  }

  Widget _buildPracticeHome(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _streakIndicator(),
        const SizedBox(height: 16),
        Text(
          l10n.get3GoodReadings,
          style: const TextStyle(
              color: Colors.white70, fontSize: AppType.secondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        ProtocolPrimaryButton(
          label: l10n.startPractice,
          onPressed: _startPracticeRound,
        ),
      ],
    );
  }

  Widget _buildPracticeResult(AppLocalizations l10n) {
    final data = _lastResult;
    final signal = _extractSignal(data);
    final peaks = _extractPeaks(data);
    final sampleRate = (data?['fps'] as num?)?.toDouble();
    final signalStart = (data?['signal_start_sec'] as num?)?.toDouble();
    final signalEnd = (data?['signal_end_sec'] as num?)?.toDouble();
    final duration = signalStart != null && signalEnd != null
        ? signalEnd - signalStart
        : (data?['duration'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _resultBadge(_lastSuccess, l10n),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (signal.isNotEmpty) ...[
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SignalWithPeaksPainter(
                          signal: signal,
                          realPeaks: peaks,
                          duration: duration,
                          sampleRate: sampleRate,
                        ),
                        child: Container(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (!_lastSuccess)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          const BadReadingStepHint(height: 110),
                          const SizedBox(height: 8),
                          Text(
                            l10n.practiceRetryHint,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: AppType.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    _streakIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.streakProgress(_successStreak, _requiredStreak),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: AppType.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        AppActionArea(
          child: ProtocolPrimaryButton(
            label: _lastSuccess ? l10n.nextRound : l10n.tryAgain,
            onPressed: _startPracticeRound,
          ),
        ),
      ],
    );
  }

  Widget _buildComplete(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: AppColors.accent, size: 80),
        const SizedBox(height: 24),
        Text(
          l10n.tutorialComplete,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppType.title,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.tutorialCompleteBody(_requiredStreak, _attemptCount),
          style: const TextStyle(
              color: Colors.white70, fontSize: AppType.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _resultBadge(bool success, AppLocalizations l10n) {
    final qualityLabel =
        (_lastResult?['quality_label'] as String?)?.toUpperCase() ?? '?';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade900 : Colors.red.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            success ? l10n.successful : l10n.notSuccessful,
            style: TextStyle(
              color: success ? Colors.greenAccent : Colors.redAccent,
              fontSize: AppType.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.readingQuality(qualityLabel),
              style: const TextStyle(
                  color: Colors.white70, fontSize: AppType.secondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _streakIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_requiredStreak, (i) {
        final filled = i < _successStreak;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            filled ? Icons.fingerprint : Icons.fingerprint_outlined,
            color: filled ? AppColors.accent : Colors.white24,
            size: 36,
          ),
        );
      }),
    );
  }

  List<double> _extractSignal(Map<String, dynamic>? data) {
    final raw = data?['clean_signal'];
    if (raw is! List) return [];
    return raw.map((e) => (e as num).toDouble()).toList();
  }

  List<double> _extractPeaks(Map<String, dynamic>? data) {
    final raw = data?['real_peaks'];
    if (raw is! List) return [];
    return raw.map((e) => (e as num).toDouble()).toList();
  }
}
