import 'package:sqflite/sqflite.dart' hide DatabaseException;

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'database_constants.dart';
import 'daos/user_profile_dao.dart';
import 'daos/query_history_dao.dart';

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

  static const _tag = 'DatabaseService';

  /// Whether the database has been initialized.
  bool get isInitialized => _database != null;

  /// Access the [UserProfileDao]. Asserts that [initialize] was called.
  UserProfileDao get userProfileDao {
    assert(isInitialized, 'DatabaseService not initialized. Call initialize() first.');
    return _userProfileDao!;
  }

  /// Access the [QueryHistoryDao]. Asserts that [initialize] was called.
  QueryHistoryDao get queryHistoryDao {
    assert(isInitialized, 'DatabaseService not initialized. Call initialize() first.');
    return _queryHistoryDao!;
  }

  /// Initialize the database connection and create tables.
  ///
  /// Pass [path] to override the default database path.
  /// Use `':memory:'` or an in-memory path for testing.
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info(
      'Upgrading database from v$oldVersion to v$newVersion',
      _tag,
    );
    // Sequential migration pattern:
    // if (oldVersion < 2) { await _migrateV1ToV2(db); }
    // if (oldVersion < 3) { await _migrateV2ToV3(db); }
  }

  /// Close the database connection and release resources.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _userProfileDao = null;
    _queryHistoryDao = null;
    AppLogger.info('Database closed', _tag);
  }
}
