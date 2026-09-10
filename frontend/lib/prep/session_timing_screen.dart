import 'package:heart_feedback/shell/app_design.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:heart_feedback/experiment/experiment_store.dart';
import 'package:heart_feedback/l10n/l10n.dart';
import 'package:heart_feedback/prep/prep_progress_store.dart';
import 'package:heart_feedback/prep/session_reminder_service.dart';
import 'package:heart_feedback/shell/app_colors.dart';
import 'package:heart_feedback/shell/qa_skip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class SessionTimingScreen extends StatefulWidget {
  /// When true, skip long intro copy (coach bubbles already explained schedule).
  final bool remindersOnly;

  const SessionTimingScreen({super.key, this.remindersOnly = false});

  @override
  State<SessionTimingScreen> createState() => _SessionTimingScreenState();
}

class _SessionTimingScreenState extends State<SessionTimingScreen> {
  static const _localKey = 'session_schedule_v1';

  late List<_SlotDraft> _slots;
  bool _loading = true;
  bool _saving = false;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _slotsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _slots = _defaultSlots();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<_SlotDraft> _defaultSlots() {
    final location = tz.getLocation(SessionReminderService.israelTz);
    final now = tz.TZDateTime.now(location);
    var day = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      18,
      0,
    ).add(const Duration(days: 1));
    final list = <_SlotDraft>[];
    for (var step = 1; step <= 10; step++) {
      list.add(
        _SlotDraft(
          trailStep: step,
          date: DateTime(day.year, day.month, day.day),
          time: TimeOfDay(hour: day.hour, minute: day.minute),
        ),
      );
      day = day.add(const Duration(days: 2));
    }
    return list;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        if (decoded.length == 10) {
          _slots = decoded.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final wall = m['local_wall_time']?.toString() ?? '';
            final parts = wall.split('T');
            final dateParts = parts[0].split('-');
            final timeParts =
                (parts.length > 1 ? parts[1] : '18:00').split(':');
            return _SlotDraft(
              trailStep: (m['trail_step'] as num).toInt(),
              enabled: m['enabled'] == true,
              date: DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              ),
              time: TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1]),
              ),
            );
          }).toList();
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  String _kindLabel(AppLocalizations l10n, int step) {
    if (step == 1) return l10n.timingSessionKindPre;
    if (step == 10) return l10n.timingSessionKindPost;
    return l10n.timingSessionKindTraining(step - 1);
  }

  Future<void> _pickDate(int index) async {
    final current = _slots[index];
    final picked = await showDatePicker(
      context: context,
      initialDate: current.date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _slots[index] = current.copyWith(date: picked);
    });
  }

  Future<void> _pickTime(int index) async {
    final current = _slots[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: current.time,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _slots[index] = current.copyWith(time: picked, enabled: true);
    });
  }

  void _scrollToSlots() {
    final ctx = _slotsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
      return;
    }
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent * 0.35,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final enableNotifications = _slots.any((s) => s.enabled);
    final l10n = context.l10n;
    setState(() => _saving = true);

    final payload = _slots.map((s) {
      final utc = israelWallToUtc(s.date, s.time);
      return <String, dynamic>{
        'trail_step': s.trailStep,
        'enabled': s.enabled,
        'scheduled_at_utc': utc.toIso8601String(),
        'local_wall_time': formatIsraelWall(s.date, s.time),
        // Existing server/SQL schema uses 7 for assessment schedule metadata.
        // User-facing estimates and reminder copy remain 10 minutes.
        'duration_minutes': (s.trailStep == 1 || s.trailStep == 10) ? 7 : 2,
        'timezone_id': SessionReminderService.israelTz,
      };
    }).toList();

    final prefs = await SharedPreferences.getInstance();

    if (enableNotifications) {
      final permitted =
          await SessionReminderService.instance.requestPermission();
      if (permitted) {
        final notifSlots = _slots.where((s) => s.enabled).map((s) {
          final utc = israelWallToUtc(s.date, s.time);
          final minutes = durationMinutesForTrailStep(s.trailStep);
          return (
            trailStep: s.trailStep,
            scheduledUtc: utc,
            title: l10n.timingNotifTitle,
            body: l10n.timingNotifBody(s.trailStep, minutes),
          );
        }).toList();
        await SessionReminderService.instance.scheduleAll(notifSlots);
      } else if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.timingNotifPermissionDenied)),
        );
        return;
      }
    } else {
      await SessionReminderService.instance.cancelAll();
    }

    await prefs.setString(_localKey, jsonEncode(payload));

    final synced = await ExperimentStore.instance.saveSessionSchedule(payload);
    await PrepProgressStore.instance.markTimingCompleted();

    if (!mounted) return;
    setState(() => _saving = false);

    if (!synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.timingSaveFailed)),
      );
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _qaSkip() async {
    _slots = _defaultSlots();
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.timingTitle),
        actions: [
          if (qaSkipEnabled)
            QaSkipMenuButton(
              entries: [
                qaSkipItem('Finish without notifications', _qaSkip),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    children: [
                      if (!widget.remindersOnly) ...[
                        Text(
                          l10n.timingIntro,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppType.body,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.timingNotificationsHint,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: AppType.secondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _scrollToSlots,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            children: [
                              Text(
                                l10n.timingScrollToReminders,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: AppType.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.accent,
                                size: 42,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.18,
                        ),
                      ],
                      KeyedSubtree(
                        key: _slotsKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.timingRemindersSection,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppType.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.timingIsraelNote,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: AppType.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (var i = 0; i < _slots.length; i++) ...[
                              _slotCard(l10n, i),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppActionArea(
                    child: ElevatedButton(
                  style: primaryActionStyle(),
                  onPressed: _saving ? null : _finish,
                  child: Text(_saving ? l10n.saving : l10n.timingFinish,
                      textAlign: TextAlign.center),
                )),
              ],
            ),
    );
  }

  Widget _slotCard(AppLocalizations l10n, int index) {
    final slot = _slots[index];
    final dateLabel =
        '${slot.date.year}-${slot.date.month.toString().padLeft(2, '0')}-${slot.date.day.toString().padLeft(2, '0')}';
    final timeLabel =
        '${slot.time.hour.toString().padLeft(2, '0')}:${slot.time.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                l10n.timingSessionLabel(slot.trailStep),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(
              value: slot.enabled,
              activeThumbColor: AppColors.accent,
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _slots[index] = slot.copyWith(enabled: value);
                      }),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            _kindLabel(l10n, slot.trailStep),
            style: const TextStyle(
                color: Colors.white70, fontSize: AppType.secondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _pickDate(index),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: Text('${l10n.timingPickDate}: $dateLabel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _pickTime(index),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: Text('${l10n.timingPickTime}: $timeLabel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotDraft {
  final int trailStep;
  final DateTime date;
  final TimeOfDay time;
  final bool enabled;

  const _SlotDraft({
    required this.trailStep,
    required this.date,
    required this.time,
    this.enabled = false,
  });

  _SlotDraft copyWith({DateTime? date, TimeOfDay? time, bool? enabled}) {
    return _SlotDraft(
      trailStep: trailStep,
      date: date ?? this.date,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
    );
  }
}
