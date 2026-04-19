import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/screens/response/response_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

GoRouter _router(String queryId, List<String> visited) => GoRouter(
      initialLocation: '/response/$queryId',
      routes: [
        GoRoute(
          path: '/response/:queryId',
          builder: (_, state) =>
              ResponseScreen(queryId: state.pathParameters['queryId']!),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) {
            visited.add('/');
            return const Scaffold(body: Text('HOME_SCREEN'));
          },
        ),
      ],
    );

Widget _app({required DatabaseService db, required GoRouter router}) {
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

Future<String> _seedQuery(
  DatabaseService db, {
  String? gemmaResponse,
  String? userRating,
}) async {
  final userId = const Uuid().v4();
  final now = DateTime.now();
  await db.userProfileDao.insert(UserProfile(
    id: userId,
    phoneNumber: 'local_user_default',
    createdAt: now,
    updatedAt: now,
  ));
  final id = const Uuid().v4();
  await db.queryHistoryDao.insert(QueryHistory(
    id: id,
    userId: userId,
    timestamp: now,
    transcription: 'நெல் நோய் என்ன?',
    transcriptionConfidence: 1.0,
    gemmaResponse: gemmaResponse,
    userRating: userRating,
    createdAt: now,
    updatedAt: now,
  ));
  return id;
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

  group('ResponseScreen', () {
    testWidgets('renders transcription and placeholder when response is null',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, router: _router(id!, [])));
      await _settle(tester);

      expect(find.text('நெல் நோய் என்ன?'), findsOneWidget);
      expect(find.text(TamilStrings.responsePlaceholder), findsOneWidget);
      expect(find.text(TamilStrings.audioComingSoon), findsOneWidget);
    });

    testWidgets('renders gemma response when present', (tester) async {
      final id = await tester.runAsync(
        () => _seedQuery(db, gemmaResponse: 'செப்பு சல்பேட் தெளிக்கவும்'),
      );
      await tester.pumpWidget(_app(db: db, router: _router(id!, [])));
      await _settle(tester);

      expect(find.text('செப்பு சல்பேட் தெளிக்கவும்'), findsOneWidget);
      expect(find.text(TamilStrings.responsePlaceholder), findsNothing);
    });

    testWidgets('audio play/pause icons are disabled', (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, router: _router(id!, [])));
      await _settle(tester);

      final playButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.play_arrow),
          matching: find.byType(IconButton),
        ),
      );
      expect(playButton.onPressed, isNull);
    });

    testWidgets('tapping helpful sets userRating to thumbs_up',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, router: _router(id!, [])));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.helpful));
      await _settle(tester);

      final saved = await tester.runAsync(() => db.queryHistoryDao.getById(id));
      expect(saved!.userRating, equals('thumbs_up'));
    });

    testWidgets('tapping the same rating again clears it to null',
        (tester) async {
      final id = await tester.runAsync(
        () => _seedQuery(db, userRating: 'thumbs_up'),
      );
      await tester.pumpWidget(_app(db: db, router: _router(id!, [])));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.helpful));
      await _settle(tester);

      final saved = await tester.runAsync(() => db.queryHistoryDao.getById(id));
      expect(saved!.userRating, isNull);
    });

    testWidgets('home button navigates to /', (tester) async {
      final visited = <String>[];
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, router: _router(id!, visited)));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.goHome));
      await _settle(tester);

      expect(visited, contains('/'));
    });

    testWidgets('shows not-found message for unknown query id', (tester) async {
      await tester.pumpWidget(_app(db: db, router: _router('does-not-exist', [])));
      await _settle(tester);

      expect(find.text(TamilStrings.queryNotFound), findsOneWidget);
    });
  });
}
