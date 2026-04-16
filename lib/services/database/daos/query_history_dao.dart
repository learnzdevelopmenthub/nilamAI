import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../../core/exceptions/app_exception.dart';
import '../../../core/logging/logger.dart';
import '../database_constants.dart';
import '../models/query_history.dart';

/// Data Access Object for [QueryHistory] CRUD and search operations.
class QueryHistoryDao {
  const QueryHistoryDao(this._database);

  final Database _database;

  static const _tag = 'QueryHistoryDao';
  static const _table = DatabaseConstants.tableQueryHistory;

  /// Insert a new query history record.
  Future<void> insert(QueryHistory query) async {
    try {
      await _database.insert(
        _table,
        query.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      AppLogger.debug('Inserted query: ${query.id}', _tag);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to insert query', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to insert query history',
        originalError: e,
      );
    }
  }

  /// Get a query by ID. Returns `null` if not found.
  Future<QueryHistory?> getById(String id) async {
    try {
      final rows = await _database.query(
        _table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return QueryHistory.fromMap(rows.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get query by ID', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to get query history',
        originalError: e,
      );
    }
  }

  /// Get all queries for a user, ordered by timestamp descending.
  ///
  /// Supports pagination via [limit] and [offset].
  Future<List<QueryHistory>> getByUserId(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _database.query(
        _table,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );
      return rows.map(QueryHistory.fromMap).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get queries by user', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to get query history for user',
        originalError: e,
      );
    }
  }

  /// Search queries by keyword in transcription or gemma_response.
  ///
  /// If [userId] is provided, results are scoped to that user.
  Future<List<QueryHistory>> searchByKeyword(
    String keyword, {
    String? userId,
    int limit = 50,
  }) async {
    try {
      final pattern = '%$keyword%';
      String where;
      List<Object?> whereArgs;

      if (userId != null) {
        where =
            'user_id = ? AND (transcription LIKE ? OR gemma_response LIKE ?)';
        whereArgs = [userId, pattern, pattern];
      } else {
        where = 'transcription LIKE ? OR gemma_response LIKE ?';
        whereArgs = [pattern, pattern];
      }

      final rows = await _database.query(
        _table,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return rows.map(QueryHistory.fromMap).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search queries', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to search query history',
        originalError: e,
      );
    }
  }

  /// Update a query record (e.g., to add gemma_response after LLM completes).
  Future<void> update(QueryHistory query) async {
    try {
      final count = await _database.update(
        _table,
        query.toMap(),
        where: 'id = ?',
        whereArgs: [query.id],
      );
      if (count == 0) {
        throw const DatabaseException(message: 'Query history not found');
      }
      AppLogger.debug('Updated query: ${query.id}', _tag);
    } on DatabaseException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update query', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to update query history',
        originalError: e,
      );
    }
  }

  /// Delete a query by ID. Returns `true` if a row was deleted.
  Future<bool> delete(String id) async {
    try {
      final count = await _database.delete(
        _table,
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.debug('Deleted query: $id (count=$count)', _tag);
      return count > 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete query', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to delete query history',
        originalError: e,
      );
    }
  }

  /// Delete all queries for a user. Returns the number of rows deleted.
  ///
  /// Used for the "clear history" privacy control.
  Future<int> deleteAllForUser(String userId) async {
    try {
      final count = await _database.delete(
        _table,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      AppLogger.info('Cleared $count queries for user: $userId', _tag);
      return count;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear queries', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to clear query history',
        originalError: e,
      );
    }
  }

  /// Get the total count of queries for a user.
  Future<int> countForUser(String userId) async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) AS count FROM $_table WHERE user_id = ?',
        [userId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to count queries', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Failed to count query history',
        originalError: e,
      );
    }
  }
}
