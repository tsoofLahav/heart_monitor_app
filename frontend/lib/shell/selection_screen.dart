import 'package:heart_feedback/shell/app_design.dart';
import 'package:flutter/material.dart';
import 'package:heart_feedback/calibration/pulse_guide_navigation.dart';
import 'package:heart_feedback/experiment/experiment_store.dart';
import 'package:heart_feedback/game/forest_trail_screen.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/prep/appreciation_questionnaire_screen.dart';
import 'package:heart_feedback/prep/prep_icon_bar.dart';
import 'package:heart_feedback/prep/prep_progress_store.dart';
import 'package:heart_feedback/prep/session_timing_screen.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/profile_screen.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen>
    with SingleTickerProviderStateMixin {
  PrepStepStatus _status = const PrepStepStatus(
    profileCompleted: false,
    questionnaireBeforeCompleted: false,
    cameraCompleted: false,
    qualityCompleted: false,
  );
  bool _loadingPrep = true;
  bool _showTrail = false;
  late final AnimationController _riseController;
  final GlobalKey _timingIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _refreshPrepState(initial: true);
    ExperimentStore.instance.bootstrap();
  }

  @override
  void dispose() {
    _riseController.dispose();
    super.dispose();
  }

  Future<void> _refreshPrepState({bool initial = false}) async {
    final status = await PrepProgressStore.instance.status();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loadingPrep = false;
      if (initial && status.isComplete) {
        _showTrail = true;
        _riseController.value = 1;
      }
    });
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (!mounted) return;
    await _refreshPrepState();
  }

  Future<void> _openQuestionnaires() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppreciationQuestionnaireScreen(phase: 'before'),
      ),
    );
    if (!mounted) return;
    await _refreshPrepState();
  }

  Future<void> _openCamera() async {
    await openCameraIdentify(context);
    if (!mounted) return;
    await _refreshPrepState();
  }

  Future<void> _openQualityPrep() async {
    await openQualityCheckFlow(context);
    if (!mounted) return;
    await _refreshPrepState();
  }

  Future<void> _openQualityMenu() async {
    await openPulseGuideComics(context);
  }

  Future<void> _openTiming({bool remindersOnly = true}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionTimingScreen(remindersOnly: remindersOnly),
      ),
    );
    if (!mounted) return;
    await _refreshPrepState();
  }

  Future<void> _startTraining() async {
    if (!_status.isComplete) return;
    setState(() => _showTrail = true);
    await _riseController.forward(from: 0);
  }

  Widget _bottomBar({bool highlightTiming = false}) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 10),
          child: PrepIconBar(
            timingKey: _timingIconKey,
            iconSize: MediaQuery.of(context).size.width * 0.095,
            highlightTiming: highlightTiming,
            onProfile: _openProfile,
            onCamera: _openCamera,
            onQuality: _openQualityMenu,
            onTiming: () => _openTiming(remindersOnly: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loadingPrep) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_showTrail) {
      return AnimatedBuilder(
        animation: _riseController,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_riseController.value);
          return Transform.translate(
            offset:
                Offset(0, (1 - t) * MediaQuery.sizeOf(context).height * 0.55),
            child: Opacity(opacity: 0.35 + 0.65 * t, child: child),
          );
        },
        child: ForestTrailHome(
          embedded: true,
          bottomBarBuilder: (highlightTiming) =>
              _bottomBar(highlightTiming: highlightTiming),
          timingIconKey: _timingIconKey,
        ),
      );
    }

    final done = _status.completedMandatoryCount;
    final total = PrepStepStatus.mandatoryTotal;
    final progress = done / total;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                children: [
                  Text(
                    l10n.prepTrainingTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppType.title,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.prepStepsProgress(done, total),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: AppType.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: AppType.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _PrepStepCard(
                    index: 1,
                    done: _status.profileCompleted,
                    title: l10n.prepCardProfileTitle,
                    subtitle: _status.profileCompleted
                        ? l10n.prepCardCompleted
                        : l10n.prepCardProfileSubtitle,
                    onTap: _openProfile,
                  ),
                  const SizedBox(height: 12),
                  _PrepStepCard(
                    index: 2,
                    done: _status.questionnaireBeforeCompleted,
                    title: l10n.prepCardQuestionnaireTitle,
                    subtitle: _status.questionnaireBeforeCompleted
                        ? l10n.prepCardCompleted
                        : l10n.prepCardQuestionnaireSubtitle,
                    onTap: _openQuestionnaires,
                  ),
                  const SizedBox(height: 12),
                  _PrepStepCard(
                    index: 3,
                    done: _status.cameraCompleted,
                    title: l10n.prepCardCameraTitle,
                    subtitle: _status.cameraCompleted
                        ? l10n.prepCardCompleted
                        : l10n.prepCardCameraSubtitle,
                    onTap: _openCamera,
                  ),
                  const SizedBox(height: 12),
                  _PrepStepCard(
                    index: 4,
                    done: _status.qualityCompleted,
                    title: l10n.prepCardQualityTitle,
                    subtitle: _status.qualityCompleted
                        ? l10n.prepCardCompleted
                        : l10n.prepCardQualitySubtitle,
                    onTap: _openQualityPrep,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
              child: _StartTrainingButton(
                unlocked: _status.isComplete,
                onPressed: _startTraining,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrepStepCard extends StatelessWidget {
  final int index;
  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrepStepCard({
    required this.index,
    required this.done,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done
                  ? AppColors.accentTeal.withValues(alpha: 0.55)
                  : Colors.white24,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: done
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.accentTeal,
                        size: 28,
                      )
                    : Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppType.title,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppType.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: done ? AppColors.accentMuted : Colors.white70,
                        fontSize: AppType.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.55),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartTrainingButton extends StatelessWidget {
  final bool unlocked;
  final VoidCallback onPressed;

  const _StartTrainingButton({
    required this.unlocked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.buttonHeight),
          child: ElevatedButton(
            style: primaryActionStyle(),
            onPressed: unlocked ? onPressed : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.prepStartTraining,
                  style: const TextStyle(
                    fontSize: AppType.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!unlocked) ...[
          const SizedBox(height: 8),
          Text(
            l10n.prepStartLockedHint,
            style: const TextStyle(
                color: Colors.white70, fontSize: AppType.secondary),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const SizedBox(height: 10),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.accent,
            size: 36,
          ),
        ],
      ],
    );
  }
}
