import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';

QueryHistory _makeQuery({required String id, required String userId}) {
  final now = DateTime.now();
  return QueryHistory(
    id: id,
    userId: userId,
    timestamp: now,
    transcription: 'test transcription',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService service;

  setUp(() {
    service = DatabaseService.create();
  });

  tearDown(() async {
    if (service.isInitialized) {
      await service.close();
    }
  });

  group('DatabaseService', () {
    test('initialize creates database and tables', () async {
      await service.initialize(path: inMemoryDatabasePath);
      expect(service.isInitialized, isTrue);
    });

    test('userProfileDao is accessible after initialize', () async {
      await service.initialize(path: inMemoryDatabasePath);
      expect(service.userProfileDao, isNotNull);
    });

    test('queryHistoryDao is accessible after initialize', () async {
      await service.initialize(path: inMemoryDatabasePath);
      expect(service.queryHistoryDao, isNotNull);
    });

    test('double initialize is idempotent', () async {
      await service.initialize(path: inMemoryDatabasePath);
      await service.initialize(path: inMemoryDatabasePath);
      expect(service.isInitialized, isTrue);
    });

    test('close sets database to null', () async {
      await service.initialize(path: inMemoryDatabasePath);
      await service.close();
      expect(service.isInitialized, isFalse);
    });

    test('foreign keys are enabled', () async {
      await service.initialize(path: inMemoryDatabasePath);

      final dao = service.queryHistoryDao;
      expect(
        () => dao.insert(_makeQuery(id: 'q1', userId: 'nonexistent-user')),
        throwsA(anything),
      );
    });
  });
}
