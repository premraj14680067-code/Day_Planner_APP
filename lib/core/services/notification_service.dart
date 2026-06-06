// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap – navigate to relevant screen
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── Schedule block reminder ──────────────────────────────────────────────

  Future<void> scheduleBlockReminder({
    required int id,
    required String blockTitle,
    required DateTime blockStart,
    int minutesBefore = 5,
  }) async {
    final scheduledTime = blockStart.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '⏰ Starting in $minutesBefore min',
      blockTitle,
      tz.TZDateTime.from(scheduledTime, tz.local),
      _notificationDetails(channelId: 'block_reminders', channelName: 'Block Reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Daily summary notification ───────────────────────────────────────────

  Future<void> scheduleDailySummary({
    required int hour,
    required int minute,
  }) async {
    await _plugin.periodicallyShowWithDuration(
      999,
      '📊 Daily Summary',
      'Check how your day went in DayPilot',
      const Duration(days: 1),
      _notificationDetails(channelId: 'daily_summary', channelName: 'Daily Summary'),
    );
  }

  // ─── Show instant notification ────────────────────────────────────────────

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      _notificationDetails(channelId: 'general', channelName: 'General'),
    );
  }

  // ─── Cancel notification ──────────────────────────────────────────────────

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();

  // ─── Helper ───────────────────────────────────────────────────────────────

  NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
