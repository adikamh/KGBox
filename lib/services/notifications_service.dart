import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _dailyScheduled = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // set local timezone for correct scheduling on device
    try {
      final String localTz = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (e) {
      // fallback to UTC if timezone lookup fails
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(settings);
    _initialized = true;
  }

  Future<void> showNotification(int id, String title, String body) async {
    const android = AndroidNotificationDetails(
      'kgbox_channel',
      'KGBox Notifications',
      channelDescription: 'Notifications for KGBox app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _local.show(id, title, body, details);
  }

  Future<void> scheduleDailyReminder(
    int id,
    String title,
    String body,
    int hour,
    int minute,
  ) async {
    await init();
    // compute next instance in local timezone
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _local.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kgbox_channel',
          'KGBox Notifications',
          channelDescription: 'Notifications for KGBox app',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> ensureDailyScheduled(int hour, int minute) async {
    if (_dailyScheduled) return;
    try {
      await scheduleDailyReminder(
        2000,
        'Pengingat Produk',
        'Periksa produk yang hampir kedaluwarsa.',
        hour,
        minute,
      );
      _dailyScheduled = true;
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await _local.cancelAll();
  }
}
