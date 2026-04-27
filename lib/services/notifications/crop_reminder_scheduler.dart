import '../../core/logging/logger.dart';
import '../database/daos/crop_profile_dao.dart';
import '../database/models/crop_profile.dart';
import '../knowledge/crop_knowledge.dart';
import '../knowledge/crop_knowledge_service.dart';
import 'notification_service.dart';

/// Reads a [CropProfile], walks its bundled stage timeline, and schedules
/// one notification on the morning of each upcoming stage transition
/// (within 90 days). Idempotent — cancels any prior schedule for the crop
/// before writing new ones, so re-calling is safe.
class CropReminderScheduler {
  CropReminderScheduler({
    required NotificationService notifications,
    required CropKnowledgeService knowledgeService,
    required CropProfileDao cropDao,
    required bool Function() notificationsEnabled,
  })  : _notifications = notifications,
        _knowledge = knowledgeService,
        _cropDao = cropDao,
        _notificationsEnabled = notificationsEnabled;

  static const _tag = 'CropReminderScheduler';
  static const _horizonDays = 90;
  static const _hourOfDay = 9;

  final NotificationService _notifications;
  final CropKnowledgeService _knowledge;
  final CropProfileDao _cropDao;
  final bool Function() _notificationsEnabled;

  /// Cancels stale reminders for [crop] and (re)schedules upcoming stage
  /// transitions. Skips entirely when notifications are disabled in
  /// settings.
  Future<void> scheduleFor(CropProfile crop) async {
    await _notifications.cancelForCrop(crop.id);
    if (!_notificationsEnabled()) return;

    final base = await _knowledge.load();
    final tpl = base.byId(crop.cropId);
    if (tpl == null) {
      AppLogger.warning(
        'Unknown cropId ${crop.cropId} — skipping reminders',
        _tag,
      );
      return;
    }

    final now = DateTime.now();
    final horizon = now.add(const Duration(days: _horizonDays));
    for (final stage in tpl.stages) {
      // Skip the very first stage: there's no "transition" — sowing day
      // doesn't need a reminder.
      if (stage.startDay == 0) continue;
      final transitionDay =
          crop.sowingDate.add(Duration(days: stage.startDay));
      final fireAt = DateTime(
        transitionDay.year,
        transitionDay.month,
        transitionDay.day,
        _hourOfDay,
      );
      if (fireAt.isBefore(now) || fireAt.isAfter(horizon)) continue;

      await _notifications.scheduleStageReminder(
        cropId: crop.id,
        stageId: stage.id,
        scheduledFor: fireAt,
        title: '${tpl.name}: ${stage.name} stage starts',
        body: _shortBodyFor(stage, tpl),
      );
    }
  }

  /// Loads every crop for the current user and reschedules each. Used at
  /// app cold start (in case the OS lost pending alarms) and on the
  /// notifications toggle.
  Future<void> rescheduleAll(String userId) async {
    if (!_notificationsEnabled()) {
      // Walk DB so we can clear stale schedules.
      try {
        final crops = await _cropDao.getByUserId(userId);
        for (final c in crops) {
          await _notifications.cancelForCrop(c.id);
        }
      } catch (e, st) {
        AppLogger.warning('rescheduleAll cancel pass failed: $e\n$st', _tag);
      }
      return;
    }
    try {
      final crops = await _cropDao.getByUserId(userId);
      for (final c in crops) {
        if (c.status == 'active') await scheduleFor(c);
      }
    } catch (e, st) {
      AppLogger.warning('rescheduleAll failed: $e\n$st', _tag);
    }
  }

  static String _shortBodyFor(CropStage stage, CropTemplate tpl) {
    if (stage.keyActivities.isEmpty) {
      return "Check today's recommended activities for your ${tpl.name}.";
    }
    final joined = stage.keyActivities.join(' ');
    if (joined.length <= 120) return joined;
    return '${joined.substring(0, 117).trimRight()}…';
  }
}
