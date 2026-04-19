import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/config/theme.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/stt_providers.dart';
import 'package:nilam_ai/screens/transcription/transcribing_screen.dart';

/// Fake notifier driven entirely by the test — does not call any real service.
///
/// Tests call [emit] to push the next state and pump the widget.
class _FakeSttNotifier extends SttNotifier {
  _FakeSttNotifier(this._initialState);

  final SttState _initialState;
  int transcribeCalls = 0;
  String? lastAudioPath;

  @override
  SttState build() => _initialState;

  @override
  Future<void> transcribe(String audioPath) async {
    transcribeCalls += 1;
    lastAudioPath = audioPath;
  }

  @override
  void reset() {
    state = const SttIdle();
  }

  void emit(SttState next) => state = next;
}

GoRouter _buildRouter({
  required SttState initialState,
  required String audioPath,
  List<String>? visitedLocations,
}) {
  return GoRouter(
    initialLocation: '/transcribe?audioPath=${Uri.encodeComponent(audioPath)}',
    routes: [
      GoRoute(
        path: '/transcribe',
        builder: (context, state) {
          final path = state.uri.queryParameters['audioPath'] ?? '';
          return TranscribingScreen(audioPath: path);
        },
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) {
          visitedLocations?.add(state.uri.toString());
          return const Scaffold(body: Text('REVIEW_SCREEN'));
        },
      ),
      GoRoute(
        path: '/record',
        builder: (context, state) {
          visitedLocations?.add(state.uri.toString());
          return const Scaffold(body: Text('RECORD_SCREEN'));
        },
      ),
    ],
  );
}

Widget _buildApp({
  required _FakeSttNotifier notifier,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      sttNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp.router(
      theme: NilamTheme.lightTheme,
      routerConfig: router,
    ),
  );
}

void main() {
  group('TranscribingScreen', () {
    testWidgets('calls transcribe() on the notifier after initState',
        (tester) async {
      final notifier = _FakeSttNotifier(const SttIdle());
      final router = _buildRouter(
        initialState: const SttIdle(),
        audioPath: '/tmp/test.wav',
      );
      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump(); // fire postFrameCallback (initState → _start)
      await tester.pump();

      expect(notifier.transcribeCalls, equals(1));
      expect(notifier.lastAudioPath, equals('/tmp/test.wav'));
    });

    testWidgets('shows Tamil loading text while SttLoadingModel',
        (tester) async {
      final notifier = _FakeSttNotifier(const SttLoadingModel());
      final router = _buildRouter(
        initialState: const SttLoadingModel(),
        audioPath: '/tmp/test.wav',
      );
      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump();

      expect(find.text(TamilStrings.sttModelLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Tamil transcribing text while SttTranscribing',
        (tester) async {
      final notifier = _FakeSttNotifier(const SttTranscribing());
      final router = _buildRouter(
        initialState: const SttTranscribing(),
        audioPath: '/tmp/test.wav',
      );
      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump();

      expect(find.text(TamilStrings.sttTranscribing), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigates to /review on SttComplete', (tester) async {
      final notifier = _FakeSttNotifier(const SttTranscribing());
      final visited = <String>[];
      final router = _buildRouter(
        initialState: const SttTranscribing(),
        audioPath: '/tmp/test.wav',
        visitedLocations: visited,
      );

      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump();
      await tester.pump();

      notifier.emit(
        const SttComplete(text: 'நெல் பயிர்', audioPath: '/tmp/test.wav'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('REVIEW_SCREEN'), findsOneWidget);
      expect(visited, isNotEmpty);
      expect(visited.first, contains('audioPath=%2Ftmp%2Ftest.wav'));
      expect(visited.first, contains('text=%E0%AE%A8'));
    });

    testWidgets('shows Tamil error + retry + retake buttons on SttError',
        (tester) async {
      final notifier = _FakeSttNotifier(
        const SttError(code: 'E006', message: 'model missing'),
      );
      final router = _buildRouter(
        initialState: const SttError(code: 'E006', message: 'model missing'),
        audioPath: '/tmp/test.wav',
      );
      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump();

      expect(find.text(TamilStrings.errorSttModelMissing), findsOneWidget);
      expect(find.text(TamilStrings.retry), findsOneWidget);
      expect(find.text(TamilStrings.retake), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('maps E007 to the transcription-failed message',
        (tester) async {
      final notifier = _FakeSttNotifier(
        const SttError(code: 'E007', message: 'native crash'),
      );
      final router = _buildRouter(
        initialState: const SttError(code: 'E007', message: 'native crash'),
        audioPath: '/tmp/test.wav',
      );
      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump();

      expect(find.text(TamilStrings.errorSttFailed), findsOneWidget);
    });

    testWidgets('retry button calls transcribe again', (tester) async {
      final notifier = _FakeSttNotifier(
        const SttError(code: 'E006', message: 'model missing'),
      );
      final router = _buildRouter(
        initialState: const SttError(code: 'E006', message: 'model missing'),
        audioPath: '/tmp/test.wav',
      );
      await tester.pumpWidget(_buildApp(notifier: notifier, router: router));
      await tester.pump();
      await tester.pump();

      final before = notifier.transcribeCalls;
      await tester.tap(find.text(TamilStrings.retry));
      await tester.pump();

      expect(notifier.transcribeCalls, equals(before + 1));
    });
  });
}
