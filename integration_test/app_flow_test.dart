import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/config/routes.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/main.dart';
import 'package:nilam_ai/providers/audio_providers.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/llm_providers.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:nilam_ai/providers/stt_providers.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/llm/gemma_generator.dart';
import 'package:nilam_ai/services/llm/gemma_service.dart' show ConnectivityCheck;
import 'package:nilam_ai/services/llm/noop_model_loader.dart';
import 'package:nilam_ai/services/stt/whisper_model_loader.dart';
import 'package:nilam_ai/services/stt/whisper_stt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// End-to-end flow exercising the real `NilamAIApp` + `appRouter` through
// Home → Record → Transcribe → Review → Response, with every
// platform-touching or network-touching dependency stubbed via Riverpod
// overrides. Runs on the host VM; device runs are tracked separately in #18.

Future<void> _settle(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Alternates real-time advancement (via `runAsync`) with microtask draining
/// (via `pump`). Needed whenever a handler chain awaits real sqflite I/O,
/// file operations, or the fake generator/transcriber.
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
  late Directory tmp;
  late File cannedAudio;

  setUp(() async {
    // `appRouter` is a top-level singleton; its current location persists
    // across tests in this file. Reset to Home before every test so each
    // testWidgets sees a cold-start.
    appRouter.go('/');
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues(const {});
    prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('app_flow_test_');
    // A real (but tiny) WAV — the review screen's retake path calls
    // File.delete on this, and STT's validateAudioFile requires >= 1024 bytes
    // with a .wav extension.
    cannedAudio = File('${tmp.path}/rec.wav');
    await cannedAudio.writeAsBytes(List<int>.filled(4096, 0));
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {
        // Windows occasionally holds file handles briefly; ignore.
      }
    }
  });

  List<Override> baseOverrides({ConnectivityCheck? connectivity}) {
    return [
      databaseServiceProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      whisperModelLoaderProvider.overrideWithValue(_FakeWhisperLoader()),
      whisperTranscriberProvider.overrideWithValue(
        _FakeTranscriber(text: 'நெல் நோய்'),
      ),
      gemmaModelLoaderProvider.overrideWithValue(NoopModelLoader()),
      gemmaGeneratorProvider.overrideWithValue(
        _FakeGenerator(text: 'நெல் பயிரில் பூச்சி கொல்லி தெளிக்கவும்.'),
      ),
      connectivityCheckProvider.overrideWithValue(connectivity),
      recordingNotifierProvider.overrideWith(
        () => _FakeRecordingNotifier(audioPath: cannedAudio.path),
      ),
    ];
  }

  testWidgets('happy path: cold start → ask → record → review → respond',
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

    // Tap CTA → Record screen
    await tester.tap(find.text(TamilStrings.askQuestionCta));
    await _settle(tester);
    expect(find.text(TamilStrings.recordingTitle), findsOneWidget);
    // tapToRecord is rendered twice on idle Record screen (status row + mic
    // FAB caption). Both point at the same RecordingIdle state.
    expect(find.text(TamilStrings.tapToRecord), findsNWidgets(2));

    // Tap mic FAB → fake startRecording → RecordingActive
    await tester.tap(find.byIcon(Icons.mic));
    await _settle(tester);
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Tap stop → fake stopRecording → RecordingComplete (with canned audio path)
    await tester.tap(find.byIcon(Icons.stop));
    await _settle(tester);
    expect(find.text(TamilStrings.recordingComplete), findsOneWidget);

    // Tap the transcribe button (reuses sttTranscribing as its label)
    await tester.tap(find.text(TamilStrings.sttTranscribing));
    // STT runs: LoadingModel → Transcribing → Complete → auto-nav to /review
    await _drainAsync(tester);

    // Review screen
    expect(find.text(TamilStrings.reviewInstructions), findsOneWidget);
    expect(find.text('நெல் நோய்'), findsOneWidget);

    // Confirm → persists QueryHistory, fires gemma.generate, nav to /response
    await tester.tap(find.text(TamilStrings.confirm));
    // Extra cycles: Response screen must mount, drain the ~80ms generator
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
    expect(rows.first.audioFilePath, equals(cannedAudio.path));
    expect(rows.first.gemmaResponse, contains('நெல் பயிரில்'));

    // Returning to Home via the goHome button works, but the recent-list
    // widget would show stale-empty because recentQueriesProvider is a
    // non-autoDispose family and nobody invalidates it after insert. The
    // DB-level assertion above is the source of truth; UI refresh is a
    // separate concern tracked outside this test.
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

    await tester.tap(find.byIcon(Icons.mic));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.stop));
    await _settle(tester);

    await tester.tap(find.text(TamilStrings.sttTranscribing));
    await _drainAsync(tester);

    expect(find.text('நெல் நோய்'), findsOneWidget);
    await tester.tap(find.text(TamilStrings.confirm));
    // Same rationale as the happy-path: the ~80ms connectivity delay must
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

/// Short-circuits the recording state machine so the UI transitions through
/// Idle → Active → Complete without touching `package:record` platform
/// channels. The complete state carries a pre-written canned WAV path so
/// downstream screens (Transcribing, Review) see a real file on disk.
class _FakeRecordingNotifier extends RecordingNotifier {
  _FakeRecordingNotifier({required this.audioPath});

  final String audioPath;

  @override
  RecordingState build() => const RecordingIdle();

  @override
  Future<void> startRecording() async {
    state = const RecordingActive(elapsed: Duration.zero, amplitudes: []);
  }

  @override
  Future<void> stopRecording() async {
    state = RecordingComplete(
      filePath: audioPath,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Future<void> cancelRecording() async {
    state = const RecordingIdle();
  }
}

/// Subclasses the concrete loader and overrides its single async entry point
/// so it never touches the app documents directory or the 82 MB whisper asset.
/// The returned path is fed to [_FakeTranscriber.transcribe], which ignores
/// it.
class _FakeWhisperLoader extends WhisperModelLoader {
  @override
  Future<String> ensureModelAvailable() async => '/fake/whisper.bin';
}

class _FakeTranscriber implements WhisperTranscriber {
  _FakeTranscriber({required this.text});

  final String text;

  @override
  Future<String> transcribe({
    required String modelPath,
    required String audioPath,
    required String language,
  }) async {
    return text;
  }
}

class _FakeGenerator implements GemmaGenerator {
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
