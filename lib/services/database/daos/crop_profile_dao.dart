import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../core/exceptions/app_exception.dart';
import '../../../core/logging/logger.dart';
import '../database_constants.dart';
import '../models/crop_profile.dart';

/// CRUD for the `crop_profile` table.
class CropProfileDao {
  const CropProfileDao(this._database);

  final Database _database;

  static const _tag = 'CropProfileDao';
  static const _table = DatabaseConstants.tableCropProfile;

  Future<void> insert(CropProfile profile) async {
    try {
      await _database.insert(
        _table,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      AppLogger.debug('Inserted crop profile: ${profile.id}', _tag);
    } catch (e, st) {
      AppLogger.error('Failed to insert crop profile', _tag, e, st);
      throw DatabaseException(
        message: 'Failed to insert crop profile',
        originalError: e,
      );
    }
  }

  Future<CropProfile?> getById(String id) async {
    try {
      final rows = await _database.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return CropProfile.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.error('Failed to get crop profile', _tag, e, st);
      throw DatabaseException(
        message: 'Failed to get crop profile',
        originalError: e,
      );
    }
  }

  /// Returns active crops first (newest sowing date first), then any
  /// non-active rows.
  Future<List<CropProfile>> getByUserId(String userId, {int limit = 50}) async {
    try {
      final rows = await _database.query(
        _table,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy:
            "CASE status WHEN 'active' THEN 0 ELSE 1 END, sowing_date DESC",
        limit: limit,
      );
      return rows.map(CropProfile.fromMap).toList();
    } catch (e, st) {
      AppLogger.error('Failed to list crop profiles', _tag, e, st);
      throw DatabaseException(
        message: 'Failed to list crop profiles',
        originalError: e,
      );
    }
  }

  Future<void> update(CropProfile profile) async {
    try {
      final count = await _database.update(
        _table,
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: 'Crop profile not found');
      }
    } on DatabaseException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('Failed to update crop profile', _tag, e, st);
      throw DatabaseException(
        message: 'Failed to update crop profile',
        originalError: e,
      );
    }
  }

  Future<bool> delete(String id) async {
    try {
      final count = await _database.delete(
        _table,
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e, st) {
      AppLogger.error('Failed to delete crop profile', _tag, e, st);
      throw DatabaseException(
        message: 'Failed to delete crop profile',
        originalError: e,
      );
    }
  }
}
