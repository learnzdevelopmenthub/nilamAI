import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/services/database/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Providers', () {
    test('databaseServiceProvider throws when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(databaseServiceProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('databaseServiceProvider works with override', () async {
      final dbService = DatabaseService.create();
      await dbService.initialize(path: inMemoryDatabasePath);

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(dbService),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await dbService.close();
      });

      expect(container.read(databaseServiceProvider), equals(dbService));
    });

    test('userProfileDaoProvider returns DAO from service', () async {
      final dbService = DatabaseService.create();
      await dbService.initialize(path: inMemoryDatabasePath);

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(dbService),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await dbService.close();
      });

      final dao = container.read(userProfileDaoProvider);
      expect(dao, isNotNull);
    });

    test('queryHistoryDaoProvider returns DAO from service', () async {
      final dbService = DatabaseService.create();
      await dbService.initialize(path: inMemoryDatabasePath);

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(dbService),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await dbService.close();
      });

      final dao = container.read(queryHistoryDaoProvider);
      expect(dao, isNotNull);
    });
  });
}
