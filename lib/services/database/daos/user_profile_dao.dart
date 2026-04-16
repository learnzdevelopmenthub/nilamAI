import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../core/exceptions/app_exception.dart';
import '../../../core/logging/logger.dart';
import '../database_constants.dart';
import '../models/user_profile.dart';

/// Data Access Object for [UserProfile] CRUD operations.
class UserProfileDao {
  const UserProfileDao(this._database);

  final Database _database;

  static const _tag = 'UserProfileDao';
  static const _table = DatabaseConstants.tableUserProfile;

  /// Insert a new user profile.
  ///
  /// Throws [DatabaseException] if the phone number already exists.
  Future<void> insert(UserProfile profile) async {
    try {
      await _database.insert(
        _table,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      AppLogger.debug('Inserted profile: ${profile.id}', _tag);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to insert profile', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to insert user profile',
        originalError: e,
      );
    }
  }

  /// Get a user profile by ID. Returns `null` if not found.
  Future<UserProfile?> getById(String id) async {
    try {
      final rows = await _database.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get profile by ID', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to get user profile',
        originalError: e,
      );
    }
  }

  /// Get a user profile by hashed phone number. Returns `null` if not found.
  Future<UserProfile?> getByPhoneHash(String phoneHash) async {
    try {
      final rows = await _database.query(
        _table,
        where: 'phone_number = ?',
        whereArgs: [phoneHash],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get profile by phone', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to get user profile by phone',
        originalError: e,
      );
    }
  }

  /// Get the current (first) user profile.
  ///
  /// For the single-user MVP, only one profile exists per installation.
  Future<UserProfile?> getCurrent() async {
    try {
      final rows = await _database.query(_table, limit: 1);
      if (rows.isEmpty) return null;
      return UserProfile.fromMap(rows.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get current profile', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to get current user profile',
        originalError: e,
      );
    }
  }

  /// Update an existing user profile.
  ///
  /// Throws [DatabaseException] if the profile does not exist.
  Future<void> update(UserProfile profile) async {
    try {
      final count = await _database.update(
        _table,
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: 'User profile not found');
      }
      AppLogger.debug('Updated profile: ${profile.id}', _tag);
    } on DatabaseException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to update user profile',
        originalError: e,
      );
    }
  }

  /// Delete a user profile by ID. Returns `true` if a row was deleted.
  Future<bool> delete(String id) async {
    try {
      final count = await _database.delete(
        _table,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.debug('Deleted profile: $id (count=$count)', _tag);
      return count > 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete profile', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to delete user profile',
        originalError: e,
      );
    }
  }
}
