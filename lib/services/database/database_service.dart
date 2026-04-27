import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'database_constants.dart';
import 'daos/crop_profile_dao.dart';
import 'daos/query_history_dao.dart';
import 'daos/user_profile_dao.dart';

/// Central database service that manages the SQLite connection,
/// schema creation, migrations, and DAO access.
///
/// Created via [DatabaseService.create] and initialized with [initialize].
/// Typically used as a singleton through Riverpod.
class DatabaseService {
  DatabaseService._internal();

  /// Create a new [DatabaseService] instance.
  ///
  /// Call [initialize] before accessing DAOs.
  static DatabaseService create() => DatabaseService._internal();

  Database? _database;
  UserProfileDao? _userProfileDao;
  QueryHistoryDao? _queryHistoryDao;
  CropProfileDao? _cropProfileDao;

  static const _tag = 'DatabaseService';

  /// Whether the database has been initialized.
  bool get isInitialized => _database != null;

  UserProfileDao get userProfileDao {
    assert(isInitialized,
        'DatabaseService not initialized. Call initialize() first.');
    return _userProfileDao!;
  }

  QueryHistoryDao get queryHistoryDao {
    assert(isInitialized,
        'DatabaseService not initialized. Call initialize() first.');
    return _queryHistoryDao!;
  }

  CropProfileDao get cropProfileDao {
    assert(isInitialized,
        'DatabaseService not initialized. Call initialize() first.');
    return _cropProfileDao!;
  }

  Future<void> initialize({String? path}) async {
    if (_database != null) {
      AppLogger.warning('Database already initialized', _tag);
      return;
    }

    try {
      final dbPath = path ??
          '${await getDatabasesPath()}/${DatabaseConstants.databaseName}';

      _database = await openDatabase(
        dbPath,
        version: DatabaseConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );

      _userProfileDao = UserProfileDao(_database!);
      _queryHistoryDao = QueryHistoryDao(_database!);
      _cropProfileDao = CropProfileDao(_database!);

      AppLogger.info('Database initialized at: $dbPath', _tag);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize database', _tag, e, stackTrace);
      throw DatabaseException(
        message: 'Database initialization failed',
        originalError: e,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('Creating database schema v$version', _tag);
    await db.execute(DatabaseConstants.createUserProfile);
    await db.execute(DatabaseConstants.createQueryHistory);
    await db.execute(DatabaseConstants.createIndexQueryUserDate);
    await db.execute(DatabaseConstants.createCropProfile);
    await db.execute(DatabaseConstants.createIndexCropProfileUser);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info(
      'Upgrading database from v$oldVersion to v$newVersion',
      _tag,
    );
    if (oldVersion < 2) {
      await db.execute(DatabaseConstants.createCropProfile);
      await db.execute(DatabaseConstants.createIndexCropProfileUser);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _userProfileDao = null;
    _queryHistoryDao = null;
    _cropProfileDao = null;
    AppLogger.info('Database closed', _tag);
  }
}
