import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/config/theme.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/llm_providers.dart';
import 'package:nilam_ai/services/llm/prompt_builder.dart';
import 'package:nilam_ai/screens/query/query_input_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

GoRouter _router({required List<String> visited}) {
  return GoRouter(
    initialLocation: '/ask',
    routes: [
      GoRoute(
        path: '/ask',
        builder: (context, state) => const QueryInputScreen(),
      ),
      GoRoute(
        path: '/response/:queryId',
        builder: (context, state) {
          visited.add('/response');
          return const Scaffold(body: Text('RESPONSE_SCREEN'));
        },
      ),
    ],
  );
}

Widget _app({
  required DatabaseService db,
  required GoRouter router,
  _FakeGemmaNotifier? gemma,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      gemmaNotifierProvider.overrideWith(() => gemma ?? _FakeGemmaNotifier()),
    ],
    child: MaterialApp.router(
      theme: NilamTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

class _FakeGemmaNotifier extends GemmaNotifier {
  int generateCalls = 0;
  String? lastQuery;
  String? lastCropType;

  @override
  GemmaState build() => const GemmaIdle();

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
}

Future<void> _pumpFrames(WidgetTester tester, [int frames = 3]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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

  group('QueryInputScreen', () {
    testWidgets('renders hint, app bar, and confirm button', (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited: visited)));
      await _pumpFrames(tester);

      expect(find.text(TamilStrings.askQuestion), findsOneWidget);
      expect(find.text(TamilStrings.queryInputHint), findsOneWidget);
      expect(find.text(TamilStrings.confirm), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('confirm button is disabled when text is empty',
        (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited: visited)));
      await _pumpFrames(tester);

      final button = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('confirm enables once text is typed', (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited: visited)));
      await _pumpFrames(tester);

      await tester.enterText(find.byType(TextField), 'நெல் நோய்');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('confirm persists QueryHistory with null audio + confidence',
        (tester) async {
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, router: _router(visited: visited)));
      await _pumpFrames(tester);

      await tester.enterText(find.byType(TextField), 'நெல் நோய்');
      await tester.pump();
      await tester.tap(find.text(TamilStrings.confirm));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await _pumpFrames(tester);

      final user = await tester.runAsync(() => db.userProfileDao.getCurrent());
      expect(user, isNotNull);
      final rows = await tester
          .runAsync(() => db.queryHistoryDao.getByUserId(user!.id));
      expect(rows, hasLength(1));
      expect(rows!.first.transcription, equals('நெல் நோய்'));
      expect(rows.first.audioFilePath, isNull);
      expect(rows.first.transcriptionConfidence, isNull);
    });

    testWidgets('confirm fires gemmaNotifier.generate and navigates',
        (tester) async {
      final visited = <String>[];
      final fake = _FakeGemmaNotifier();
      await tester.pumpWidget(
        _app(db: db, router: _router(visited: visited), gemma: fake),
      );
      await _pumpFrames(tester);

      await tester.enterText(find.byType(TextField), 'நெல் நோய்');
      await tester.pump();
      await tester.tap(find.text(TamilStrings.confirm));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
      }

      expect(fake.generateCalls, equals(1));
      expect(fake.lastQuery, equals('நெல் நோய்'));
      expect(fake.lastCropType, isNull);
      expect(visited, contains('/response'));
    });
  });
}
