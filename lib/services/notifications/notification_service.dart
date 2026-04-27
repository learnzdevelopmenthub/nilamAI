import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/logging/logger.dart';

/// Thin wrapper around `flutter_local_notifications` for crop stage
/// reminders.
///
/// Responsible only for plugin lifecycle and the low-level schedule API;
/// domain logic (which crops + which days) lives in
/// [CropReminderScheduler].
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _tag = 'NotificationService';
  static const _channelId = 'crop_stage_reminders';
  static const _channelName = 'Crop stage reminders';
  static const _channelDescription =
      'Stage transition reminders for your crops';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      // Demo target audience is South India; bias toward Asia/Kolkata. Swap
      // to FlutterTimezone.getLocalTimezone() when iOS / wider geography
      // ships.
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const init = InitializationSettings(android: android);
      await _plugin.initialize(init);
      _initialized = true;
      AppLogger.info('Notifications initialized', _tag);
    } catch (e, st) {
      AppLogger.error('Notification init failed', _tag, e, st);
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      final notif = await android.requestNotificationsPermission();
      final exact = await android.requestExactAlarmsPermission();
      return (notif ?? false) && (exact ?? false);
    } catch (e, st) {
      AppLogger.warning('Permission request failed: $e\n$st', _tag);
      return false;
    }
  }

  Future<void> scheduleStageReminder({
    required String cropId,
    required String stageId,
    required DateTime scheduledFor,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    final id = stableId(cropId, stageId);
    final when = tz.TZDateTime.from(scheduledFor, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'crop:$cropId|stage:$stageId',
      );
    } catch (e, st) {
      AppLogger.warning(
        'Failed to schedule notification for $cropId/$stageId: $e\n$st',
        _tag,
      );
    }
  }

  Future<void> cancelForCrop(String cropId) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.payload != null && p.payload!.startsWith('crop:$cropId|')) {
          await _plugin.cancel(p.id);
        }
      }
    } catch (e, st) {
      AppLogger.warning('cancelForCrop($cropId) failed: $e\n$st', _tag);
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e, st) {
      AppLogger.warning('cancelAll failed: $e\n$st', _tag);
    }
  }

  /// 31-bit positive int derived from a stable hash of (cropId, stageId).
  /// Re-running [scheduleStageReminder] with the same key replaces the
  /// prior entry instead of duplicating it.
  static int stableId(String cropId, String stageId) {
    return '$cropId|$stageId'.hashCode & 0x7fffffff;
  }
}
