import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/llm_providers.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:nilam_ai/screens/response/response_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:nilam_ai/services/llm/gemma_service.dart';
import 'package:nilam_ai/services/llm/prompt_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Widget _app({
  required DatabaseService db,
  required SharedPreferences prefs,
  required GoRouter router,
  _FakeGemmaNotifier? gemma,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (gemma != null) gemmaNotifierProvider.overrideWith(() => gemma),
    ],
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

/// Test double for [GemmaNotifier]: exposes the initial state, counts
/// [generate] calls, and lets the test [emit] subsequent states.
class _FakeGemmaNotifier extends GemmaNotifier {
  _FakeGemmaNotifier({this.initialState = const GemmaIdle()});

  final GemmaState initialState;
  int generateCalls = 0;
  String? lastQuery;
  String? lastCropType;

  @override
  GemmaState build() => initialState;

  @override
  Future<void> generate({
    required String query,
    String? cropType,
    CropContext? cropContext,
  }) async {
    generateCalls += 1;
    lastQuery = query;
    lastCropType = cropType;
  }

  void emit(GemmaState s) => state = s;
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

  group('ResponseScreen', () {
    testWidgets('renders transcription and placeholder when response is null',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router(id!, [])));
      await _settle(tester);

      expect(find.text('நெல் நோய் என்ன?'), findsOneWidget);
      expect(find.text(TamilStrings.responsePlaceholder), findsOneWidget);
      expect(find.text(TamilStrings.gemmaGenerateAnswer), findsOneWidget);
      // Audio play button is rendered but disabled until a stored response.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets(
        'tapping generate-answer on an Idle+null row invokes generate',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      final fake = _FakeGemmaNotifier();
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.gemmaGenerateAnswer));
      await _settle(tester);

      expect(fake.generateCalls, equals(1));
      expect(fake.lastQuery, equals('நெல் நோய் என்ன?'));
    });

    testWidgets('renders gemma response when present', (tester) async {
      final id = await tester.runAsync(
        () => _seedQuery(db, gemmaResponse: 'செப்பு சல்பேட் தெளிக்கவும்'),
      );
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router(id!, [])));
      await _settle(tester);

      expect(find.text('செப்பு சல்பேட் தெளிக்கவும்'), findsOneWidget);
      expect(find.text(TamilStrings.responsePlaceholder), findsNothing);
    });

    testWidgets('audio play/pause icons are disabled', (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router(id!, [])));
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
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router(id!, [])));
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
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router(id!, [])));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.helpful));
      await _settle(tester);

      final saved = await tester.runAsync(() => db.queryHistoryDao.getById(id));
      expect(saved!.userRating, isNull);
    });

    testWidgets('home button navigates to /', (tester) async {
      final visited = <String>[];
      final id = await tester.runAsync(() => _seedQuery(db));
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router(id!, visited)));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.goHome));
      await _settle(tester);

      expect(visited, contains('/'));
    });

    testWidgets('shows not-found message for unknown query id', (tester) async {
      await tester.pumpWidget(_app(db: db, prefs: prefs, router: _router('does-not-exist', [])));
      await _settle(tester);

      expect(find.text(TamilStrings.queryNotFound), findsOneWidget);
    });

    testWidgets('GemmaLoadingModel renders spinner and label', (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      final fake = _FakeGemmaNotifier(initialState: const GemmaLoadingModel());
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      await _settle(tester);

      expect(find.text(TamilStrings.gemmaLoadingModel), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(TamilStrings.responsePlaceholder), findsNothing);
    });

    testWidgets('GemmaGenerating renders the generating label', (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      final fake = _FakeGemmaNotifier(initialState: const GemmaGenerating());
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      await _settle(tester);

      expect(find.text(TamilStrings.gemmaGenerating), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'GemmaComplete persists response to DB, invalidates, and resets notifier',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      final fake = _FakeGemmaNotifier(initialState: const GemmaGenerating());
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      await _settle(tester);

      fake.emit(const GemmaComplete(
        response: GemmaResponse(
          text: 'தமிழ் பதில்',
          rawText: 'raw',
          prompt: 'prompt',
          latencyMs: 1234,
        ),
      ));
      await _settle(tester);

      final saved = await tester.runAsync(() => db.queryHistoryDao.getById(id));
      expect(saved!.gemmaResponse, equals('தமிழ் பதில்'));
      expect(saved.gemmaPrompt, equals('prompt'));
      expect(saved.gemmaLatencyMs, equals(1234));
      expect(find.text('தமிழ் பதில்'), findsOneWidget);
      // Persist path resets the notifier back to Idle.
      expect(fake.state, isA<GemmaIdle>());
    });

    testWidgets(
        'GemmaError shows friendly message + code; Retry invokes generate',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      // Start in Generating so the screen's stale-terminal-state guard in
      // initState leaves the notifier alone; then emit Error to simulate a
      // live failure arriving while the screen is mounted.
      final fake = _FakeGemmaNotifier(initialState: const GemmaGenerating());
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      await _settle(tester);

      fake.emit(const GemmaError(code: 'E010', message: 'timeout'));
      await _settle(tester);

      expect(find.text(TamilStrings.gemmaError), findsOneWidget);
      expect(find.textContaining('[E010]'), findsOneWidget);

      await tester.tap(find.text(TamilStrings.retry));
      await _settle(tester);

      expect(fake.generateCalls, equals(1));
      expect(fake.lastQuery, equals('நெல் நோய் என்ன?'));
    });

    testWidgets('stored response takes precedence over stale notifier state',
        (tester) async {
      final id = await tester.runAsync(
        () => _seedQuery(db, gemmaResponse: 'stored answer'),
      );
      final fake = _FakeGemmaNotifier(
        initialState: const GemmaComplete(
          response: GemmaResponse(
            text: 'stale',
            rawText: 'r',
            prompt: 'p',
            latencyMs: 0,
          ),
        ),
      );
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      await _settle(tester);

      expect(find.text('stored answer'), findsOneWidget);
      expect(find.text('stale'), findsNothing);
    });

    testWidgets(
        'opening screen resets notifier if in stale terminal state and response null',
        (tester) async {
      final id = await tester.runAsync(() => _seedQuery(db));
      final fake = _FakeGemmaNotifier(
        initialState: const GemmaError(code: 'E010', message: 'prior failure'),
      );
      await tester.pumpWidget(
        _app(db: db, prefs: prefs, router: _router(id!, []), gemma: fake),
      );
      // Error state renders first; post-frame reset then swaps to Idle.
      await _settle(tester);

      expect(fake.state, isA<GemmaIdle>());
      expect(find.text(TamilStrings.responsePlaceholder), findsOneWidget);
    });
  });
}
