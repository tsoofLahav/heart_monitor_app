import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local reminders scheduled in Asia/Jerusalem for experiment sessions.
class SessionReminderService {
  SessionReminderService._();
  static final SessionReminderService instance = SessionReminderService._();

  static const israelTz = 'Asia/Jerusalem';
  static const _channelId = 'session_reminders';
  static const _channelName = 'Session reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation(israelTz));
    }

    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Returns true if notifications are allowed (or permission granted now).
  Future<bool> requestPermission() async {
    await ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> cancelAll() async {
    await ensureInitialized();
    await _plugin.cancelAll();
  }

  /// [slots]: trailStep 1..10, scheduledUtc, title, body
  Future<void> scheduleAll(
    List<({int trailStep, DateTime scheduledUtc, String title, String body})>
        slots,
  ) async {
    await ensureInitialized();
    await cancelAll();
    final location = tz.getLocation(israelTz);
    final nowUtc = DateTime.now().toUtc();

    for (final slot in slots) {
      if (!slot.scheduledUtc.isAfter(nowUtc.add(const Duration(seconds: 30)))) {
        continue;
      }
      final when = tz.TZDateTime.from(slot.scheduledUtc, location);
      await _plugin.zonedSchedule(
        slot.trailStep,
        slot.title,
        slot.body,
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Reminders for practice sessions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}

/// Convert Israel wall-clock (yyyy-MM-dd + hour/minute) to UTC.
DateTime israelWallToUtc(DateTime date, TimeOfDay time) {
  final location = tz.getLocation(SessionReminderService.israelTz);
  final local = tz.TZDateTime(
    location,
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  return local.toUtc();
}

String formatIsraelWall(DateTime date, TimeOfDay time) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$y-$m-${d}T$hh:$mm';
}

int durationMinutesForTrailStep(int trailStep) =>
    (trailStep == 1 || trailStep == 10) ? 10 : 2;
