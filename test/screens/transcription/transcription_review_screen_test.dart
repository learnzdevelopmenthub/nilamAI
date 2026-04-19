import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/config/theme.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/screens/transcription/transcription_review_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/stt/stt_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Using GoRouter here (not a plain Navigator) because the screen calls
// `context.go(...)` which is an extension defined on [BuildContext] by the
// go_router package and requires a `GoRouter` to be present in the widget
// tree.
GoRouter _router({
  required String audioPath,
  required String initialText,
  required List<String> visited,
}) {
  return GoRouter(
    initialLocation: '/review?audioPath=${Uri.encodeComponent(audioPath)}'
        '&text=${Uri.encodeComponent(initialText)}',
    routes: [
      GoRoute(
        path: '/review',
        builder: (context, state) => TranscriptionReviewScreen(
          audioPath: state.uri.queryParameters['audioPath'] ?? '',
          initialText: state.uri.queryParameters['text'] ?? '',
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          visited.add('/');
          return const Scaffold(body: Text('HOME_SCREEN'));
        },
      ),
      GoRoute(
        path: '/record',
        builder: (context, state) {
          visited.add('/record');
          return const Scaffold(body: Text('RECORD_SCREEN'));
        },
      ),
    ],
  );
}

Widget _app({
  required DatabaseService db,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
    ],
    child: MaterialApp.router(
      theme: NilamTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

/// `pumpAndSettle` hangs because of the blinking [TextField] cursor. Pump a
/// bounded number of frames instead.
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
  late Directory tmp;
  late File audio;

  setUp(() async {
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
    tmp = await Directory.systemTemp.createTemp('review_screen_test_');
    audio = File('${tmp.path}/recording.wav');
    await audio.writeAsBytes(List<int>.filled(4096, 0));
  });

  tearDown(() async {
    await db.close();
    try {
      if (await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    } catch (_) {
      // Windows occasionally holds file handles briefly; ignore.
    }
  });

  group('TranscriptionReviewScreen', () {
    testWidgets('renders initial text and Tamil UI chrome', (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: 'நெல் பயிர்',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
      await _pumpFrames(tester);

      expect(find.text(TamilStrings.reviewTitle), findsOneWidget);
      expect(find.text(TamilStrings.reviewInstructions), findsOneWidget);
      expect(find.text('நெல் பயிர்'), findsOneWidget);
      expect(find.text(TamilStrings.confirm), findsOneWidget);
      expect(find.text(TamilStrings.retake), findsOneWidget);
    });

    testWidgets('confirm button is disabled when text is empty',
        (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: '',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
      await _pumpFrames(tester);

      final confirmButton = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('confirm button is enabled when text is non-empty',
        (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: 'நெல் பயிர்',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
      await _pumpFrames(tester);

      final confirmButton = tester.widget<ElevatedButton>(
        find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(confirmButton.onPressed, isNotNull);
    });

    testWidgets(
        'confirm with unedited text persists QueryHistory with confidence=1.0',
        (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: 'நெல் பயிர்',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
      await _pumpFrames(tester);

      await tester.tap(find.text(TamilStrings.confirm));
      // Let the async DB writes complete.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await _pumpFrames(tester);

      final user = await tester.runAsync(() => db.userProfileDao.getCurrent());
      expect(user, isNotNull);
      final rows = await tester
          .runAsync(() => db.queryHistoryDao.getByUserId(user!.id));
      expect(rows, hasLength(1));
      expect(rows!.first.transcription, equals('நெல் பயிர்'));
      expect(
        rows.first.transcriptionConfidence,
        equals(SttConstants.confidenceUnedited),
      );
      expect(rows.first.audioFilePath, equals(audio.path));
    });

    testWidgets(
        'confirm with edited text persists QueryHistory with confidence=0.5',
        (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: 'நெல் பயிர்',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
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
      expect(
        rows.first.transcriptionConfidence,
        equals(SttConstants.confidenceEdited),
      );
    });

    testWidgets('confirm bootstraps a default user when none exists',
        (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: 'நெல் பயிர்',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
      await _pumpFrames(tester);

      expect(
        await tester.runAsync(() => db.userProfileDao.getCurrent()),
        isNull,
      );

      await tester.tap(find.text(TamilStrings.confirm));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await _pumpFrames(tester);

      final user = await tester.runAsync(() => db.userProfileDao.getCurrent());
      expect(user, isNotNull);
      expect(user!.phoneNumber, equals('local_user_default'));
    });

    testWidgets('retake deletes the audio file and navigates to /record',
        (tester) async {
      final visited = <String>[];
      final router = _router(
        audioPath: audio.path,
        initialText: 'நெல் பயிர்',
        visited: visited,
      );
      await tester.pumpWidget(_app(db: db, router: router));
      await _pumpFrames(tester);
      expect(await tester.runAsync(() => audio.exists()), isTrue);

      await tester.tap(find.text(TamilStrings.retake));
      // `_retake` awaits real file I/O before calling `context.go`. Alternate
      // `runAsync` (real time for I/O) with `pump` (drain microtasks so the
      // handler's continuation can run, and GoRouter can rebuild). Several
      // cycles are needed because each `await` inside `_retake` pauses the
      // handler until the next microtask drain.
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
      }

      expect(await tester.runAsync(() => audio.exists()), isFalse);
      expect(visited, contains('/record'));
      expect(find.text('RECORD_SCREEN'), findsOneWidget);
    });
  });
}
