import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Client-side 24h unlock gates between trail steps.
/// Backend progress still records completion; cooldown is local only.
class TrailUnlockStore {
  TrailUnlockStore._();
  static final TrailUnlockStore instance = TrailUnlockStore._();

  static const _key = 'trail_step_completed_at_v1';
  static const unlockDelay = Duration(hours: 24);

  Future<Map<int, DateTime>> loadCompletedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final out = <int, DateTime>{};
      for (final e in map.entries) {
        final step = int.tryParse(e.key);
        final at = DateTime.tryParse(e.value.toString());
        if (step != null && at != null) out[step] = at.toUtc();
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> markStepCompleted(int trailStep) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadCompletedAt();
    current[trailStep] = DateTime.now().toUtc();
    final encoded = jsonEncode(
      current.map((k, v) => MapEntry(k.toString(), v.toIso8601String())),
    );
    await prefs.setString(_key, encoded);
  }

  /// When [step] becomes available (UTC). Step 1 is always available.
  DateTime? unlockAtForStep(int step, Map<int, DateTime> completedAt) {
    if (step <= 1) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final prev = completedAt[step - 1];
    if (prev == null) return null;
    return prev.add(unlockDelay);
  }

  bool isStepUnlocked(
    int step, {
    required Map<int, DateTime> completedAt,
    required int completedTrailSteps,
    required bool qaBypass,
  }) {
    if (qaBypass) return true;
    if (step <= completedTrailSteps) return true; // already finished
    if (step > completedTrailSteps + 1) return false; // future beyond next
    // Next playable step:
    if (step == 1) return true;
    final unlockAt = unlockAtForStep(step, completedAt);
    if (unlockAt == null) {
      // Previous finished on server but no local timestamp — allow (migrated).
      return step == completedTrailSteps + 1;
    }
    return !DateTime.now().toUtc().isBefore(unlockAt);
  }

  Duration? remainingUntilUnlock(
    int step, {
    required Map<int, DateTime> completedAt,
  }) {
    final unlockAt = unlockAtForStep(step, completedAt);
    if (unlockAt == null) return null;
    final left = unlockAt.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }
}

/// First-time trail coach bubbles.
class TrailCoachStore {
  TrailCoachStore._();
  static final TrailCoachStore instance = TrailCoachStore._();

  static const _key = 'trail_coach_done_v1';

  Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) == true;
  }

  Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
