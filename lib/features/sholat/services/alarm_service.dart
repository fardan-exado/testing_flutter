import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:test_flutter/core/utils/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AudioPlayer audioPlayer;
  Timer? _checkTimer;
  bool _isInitialized = false;
  bool _isAdzanPlaying = false;

  // Map untuk menyimpan waktu sholat
  Map<String, String> _prayerTimes = {};

  // Notification action IDs
  static const String stopAlarmActionId = 'stop_alarm';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      // Initialize notification plugin
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      audioPlayer = AudioPlayer();

      // Android notification settings dengan action buttons
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      await _requestPermissions();
      await _loadSavedPrayerTimes();
      _startPrayerTimeChecker();
      _isInitialized = true;

      logger.info('AlarmService initialized successfully');
    } catch (e) {
      logger.severe('Error initializing AlarmService: $e');
    }
  }

  // Handle notification response (termasuk action buttons)
  Future<void> _onNotificationResponse(NotificationResponse response) async {
    logger.info(
      'Notification response: actionId=${response.actionId}, payload=${response.payload}',
    );

    if (response.actionId == stopAlarmActionId) {
      // Stop adzan ketika user tap "Stop Alarm"
      await stopAdzan();
      // Cancel all immediate notifications (ID 0 dan scheduled notification)
      await flutterLocalNotificationsPlugin.cancel(0);
      if (response.payload != null) {
        final id = _getNotificationId(response.payload!);
        await flutterLocalNotificationsPlugin.cancel(id);
      }
      logger.info('Alarm stopped by user');
    } else if (response.payload != null) {
      // Ketika user tap notification (bukan stop button), play adzan jika belum play
      logger.info('User tapped notification for ${response.payload}');
      if (!_isAdzanPlaying) {
        logger.info('Playing adzan for ${response.payload}');
        await _playAdzan();
        await _showImmediateNotification(response.payload!);
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Load saved prayer times dari SharedPreferences
  Future<void> _loadSavedPrayerTimes() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // UPDATED: Gunakan penamaan yang konsisten dengan sholat_page.dart
      final prayerNames = ['Shubuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

      for (String prayerName in prayerNames) {
        final savedTime = prefs.getString('time_$prayerName');
        if (savedTime != null) {
          _prayerTimes[prayerName] = savedTime;
        }
      }

      logger.info('Loaded saved prayer times: $_prayerTimes');
    } catch (e) {
      logger.severe('Error loading saved prayer times: $e');
    }
  }

  /// Set alarm untuk sholat tertentu
  Future<void> setAlarm(String prayerName, bool enabled, String time) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final key = _getAlarmKey(prayerName);

      // Simpan status alarm
      await prefs.setBool(key, enabled);

      // Simpan waktu sholat
      _prayerTimes[prayerName] = time;
      await prefs.setString('time_$prayerName', time);

      if (enabled) {
        await _scheduleNotification(prayerName, time);
        logger.info('Alarm enabled for $prayerName at $time');
      } else {
        await _cancelNotification(prayerName);
        logger.info('Alarm disabled for $prayerName');
      }
    } catch (e) {
      logger.severe('Error setting alarm for $prayerName: $e');
      rethrow;
    }
  }

  /// Cek apakah alarm aktif
  Future<bool> isAlarmEnabled(String prayerName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final key = _getAlarmKey(prayerName);
      return prefs.getBool(key) ?? false;
    } catch (e) {
      logger.severe('Error checking alarm status for $prayerName: $e');
      return false;
    }
  }

  /// Get semua status alarm
  Future<Map<String, bool>> getAllAlarmStates() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, bool> alarmStates = {};

      // UPDATED: Gunakan penamaan yang konsisten
      final prayerNames = ['Shubuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

      for (String prayerName in prayerNames) {
        final key = _getAlarmKey(prayerName);
        alarmStates[prayerName] = prefs.getBool(key) ?? false;
      }

      return alarmStates;
    } catch (e) {
      logger.severe('Error getting alarm states: $e');
      return {};
    }
  }

  /// Update waktu sholat dan reschedule alarm yang aktif
  Future<void> updatePrayerTimes(Map<String, String> times) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      for (var entry in times.entries) {
        final oldTime = _prayerTimes[entry.key];
        _prayerTimes[entry.key] = entry.value;
        await prefs.setString('time_${entry.key}', entry.value);

        // Jika alarm aktif dan waktu berubah, reschedule
        bool isEnabled = await isAlarmEnabled(entry.key);
        if (isEnabled && oldTime != entry.value) {
          await _cancelNotification(entry.key);
          await _scheduleNotification(entry.key, entry.value);
          logger.info(
            'Rescheduled alarm for ${entry.key} from $oldTime to ${entry.value}',
          );
        }
      }

      logger.info('Prayer times updated: $times');
    } catch (e) {
      logger.severe('Error updating prayer times: $e');
    }
  }

  /// Schedule notification untuk sholat (berulang setiap hari)
  Future<void> _scheduleNotification(String prayerName, String time) async {
    try {
      final List<String> timeParts = time.split(':');

      if (timeParts.length != 2) {
        logger.warning('Invalid time format for $prayerName: $time');
        return;
      }

      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      // Create scheduled time for today
      final DateTime now = DateTime.now();
      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has passed for today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // UPDATED: Convert to TZDateTime with proper timezone
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime(
        tz.local,
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
        hour,
        minute,
      );

      // Action button untuk stop alarm
      const AndroidNotificationAction stopAction = AndroidNotificationAction(
        stopAlarmActionId,
        'Stop Alarm',
        cancelNotification: false,
        showsUserInterface: true,
      );

      // Notification details untuk scheduled alarm
      // NOTE: Sound dinonaktifkan karena audio dimainkan via AudioPlayer
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'prayer_alarm_channel',
            'Alarm Sholat',
            channelDescription: 'Notifikasi pengingat waktu sholat',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            playSound:
                false, // Disabled - audio akan dimainkan manual via AudioPlayer
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            ongoing: true,
            autoCancel: false,
            actions: const <AndroidNotificationAction>[stopAction],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: null, // Disabled - audio akan dimainkan manual via AudioPlayer
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = _getNotificationId(prayerName);

      // UPDATED: Cancel existing notification first
      await flutterLocalNotificationsPlugin.cancel(id);

      // Schedule dengan matchDateTimeComponents.time agar repeat setiap hari
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '🕌 Waktu Sholat $prayerName',
        'Saatnya melaksanakan sholat $prayerName. Allahu Akbar! 🤲',
        tzScheduledTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayerName,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      logger.info(
        'Notification scheduled for $prayerName at $time (ID: $id, Time: $tzScheduledTime, repeating daily)',
      );

      // UPDATED: Verify notification is scheduled
      final pending = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      final isScheduled = pending.any((n) => n.id == id);
      logger.info('Notification verified for $prayerName: $isScheduled');
    } catch (e) {
      logger.severe('Error scheduling notification for $prayerName: $e');
      rethrow;
    }
  }

  /// Cancel notification
  Future<void> _cancelNotification(String prayerName) async {
    try {
      final id = _getNotificationId(prayerName);
      await flutterLocalNotificationsPlugin.cancel(id);
      logger.info('Notification cancelled for $prayerName');
    } catch (e) {
      logger.severe('Error cancelling notification for $prayerName: $e');
    }
  }

  /// Dismiss notification by ID
  Future<void> _dismissNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      logger.info('Notification dismissed with ID: $id');
    } catch (e) {
      logger.severe('Error dismissing notification: $e');
    }
  }

  /// Start checker untuk mengecek waktu sholat setiap menit
  void _startPrayerTimeChecker() {
    _checkTimer?.cancel();

    // UPDATED: Check immediately first
    _checkPrayerTimes();

    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkPrayerTimes();
    });

    logger.info('Prayer time checker started');
  }

  /// Check apakah sudah waktu sholat
  Future<void> _checkPrayerTimes() async {
    try {
      final DateTime now = DateTime.now();
      final String currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      logger.info('Checking prayer times at $currentTime');
      logger.info('Prayer times to check: $_prayerTimes');

      for (String prayerName in _prayerTimes.keys) {
        final prayerTime = _prayerTimes[prayerName];

        if (prayerTime == currentTime) {
          bool isEnabled = await isAlarmEnabled(prayerName);

          logger.info('Time match for $prayerName! Alarm enabled: $isEnabled');

          if (isEnabled) {
            logger.info('Triggering alarm for $prayerName at $currentTime');
            await _playAdzan();
            await _showImmediateNotification(prayerName);
          }
        }
      }
    } catch (e) {
      logger.severe('Error checking prayer times: $e');
    }
  }

  /// Show notification immediately dengan action button
  Future<void> _showImmediateNotification(String prayerName) async {
    try {
      // Action button untuk stop alarm
      const AndroidNotificationAction stopAction = AndroidNotificationAction(
        stopAlarmActionId,
        'Stop Alarm',
        cancelNotification: false,
        showsUserInterface: true,
      );

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'prayer_now_channel',
            'Waktu Sholat Sekarang',
            channelDescription: 'Notifikasi waktu sholat tiba',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            playSound: false, // Kita play adzan manual
            fullScreenIntent: true,
            ongoing: true, // Notification tidak bisa diswipe
            autoCancel: false,
            category: AndroidNotificationCategory.alarm,
            actions: const <AndroidNotificationAction>[stopAction],
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        sound: null,
        presentAlert: true,
        presentBadge: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        0, // ID 0 untuk immediate notification
        '🕌 Waktu Sholat $prayerName Telah Tiba',
        'Mari segera melaksanakan sholat $prayerName. Tap "Stop Alarm" untuk menghentikan. 🤲',
        platformDetails,
        payload: prayerName,
      );

      logger.info('Immediate notification shown for $prayerName');
    } catch (e) {
      logger.severe('Error showing immediate notification: $e');
    }
  }

  /// Play adzan
  Future<void> _playAdzan() async {
    try {
      if (_isAdzanPlaying) {
        logger.info('Adzan already playing, skipping...');
        return;
      }

      _isAdzanPlaying = true;

      await audioPlayer.stop();
      await audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Set volume max
      await audioPlayer.setVolume(1.0);

      // Play adzan
      await audioPlayer.play(AssetSource('audio/adzan.mp3'));

      logger.info('Playing adzan...');

      // Auto stop setelah 5 menit (fallback)
      Future.delayed(const Duration(minutes: 5), () async {
        if (_isAdzanPlaying) {
          await stopAdzan();
          await _dismissNotification(0);
          logger.info('Adzan auto-stopped after 5 minutes');
        }
      });

      // Listen ketika adzan selesai
      audioPlayer.onPlayerComplete.listen((event) {
        _isAdzanPlaying = false;
        _dismissNotification(0);
        logger.info('Adzan completed');
      });
    } catch (e) {
      _isAdzanPlaying = false;
      logger.severe('Error playing adzan: $e');
    }
  }

  /// Play adzan for testing
  Future<void> playAdzanTest() async {
    await _playAdzan();
    await _showImmediateNotification('Test');
  }

  /// Stop adzan
  Future<void> stopAdzan() async {
    try {
      if (_isAdzanPlaying) {
        await audioPlayer.stop();
        _isAdzanPlaying = false;
        logger.info('Adzan stopped');
      }
    } catch (e) {
      logger.severe('Error stopping adzan: $e');
    }
  }

  /// Check if adzan is playing
  bool get isAdzanPlaying => _isAdzanPlaying;

  /// Helper untuk generate alarm key
  String _getAlarmKey(String prayerName) {
    return 'alarm_${prayerName.toLowerCase()}';
  }

  /// Helper untuk generate notification ID
  int _getNotificationId(String prayerName) {
    // Generate unique ID berdasarkan nama sholat
    return prayerName.toLowerCase().hashCode.abs();
  }

  /// Cancel all alarms
  Future<void> cancelAllAlarms() async {
    try {
      // UPDATED: Gunakan penamaan yang konsisten
      final prayerNames = ['Shubuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

      for (String prayerName in prayerNames) {
        await _cancelNotification(prayerName);
        await setAlarm(prayerName, false, '00:00');
      }

      await flutterLocalNotificationsPlugin.cancelAll();
      await stopAdzan();

      logger.info('All alarms cancelled');
    } catch (e) {
      logger.severe('Error cancelling all alarms: $e');
    }
  }

  /// Get pending notifications (untuk debug)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      logger.info('Pending notifications: ${pending.length}');
      for (var notif in pending) {
        logger.info(
          'ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}',
        );
      }
      return pending;
    } catch (e) {
      logger.severe('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Dispose service
  void dispose() {
    _checkTimer?.cancel();
    audioPlayer.dispose();
    _isInitialized = false;
    _isAdzanPlaying = false;
    logger.info('AlarmService disposed');
  }

  Future<void> debugAlarmStatus() async {
    try {
      logger.info('=== DEBUG ALARM STATUS ===');

      // Check saved times
      SharedPreferences prefs = await SharedPreferences.getInstance();
      logger.info('Saved prayer times:');
      final prayerNames = ['Shubuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
      for (String name in prayerNames) {
        final time = prefs.getString('time_$name');
        final enabled = prefs.getBool(_getAlarmKey(name));
        logger.info('  $name: time=$time, enabled=$enabled');
      }

      // Check memory state
      logger.info('Memory prayer times: $_prayerTimes');

      // Check pending notifications
      final pending = await getPendingNotifications();
      logger.info('Pending notifications: ${pending.length}');

      // Check current time
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      logger.info('Current time: $currentTime');

      logger.info('=== END DEBUG ===');
    } catch (e) {
      logger.severe('Error in debug: $e');
    }
  }
}
