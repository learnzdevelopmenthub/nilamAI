import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/daos/user_profile_dao.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';

UserProfile _makeProfile({
  String id = 'user-1',
  String phoneNumber = 'hashed-phone-1',
  String? name = 'Test Farmer',
  String? district = 'Thanjavur',
}) {
  final now = DateTime.now();
  return UserProfile(
    id: id,
    phoneNumber: phoneNumber,
    name: name,
    village: 'TestVillage',
    district: district,
    primaryCrop: 'rice',
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
  late UserProfileDao dao;

  setUp(() async {
    service = DatabaseService.create();
    await service.initialize(path: inMemoryDatabasePath);
    dao = service.userProfileDao;
  });

  tearDown(() async {
    await service.close();
  });

  group('UserProfileDao', () {
    test('insert and retrieve by ID', () async {
      final profile = _makeProfile();
      await dao.insert(profile);

      final retrieved = await dao.getById('user-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('user-1'));
      expect(retrieved.name, equals('Test Farmer'));
    });

    test('insert duplicate phone number throws DatabaseException', () async {
      await dao.insert(_makeProfile(id: 'u1', phoneNumber: 'same-hash'));
      expect(
        () => dao.insert(_makeProfile(id: 'u2', phoneNumber: 'same-hash')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('getByPhoneHash returns correct profile', () async {
      await dao.insert(_makeProfile(phoneNumber: 'unique-hash'));
      final result = await dao.getByPhoneHash('unique-hash');
      expect(result, isNotNull);
      expect(result!.phoneNumber, equals('unique-hash'));
    });

    test('getByPhoneHash returns null for nonexistent', () async {
      final result = await dao.getByPhoneHash('no-such-hash');
      expect(result, isNull);
    });

    test('getCurrent returns first profile', () async {
      await dao.insert(_makeProfile(id: 'u1', phoneNumber: 'hash-1'));
      final result = await dao.getCurrent();
      expect(result, isNotNull);
      expect(result!.id, equals('u1'));
    });

    test('getCurrent returns null when empty', () async {
      final result = await dao.getCurrent();
      expect(result, isNull);
    });

    test('update modifies fields', () async {
      final profile = _makeProfile();
      await dao.insert(profile);

      final updated = profile.copyWith(
        name: 'Updated Name',
        updatedAt: DateTime.now(),
      );
      await dao.update(updated);

      final retrieved = await dao.getById('user-1');
      expect(retrieved!.name, equals('Updated Name'));
    });

    test('update throws for nonexistent profile', () async {
      final profile = _makeProfile(id: 'no-such-id');
      expect(
        () => dao.update(profile),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('delete removes record', () async {
      await dao.insert(_makeProfile());
      final deleted = await dao.delete('user-1');
      expect(deleted, isTrue);

      final retrieved = await dao.getById('user-1');
      expect(retrieved, isNull);
    });

    test('delete returns false for nonexistent', () async {
      final deleted = await dao.delete('no-such-id');
      expect(deleted, isFalse);
    });

    test('getById returns null for nonexistent', () async {
      final result = await dao.getById('no-such-id');
      expect(result, isNull);
    });
  });
}
