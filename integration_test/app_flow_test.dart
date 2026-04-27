import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/config/routes.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/main.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/llm_providers.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/llm/gemma_generator.dart';
import 'package:nilam_ai/services/llm/gemma_service.dart' show ConnectivityCheck;
import 'package:nilam_ai/services/llm/noop_model_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// End-to-end flow exercising the real `NilamAIApp` + `appRouter` through
// Home → Ask (text input) → Response, with every network-touching dependency
// stubbed via Riverpod overrides. Runs on the host VM.

Future<void> _settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Alternates real-time advancement (via `runAsync`) with microtask draining
/// (via `pump`). Needed whenever a handler chain awaits real sqflite I/O or
/// the fake generator.
Future<void> _drainAsync(WidgetTester tester, [int cycles = 8]) async {
  for (var i = 0; i < cycles; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late SharedPreferences prefs;

  setUp(() async {
    // `appRouter` is a top-level singleton; its current location persists
    // across tests in this file. Reset to Home before every test so each
    // testWidgets sees a cold-start.
    appRouter.go('/');
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues(const {});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  List<Override> baseOverrides({ConnectivityCheck? connectivity}) {
    return [
      databaseServiceProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      gemmaModelLoaderProvider.overrideWithValue(NoopModelLoader()),
      gemmaGeneratorProvider.overrideWithValue(
        _FakeGenerator(text: 'நெல் பயிரில் பூச்சி கொல்லி தெளிக்கவும்.'),
      ),
      connectivityCheckProvider.overrideWithValue(connectivity),
    ];
  }

  testWidgets('happy path: cold start → ask → type → respond',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(),
        child: const NilamAIApp(),
      ),
    );
    // Let currentUserIdProvider bootstrap the default user, then Home's
    // recentQueriesProvider complete.
    await _drainAsync(tester);

    // Home
    expect(find.text(TamilStrings.appTagline), findsOneWidget);
    expect(find.text(TamilStrings.askQuestionCta), findsOneWidget);
    expect(find.text(TamilStrings.noRecentQuestions), findsOneWidget);

    // Tap CTA → Ask screen
    await tester.tap(find.text(TamilStrings.askQuestionCta));
    await _settle(tester);
    expect(find.text(TamilStrings.askQuestion), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Type Tamil question
    await tester.enterText(find.byType(TextField), 'நெல் நோய்');
    await _settle(tester);

    // Confirm → persists QueryHistory, fires gemma.generate, nav to /response
    await tester.tap(find.text(TamilStrings.confirm));
    // Extra cycles: Response screen must mount, drain the ~500ms generator
    // delay, catch GemmaComplete via ref.listen, _persistGemma writes to DB,
    // queryByIdProvider invalidates, then rebuild with hasStored=true.
    await _drainAsync(tester, 30);

    // Response screen — canned LLM text rendered once the listener persists
    // the response and invalidates queryByIdProvider.
    expect(find.textContaining('நெல் பயிரில்'), findsOneWidget);
    expect(find.text(TamilStrings.goHome), findsOneWidget);

    // DB sanity
    final user = await db.userProfileDao.getCurrent();
    expect(user, isNotNull);
    final rows = await db.queryHistoryDao.getByUserId(user!.id);
    expect(rows, hasLength(1));
    expect(rows.first.transcription, equals('நெல் நோய்'));
    expect(rows.first.audioFilePath, isNull);
    expect(rows.first.transcriptionConfidence, isNull);
    expect(rows.first.gemmaResponse, contains('நெல் பயிரில்'));
  });

  testWidgets('offline path: confirm with no connectivity shows E013 block',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(
          connectivity: () async {
            // Matching the generator's delay — see _FakeGenerator.
            await Future<void>.delayed(const Duration(milliseconds: 500));
            return [ConnectivityResult.none];
          },
        ),
        child: const NilamAIApp(),
      ),
    );
    await _drainAsync(tester);
    await _settle(tester);

    // Sanity: Home loaded.
    expect(find.text(TamilStrings.askQuestionCta), findsOneWidget);

    // Walk the same path up to Confirm.
    await tester.tap(find.text(TamilStrings.askQuestionCta));
    await _settle(tester);

    await tester.enterText(find.byType(TextField), 'நெல் நோய்');
    await _settle(tester);

    await tester.tap(find.text(TamilStrings.confirm));
    // Same rationale as the happy-path: the ~500ms connectivity delay must
    // elapse after Response mounts so the Error state replaces the reset.
    await _drainAsync(tester, 15);

    // GemmaService's pre-flight connectivity check throws networkOffline
    // before the HTTPS call, so GemmaNotifier surfaces GemmaError(E013) and
    // the _GemmaError card renders in the AI-response slot.
    expect(find.text(TamilStrings.gemmaError), findsOneWidget);
    expect(find.textContaining('E013'), findsOneWidget);
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _FakeGenerator extends GemmaGenerator {
  _FakeGenerator({required this.text});

  final String text;

  @override
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    // Real-time delay so the GemmaNotifier state transitions land *after*
    // ResponseScreen mounts — otherwise its initState reset-on-stale-
    // terminal-state wipes the Complete state before the screen's
    // ref.listen has a chance to persist + render it.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return text;
  }
}
