import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/garden_plant.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Reminder Time State (persisted) ──────────────────────

  int _reminderHour = 9;
  int _reminderMinute = 0;

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  /// Load the user's saved reminder time from SharedPreferences.
  /// Call once at startup before scheduling any notifications.
  Future<void> loadReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reminderHour = prefs.getInt('notif_reminder_hour') ?? 9;
      _reminderMinute = prefs.getInt('notif_reminder_minute') ?? 0;
      debugPrint('🔔 Reminder time loaded: $_reminderHour:${_reminderMinute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('⚠️ Failed to load reminder time: $e');
    }
  }

  /// Persist the user's preferred daily reminder time.
  /// After calling this, you should call [rescheduleAllReminders] to apply.
  Future<void> saveReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_reminder_hour', hour);
      await prefs.setInt('notif_reminder_minute', minute);
      debugPrint('🔔 Reminder time saved: $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('⚠️ Failed to save reminder time: $e');
    }
  }

  // ── Initialization ────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await loadReminderTime();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
      );
      _initialized = true;
      debugPrint('🔔 NotificationService initialized.');
    } catch (e) {
      debugPrint('⚠️ NotificationService init failed: $e');
    }
  }

  /// Request runtime notification permissions (required on Android 13+ / iOS).
  /// Call this at app startup after the first frame renders.
  Future<bool> requestPermissions() async {
    await init();
    try {
      // Android 13+ (API 33+)
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint('🔔 Android notification permission granted: $granted');
        return granted ?? false;
      }

      // iOS
      final iosImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('🔔 iOS notification permission granted: $granted');
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('⚠️ requestPermissions failed: $e');
    }
    return false;
  }

  // ── Notification Tap Handling ─────────────────────────────

  /// Called when the user taps a notification while the app is in foreground/background.
  /// Override [onNotificationTap] to handle navigation from the main app.
  static void Function(String plantId, String type)? onNotificationTap;

  static void _onNotificationTap(NotificationResponse details) {
    _handlePayload(details.payload);
  }

  @pragma('vm:entry-point')
  static void _onNotificationTapBackground(NotificationResponse details) {
    _handlePayload(details.payload);
  }

  static void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split('|');
    if (parts.length == 2) {
      final type = parts[0];   // 'water' or 'fertilize'
      final plantId = parts[1];
      debugPrint('🔔 Notification tapped: type=$type plantId=$plantId');
      onNotificationTap?.call(plantId, type);
    }
  }

  // ── Notification ID ───────────────────────────────────────

  /// Produce a stable, collision-resistant notification ID.
  /// Uses a combination of the plant ID string hash and the type offset.
  int _getNotificationId(String plantId, int type) {
    // Fold the UUID characters to produce a more distributed hash
    int hash = 0;
    for (final codeUnit in plantId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return ((hash + type * 1000003) & 0x7FFFFFFF);
  }

  // ── Time Snapping ─────────────────────────────────────────

  /// Snaps a given [targetDate] to the user's configured reminder hour/minute.
  /// If that time on the target day has already passed, pushes to the next day.
  DateTime _snapToReminderTime(DateTime targetDate) {
    final candidate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _reminderHour,
      _reminderMinute,
      0,
    );
    if (candidate.isBefore(DateTime.now())) {
      return candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  // ── Schedule Watering Reminder ────────────────────────────

  /// Schedules a watering reminder.
  ///
  /// [plantId]   — unique plant identifier (used for notification ID + payload).
  /// [nickname]  — displayed plant name in the notification.
  /// [days]      — number of days until watering is due (from [fromDate]).
  /// [fromDate]  — base date for computing the due date (defaults to now).
  ///               Pass [lastWatered] when called from updatePlant so reminders
  ///               are anchored to the actual last-watered date, not the current time.
  Future<void> scheduleWateringReminder(
    String plantId,
    String nickname,
    int days, {
    DateTime? fromDate,
  }) async {
    if (days <= 0) {
      // Plant is already overdue — cancel any stale reminder
      await cancelWateringReminder(plantId);
      return;
    }
    await init();
    if (!_initialized) return;

    final id = _getNotificationId(plantId, 1);
    final base = fromDate ?? DateTime.now();
    final rawDue = base.add(Duration(days: days));
    final scheduledDate = _snapToReminderTime(rawDue);

    try {
      await _localNotifications.cancel(id);
      await _localNotifications.zonedSchedule(
        id,
        '💧 Water $nickname',
        '"$nickname" needs watering today — give it some love!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'watering_reminders',
            'Watering Reminders',
            channelDescription: 'Daily reminders to water your plants',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'water|$plantId',
      );
      debugPrint('🔔 Watering reminder for "$nickname" scheduled at $scheduledDate');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule watering reminder: $e');
    }
  }

  // ── Schedule Fertilizing Reminder ─────────────────────────

  /// Schedules a fertilizing reminder.
  ///
  /// [fromDate] — pass [lastFertilized] when called from updatePlant so the
  ///              reminder is anchored to the actual fertilizing date.
  Future<void> scheduleFertilizingReminder(
    String plantId,
    String nickname,
    int days, {
    DateTime? fromDate,
  }) async {
    if (days <= 0) {
      await cancelFertilizingReminder(plantId);
      return;
    }
    await init();
    if (!_initialized) return;

    final id = _getNotificationId(plantId, 2);
    final base = fromDate ?? DateTime.now();
    final rawDue = base.add(Duration(days: days));
    final scheduledDate = _snapToReminderTime(rawDue);

    try {
      await _localNotifications.cancel(id);
      await _localNotifications.zonedSchedule(
        id,
        '🧪 Fertilize $nickname',
        '"$nickname" is ready for nutrients — time to fertilize!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fertilizing_reminders',
            'Fertilizing Reminders',
            channelDescription: 'Periodic reminders to fertilize your plants',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'fertilize|$plantId',
      );
      debugPrint('🔔 Fertilizing reminder for "$nickname" scheduled at $scheduledDate');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule fertilizing reminder: $e');
    }
  }

  // ── Batch Reschedule (Cold-Start Recovery) ────────────────

  /// Reschedules ALL plant reminders from scratch.
  ///
  /// Call this on every app cold start to recover from OS-cancelled notifications
  /// (phone restarts, OS-killed background tasks).
  ///
  /// Plants with [notificationsEnabled] = false are skipped (reminders cancelled).
  Future<void> rescheduleAllReminders(List<GardenPlant> plants) async {
    await init();
    if (!_initialized) return;

    debugPrint('🔔 Rescheduling reminders for ${plants.length} plant(s)...');
    for (final plant in plants) {
      if (!plant.notificationsEnabled) {
        await cancelReminders(plant.id);
        continue;
      }

      // Anchor watering reminder to lastWatered so it reflects actual next due date
      await scheduleWateringReminder(
        plant.id,
        plant.nickname,
        plant.wateringFrequencyDays,
        fromDate: plant.lastWatered,
      );

      // Anchor fertilizing reminder to lastFertilized
      await scheduleFertilizingReminder(
        plant.id,
        plant.nickname,
        plant.fertilizingFrequencyDays,
        fromDate: plant.lastFertilized,
      );
    }
    debugPrint('🔔 All reminders rescheduled successfully.');
  }

  // ── Pending Notification Inspection ──────────────────────

  /// Returns the list of currently pending notification IDs.
  /// Useful for confirming a plant's reminder is active.
  Future<List<int>> getPendingNotificationIds() async {
    await init();
    if (!_initialized) return [];
    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      return pending.map((n) => n.id).toList();
    } catch (e) {
      debugPrint('⚠️ getPendingNotificationIds failed: $e');
      return [];
    }
  }

  /// Returns true if a watering reminder is currently pending for the given plant.
  Future<bool> isWateringReminderPending(String plantId) async {
    final ids = await getPendingNotificationIds();
    return ids.contains(_getNotificationId(plantId, 1));
  }

  /// Returns true if a fertilizing reminder is currently pending for the given plant.
  Future<bool> isFertilizingReminderPending(String plantId) async {
    final ids = await getPendingNotificationIds();
    return ids.contains(_getNotificationId(plantId, 2));
  }

  // ── Cancel Reminders ──────────────────────────────────────

  Future<void> cancelWateringReminder(String plantId) async {
    await init();
    if (!_initialized) return;
    try {
      await _localNotifications.cancel(_getNotificationId(plantId, 1));
    } catch (e) {
      debugPrint('⚠️ cancelWateringReminder failed: $e');
    }
  }

  Future<void> cancelFertilizingReminder(String plantId) async {
    await init();
    if (!_initialized) return;
    try {
      await _localNotifications.cancel(_getNotificationId(plantId, 2));
    } catch (e) {
      debugPrint('⚠️ cancelFertilizingReminder failed: $e');
    }
  }

  Future<void> cancelReminders(String plantId) async {
    await cancelWateringReminder(plantId);
    await cancelFertilizingReminder(plantId);
    debugPrint('🔔 Cancelled all reminders for plant: $plantId');
  }
}
