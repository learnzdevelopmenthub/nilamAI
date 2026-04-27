/// Database schema constants, table names, and SQL DDL statements.
class DatabaseConstants {
  DatabaseConstants._();

  static const String databaseName = 'nilam_ai.db';

  /// v2 added the `crop_profile` table for multi-crop tracking (FR-3.1).
  static const int databaseVersion = 2;

  // -- Table names --
  static const String tableUserProfile = 'user_profile';
  static const String tableQueryHistory = 'query_history';
  static const String tableCropProfile = 'crop_profile';

  // -- SQL: Create tables --

  static const String createUserProfile = '''
    CREATE TABLE $tableUserProfile (
      id TEXT PRIMARY KEY,
      phone_number TEXT NOT NULL UNIQUE,
      name TEXT,
      village TEXT,
      district TEXT,
      primary_crop TEXT,
      language TEXT DEFAULT 'ta-IN',
      tts_speed REAL DEFAULT 1.0,
      notifications_enabled INTEGER DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  static const String createQueryHistory = '''
    CREATE TABLE $tableQueryHistory (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      audio_file_path TEXT,
      transcription TEXT NOT NULL,
      transcription_confidence REAL,
      gemma_prompt TEXT,
      gemma_response TEXT,
      gemma_latency_ms INTEGER,
      user_rating TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $tableUserProfile(id)
    )
  ''';

  static const String createCropProfile = '''
    CREATE TABLE $tableCropProfile (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      crop_id TEXT NOT NULL,
      variety TEXT,
      sowing_date INTEGER NOT NULL,
      land_area_acres REAL,
      soil_type TEXT,
      irrigation_type TEXT,
      status TEXT NOT NULL DEFAULT 'active',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $tableUserProfile(id)
    )
  ''';

  // -- SQL: Create indexes --

  static const String createIndexQueryUserDate =
      'CREATE INDEX idx_query_user_date ON $tableQueryHistory(user_id, timestamp DESC)';

  static const String createIndexCropProfileUser =
      'CREATE INDEX idx_crop_profile_user ON $tableCropProfile(user_id, status)';
}
