import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:nilam_ai/screens/settings/settings_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    );

Widget _app({
  required DatabaseService db,
  required SharedPreferences prefs,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late SharedPreferences prefs;

  setUp(() async {
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsScreen', () {
    testWidgets('renders sections with default values', (tester) async {
      await tester.pumpWidget(_app(db: db, prefs: prefs));
      await _settle(tester);

      expect(find.text(TamilStrings.ttsSpeedLabel), findsOneWidget);
      expect(find.text(TamilStrings.notificationsLabel), findsOneWidget);
      expect(find.text(TamilStrings.clearHistoryLabel), findsOneWidget);
      expect(find.text(TamilStrings.aboutLabel), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
    });

    testWidgets('toggling notifications switch persists value',
        (tester) async {
      await tester.pumpWidget(_app(db: db, prefs: prefs));
      await _settle(tester);

      await tester.tap(find.byType(SwitchListTile));
      await _settle(tester);

      expect(prefs.getBool('notifications_enabled'), isFalse);
    });

    testWidgets('clear-history confirm calls deleteAllForUser',
        (tester) async {
      // Seed a user and one query.
      await tester.runAsync(() async {
        final userId = const Uuid().v4();
        final now = DateTime.now();
        await db.userProfileDao.insert(UserProfile(
          id: userId,
          phoneNumber: 'local_user_default',
          createdAt: now,
          updatedAt: now,
        ));
        await db.queryHistoryDao.insert(QueryHistory(
          id: const Uuid().v4(),
          userId: userId,
          timestamp: now,
          transcription: 'test',
          transcriptionConfidence: 1.0,
          createdAt: now,
          updatedAt: now,
        ));
      });

      await tester.pumpWidget(_app(db: db, prefs: prefs));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.clearHistoryLabel));
      await _settle(tester);
      await tester.tap(find.text(TamilStrings.delete));
      await _settle(tester);

      final user =
          await tester.runAsync(() => db.userProfileDao.getCurrent());
      final remaining = await tester
          .runAsync(() => db.queryHistoryDao.countForUser(user!.id));
      expect(remaining, equals(0));
    });
  });
}
