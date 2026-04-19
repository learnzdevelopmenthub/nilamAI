import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/screens/home/home_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

GoRouter _router(List<String> visited) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/record',
          builder: (_, _) {
            visited.add('/record');
            return const Scaffold(body: Text('RECORD_SCREEN'));
          },
        ),
        GoRoute(
          path: '/history',
          builder: (_, _) {
            visited.add('/history');
            return const Scaffold(body: Text('HISTORY_SCREEN'));
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) {
            visited.add('/settings');
            return const Scaffold(body: Text('SETTINGS_SCREEN'));
          },
        ),
        GoRoute(
          path: '/response/:queryId',
          builder: (_, state) {
            visited.add('/response/${state.pathParameters['queryId']}');
            return const Scaffold(body: Text('RESPONSE_SCREEN'));
          },
        ),
      ],
    );

Widget _app({
  required DatabaseService db,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [databaseServiceProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
  }
}

UserProfile _seedUser(String id, DateTime now) => UserProfile(
      id: id,
      phoneNumber: 'local_user_default',
      createdAt: now,
      updatedAt: now,
    );

QueryHistory _seedQuery(String userId, String text, DateTime ts) =>
    QueryHistory(
      id: const Uuid().v4(),
      userId: userId,
      timestamp: ts,
      transcription: text,
      transcriptionConfidence: 1.0,
      createdAt: ts,
      updatedAt: ts,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;

  setUp(() async {
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  group('HomeScreen', () {
    testWidgets('renders tagline, CTA, and AppBar action icons',
        (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited)));
      await _settle(tester);

      expect(find.text(TamilStrings.appTagline), findsOneWidget);
      expect(find.text(TamilStrings.askQuestionCta), findsOneWidget);
      expect(find.text(TamilStrings.recentQuestions), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('shows empty state when no recent queries', (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited)));
      await _settle(tester);

      expect(find.text(TamilStrings.noRecentQuestions), findsOneWidget);
    });

    testWidgets('renders recent queries when present', (tester) async {
      final visited = <String>[];
      await tester.runAsync(() async {
        final userId = const Uuid().v4();
        final now = DateTime.now();
        await db.userProfileDao.insert(_seedUser(userId, now));
        await db.queryHistoryDao
            .insert(_seedQuery(userId, 'நெல் பயிர் கேள்வி', now));
        await db.queryHistoryDao.insert(_seedQuery(
          userId,
          'மண் வளம்',
          now.subtract(const Duration(hours: 2)),
        ));
      });

      await tester.pumpWidget(_app(db: db, router: _router(visited)));
      await _settle(tester);

      expect(find.text('நெல் பயிர் கேள்வி'), findsOneWidget);
      expect(find.text('மண் வளம்'), findsOneWidget);
    });

    testWidgets('tapping CTA navigates to /record', (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited)));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.askQuestionCta));
      await _settle(tester);

      expect(visited, contains('/record'));
    });

    testWidgets('tapping settings icon navigates to /settings',
        (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited)));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await _settle(tester);

      expect(visited, contains('/settings'));
    });
  });
}
