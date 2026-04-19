import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/user_providers.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<(ProviderContainer, DatabaseService)> makeContainer() async {
    final db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
    final container = ProviderContainer(
      overrides: [databaseServiceProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    return (container, db);
  }

  group('currentUserIdProvider', () {
    test('bootstraps a default user when none exists', () async {
      final (container, db) = await makeContainer();
      expect(await db.userProfileDao.getCurrent(), isNull);

      final id = await container.read(currentUserIdProvider.future);

      final user = await db.userProfileDao.getCurrent();
      expect(user, isNotNull);
      expect(user!.id, equals(id));
      expect(user.phoneNumber, equals('local_user_default'));
    });

    test('returns the existing user id on subsequent reads', () async {
      final (container, _) = await makeContainer();
      final first = await container.read(currentUserIdProvider.future);
      container.invalidate(currentUserIdProvider);
      final second = await container.read(currentUserIdProvider.future);
      expect(second, equals(first));
    });
  });
}
