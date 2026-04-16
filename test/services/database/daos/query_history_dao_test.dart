import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/daos/user_profile_dao.dart';
import 'package:nilam_ai/services/database/daos/query_history_dao.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';

const _userId = 'test-user';

UserProfile _makeUser() {
  final now = DateTime.now();
  return UserProfile(
    id: _userId,
    phoneNumber: 'hashed-phone',
    name: 'Test Farmer',
    district: 'Thanjavur',
    createdAt: now,
    updatedAt: now,
  );
}

QueryHistory _makeQuery({
  required String id,
  String userId = _userId,
  String transcription = 'நெல் விலை என்ன?',
  String? gemmaResponse,
  DateTime? timestamp,
}) {
  final now = timestamp ?? DateTime.now();
  return QueryHistory(
    id: id,
    userId: userId,
    timestamp: now,
    transcription: transcription,
    gemmaResponse: gemmaResponse,
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
  late UserProfileDao userDao;
  late QueryHistoryDao dao;

  setUp(() async {
    service = DatabaseService.create();
    await service.initialize(path: inMemoryDatabasePath);
    userDao = service.userProfileDao;
    dao = service.queryHistoryDao;

    // Insert a user for FK constraint.
    await userDao.insert(_makeUser());
  });

  tearDown(() async {
    await service.close();
  });

  group('QueryHistoryDao', () {
    test('insert and retrieve by ID', () async {
      final query = _makeQuery(id: 'q1');
      await dao.insert(query);

      final retrieved = await dao.getById('q1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('q1'));
      expect(retrieved.transcription, equals('நெல் விலை என்ன?'));
    });

    test('getById returns null for nonexistent', () async {
      final result = await dao.getById('no-such-id');
      expect(result, isNull);
    });

    test('getByUserId returns ordered by timestamp DESC', () async {
      final t1 = DateTime(2026, 4, 17, 8, 0);
      final t2 = DateTime(2026, 4, 17, 9, 0);
      final t3 = DateTime(2026, 4, 17, 10, 0);

      await dao.insert(_makeQuery(id: 'q1', timestamp: t1));
      await dao.insert(_makeQuery(id: 'q2', timestamp: t3));
      await dao.insert(_makeQuery(id: 'q3', timestamp: t2));

      final results = await dao.getByUserId(_userId);
      expect(results.length, equals(3));
      expect(results[0].id, equals('q2')); // t3 (latest)
      expect(results[1].id, equals('q3')); // t2
      expect(results[2].id, equals('q1')); // t1 (oldest)
    });

    test('getByUserId supports pagination', () async {
      for (var i = 0; i < 10; i++) {
        await dao.insert(_makeQuery(
          id: 'q$i',
          timestamp: DateTime(2026, 4, 17, i),
        ));
      }

      final page1 = await dao.getByUserId(_userId, limit: 3, offset: 0);
      final page2 = await dao.getByUserId(_userId, limit: 3, offset: 3);
      expect(page1.length, equals(3));
      expect(page2.length, equals(3));
      expect(page1.first.id, isNot(equals(page2.first.id)));
    });

    test('searchByKeyword finds matches in transcription', () async {
      await dao.insert(_makeQuery(id: 'q1', transcription: 'நெல் விலை'));
      await dao.insert(_makeQuery(id: 'q2', transcription: 'தக்காளி விலை'));
      await dao.insert(_makeQuery(id: 'q3', transcription: 'வானிலை'));

      final results = await dao.searchByKeyword('விலை');
      expect(results.length, equals(2));
    });

    test('searchByKeyword finds matches in gemma_response', () async {
      await dao.insert(_makeQuery(
        id: 'q1',
        transcription: 'test',
        gemmaResponse: 'Rice price is ₹2000',
      ));
      await dao.insert(_makeQuery(
        id: 'q2',
        transcription: 'test2',
        gemmaResponse: 'Tomato advice',
      ));

      final results = await dao.searchByKeyword('price');
      expect(results.length, equals(1));
      expect(results.first.id, equals('q1'));
    });

    test('searchByKeyword with userId scopes results', () async {
      // Create second user.
      final now = DateTime.now();
      await userDao.insert(UserProfile(
        id: 'user-2',
        phoneNumber: 'hash-2',
        createdAt: now,
        updatedAt: now,
      ));

      await dao.insert(_makeQuery(id: 'q1', transcription: 'நெல் விலை'));
      await dao.insert(_makeQuery(
        id: 'q2',
        userId: 'user-2',
        transcription: 'நெல் விலை',
      ));

      final results = await dao.searchByKeyword('நெல்', userId: _userId);
      expect(results.length, equals(1));
      expect(results.first.userId, equals(_userId));
    });

    test('update modifies fields', () async {
      await dao.insert(_makeQuery(id: 'q1'));
      final original = (await dao.getById('q1'))!;

      final updated = original.copyWith(
        gemmaResponse: 'New response',
        updatedAt: DateTime.now(),
      );
      await dao.update(updated);

      final retrieved = await dao.getById('q1');
      expect(retrieved!.gemmaResponse, equals('New response'));
    });

    test('delete removes record', () async {
      await dao.insert(_makeQuery(id: 'q1'));
      final deleted = await dao.delete('q1');
      expect(deleted, isTrue);
      expect(await dao.getById('q1'), isNull);
    });

    test('delete returns false for nonexistent', () async {
      final deleted = await dao.delete('no-such-id');
      expect(deleted, isFalse);
    });

    test('deleteAllForUser removes all and returns count', () async {
      await dao.insert(_makeQuery(id: 'q1'));
      await dao.insert(_makeQuery(id: 'q2'));
      await dao.insert(_makeQuery(id: 'q3'));

      final count = await dao.deleteAllForUser(_userId);
      expect(count, equals(3));

      final remaining = await dao.getByUserId(_userId);
      expect(remaining, isEmpty);
    });

    test('countForUser returns correct count', () async {
      expect(await dao.countForUser(_userId), equals(0));

      await dao.insert(_makeQuery(id: 'q1'));
      await dao.insert(_makeQuery(id: 'q2'));
      expect(await dao.countForUser(_userId), equals(2));
    });

    test('500-record search completes within 500ms', () async {
      // Insert 500 records.
      for (var i = 0; i < 500; i++) {
        await dao.insert(_makeQuery(
          id: 'perf-$i',
          transcription: 'Query number $i about rice paddy cultivation',
          timestamp: DateTime(2026, 1, 1).add(Duration(hours: i)),
        ));
      }

      final stopwatch = Stopwatch()..start();
      final results = await dao.searchByKeyword('rice', limit: 500);
      stopwatch.stop();

      expect(results.length, equals(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
