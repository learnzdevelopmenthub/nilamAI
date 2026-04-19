import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/screens/history/history_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(
          path: '/response/:queryId',
          builder: (_, _) => const Scaffold(body: Text('RESPONSE_SCREEN')),
        ),
      ],
    );

Widget _app({required DatabaseService db}) {
  return ProviderScope(
    overrides: [databaseServiceProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

Future<String> _seedUserAndQueries(
  DatabaseService db, {
  List<String> texts = const [],
}) async {
  final userId = const Uuid().v4();
  final now = DateTime.now();
  await db.userProfileDao.insert(UserProfile(
    id: userId,
    phoneNumber: 'local_user_default',
    createdAt: now,
    updatedAt: now,
  ));
  for (var i = 0; i < texts.length; i++) {
    await db.queryHistoryDao.insert(QueryHistory(
      id: const Uuid().v4(),
      userId: userId,
      timestamp: now.subtract(Duration(minutes: i)),
      transcription: texts[i],
      transcriptionConfidence: 1.0,
      createdAt: now,
      updatedAt: now,
    ));
  }
  return userId;
}

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

  group('HistoryScreen', () {
    testWidgets('renders empty state when no queries', (tester) async {
      await tester.pumpWidget(_app(db: db));
      await _settle(tester);

      expect(find.text(TamilStrings.historyEmpty), findsOneWidget);
    });

    testWidgets('renders the query list', (tester) async {
      await tester.runAsync(() => _seedUserAndQueries(
            db,
            texts: ['நெல் பயிர்', 'மண் வளம்', 'பூச்சி நாசினி'],
          ));
      await tester.pumpWidget(_app(db: db));
      await _settle(tester);

      expect(find.text('நெல் பயிர்'), findsOneWidget);
      expect(find.text('மண் வளம்'), findsOneWidget);
      expect(find.text('பூச்சி நாசினி'), findsOneWidget);
    });

    testWidgets('search filters results', (tester) async {
      await tester.runAsync(() => _seedUserAndQueries(
            db,
            texts: ['நெல் பயிர்', 'மண் வளம்'],
          ));
      await tester.pumpWidget(_app(db: db));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'நெல்');
      // Advance the fake clock past the 300 ms debounce.
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);

      expect(find.text('நெல் பயிர்'), findsOneWidget);
      expect(find.text('மண் வளம்'), findsNothing);
    });

    testWidgets('long-press opens delete dialog and confirm deletes',
        (tester) async {
      await tester.runAsync(
          () => _seedUserAndQueries(db, texts: ['நெல் பயிர்']));
      await tester.pumpWidget(_app(db: db));
      await _settle(tester);

      await tester.longPress(find.text('நெல் பயிர்'));
      await _settle(tester);

      expect(find.text(TamilStrings.deleteConfirmTitle), findsOneWidget);

      await tester.tap(find.text(TamilStrings.delete));
      await _settle(tester);

      expect(find.text('நெல் பயிர்'), findsNothing);
      expect(find.text(TamilStrings.historyEmpty), findsOneWidget);
    });
  });
}
