import 'package:heart_feedback/shell/app_design.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/protocols/ecg/constant_rhythm_monitor.dart';
import 'package:heart_feedback/protocols/ecg/rhythm_scheduler.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/protocols/protocol_round_footer.dart';
import 'package:heart_feedback/shell/qa_skip.dart';

class HrSliderScreen extends StatefulWidget {
  final int roundIndex;

  /// Overrides default “match your own” prompt (e.g. control: match what you heard).
  final String? matchPrompt;

  /// When set, slider opens at this BPM (clamped via [sliderValueFromBpm]).
  final double? initialBpm;
  final int totalRounds;
  final String? sessionTitle;
  final String? footerLabel;

  const HrSliderScreen({
    super.key,
    required this.roundIndex,
    this.matchPrompt,
    this.initialBpm,
    this.totalRounds = 2,
    this.sessionTitle,
    this.footerLabel,
  });

  @override
  State<HrSliderScreen> createState() => _HrSliderScreenState();
}

class _HrSliderScreenState extends State<HrSliderScreen> {
  late final ValueNotifier<double> _sliderValue;
  late final RhythmScheduler _scheduler;
  int _activeWaypoint = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBpm != null
        ? sliderValueFromBpm(widget.initialBpm!.clamp(40.0, 150.0))
        : hrSliderCenter;
    _sliderValue = ValueNotifier(initial);
    _activeWaypoint = hrWaypointIndexFromSlider(_sliderValue.value);
    _scheduler = RhythmScheduler(bpm: bpmForWaypoint(_activeWaypoint));
  }

  @override
  void dispose() {
    _sliderValue.dispose();
    super.dispose();
  }

  void _onSliderChanged(double v) {
    _sliderValue.value = v;
    final wp = hrWaypointIndexFromSlider(v);
    if (wp != _activeWaypoint) {
      _activeWaypoint = wp;
      _scheduler.setBpm(bpmForWaypoint(wp));
      setState(() {});
    }
  }

  void _onSliderEnd(double v) {
    _sliderValue.value = v;
    _scheduler.setBpm(bpmFromSliderValue(v));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.sessionTitle ??
              l10n.roundHeartRateTitle(widget.roundIndex + 1),
        ),
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem(
                  'Skip slider (72 BPM)',
                  () => Navigator.of(context).pop(72.0),
                ),
              ],
            ),
        ],
      ),
      body: ProtocolRoundShell(
        action: ValueListenableBuilder<double>(
          valueListenable: _sliderValue,
          builder: (_, v, __) => ProtocolPrimaryButton(
            label: l10n.continueAction,
            onPressed: () => Navigator.of(context).pop(bpmFromSliderValue(v)),
          ),
        ),
        roundNumber: widget.roundIndex + 1,
        totalRounds: widget.totalRounds,
        footerLabel: widget.footerLabel,
        child: Builder(
          builder: (context) {
            final viewportH = MediaQuery.sizeOf(context).height;
            final monitorH = (viewportH * 0.22).clamp(120.0, 180.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: monitorH,
                  width: double.infinity,
                  child: ConstantRhythmMonitor(
                    scheduler: _scheduler,
                    height: monitorH,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.matchPrompt ?? l10n.slideTillRhythmMatches,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: AppType.body),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: _sliderValue,
                  builder: (_, v, __) => _WaypointTrack(
                    value: v,
                    activeWaypoint: _activeWaypoint,
                    onChanged: _onSliderChanged,
                    onChangeEnd: _onSliderEnd,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Smooth slider with visible waypoint ticks (rhythm changes at tick boundaries).
class _WaypointTrack extends StatelessWidget {
  final double value;
  final int activeWaypoint;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _WaypointTrack({
    required this.value,
    required this.activeWaypoint,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 12,
              width: w,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  for (var i = 0; i < hrSliderWaypointCount; i++)
                    Positioned(
                      left: w * hrSliderValueForWaypoint(i) - 1,
                      child: Container(
                        width: 2,
                        height: i == activeWaypoint ? 12 : 8,
                        decoration: BoxDecoration(
                          color: i == activeWaypoint
                              ? AppColors.accentTeal
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            activeColor: AppColors.accentTeal,
            inactiveColor: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
