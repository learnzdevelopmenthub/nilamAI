import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilam_ai/config/theme.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/audio_providers.dart';
import 'package:nilam_ai/screens/recording/recording_screen.dart';

/// A fake notifier that exposes a fixed state.
class FakeRecordingNotifier extends RecordingNotifier {
  FakeRecordingNotifier(this._initialState);

  final RecordingState _initialState;

  @override
  RecordingState build() => _initialState;

  @override
  Future<void> startRecording() async {}

  @override
  Future<void> stopRecording() async {}

  @override
  Future<void> cancelRecording() async {}
}

Widget _buildTestApp(RecordingState initialState) {
  return ProviderScope(
    overrides: [
      recordingNotifierProvider.overrideWith(
        () => FakeRecordingNotifier(initialState),
      ),
    ],
    child: MaterialApp(
      theme: NilamTheme.lightTheme,
      home: const RecordingScreen(),
    ),
  );
}

void main() {
  group('RecordingScreen', () {
    testWidgets('shows record button and hint text in idle state',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const RecordingIdle()));
      await tester.pumpAndSettle();

      expect(find.text(TamilStrings.tapToRecord), findsWidgets);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('shows app bar with recording title', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RecordingIdle()));
      await tester.pumpAndSettle();

      expect(find.text(TamilStrings.recordingTitle), findsOneWidget);
    });

    testWidgets('shows stop and cancel buttons in active state',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const RecordingActive(
          elapsed: Duration(seconds: 5),
          amplitudes: [0.1, 0.5, 0.8],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text(TamilStrings.cancel), findsOneWidget);
      expect(find.text(TamilStrings.recordingActive), findsOneWidget);
    });

    testWidgets('shows timer in active state', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const RecordingActive(
          elapsed: Duration(seconds: 45),
          amplitudes: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('0:45 / 2:00'), findsOneWidget);
    });

    testWidgets('shows complete state with record button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const RecordingComplete(
          filePath: '/test/audio.wav',
          duration: Duration(seconds: 30),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(TamilStrings.recordingComplete), findsOneWidget);
      expect(find.text(TamilStrings.record), findsOneWidget);
    });

    testWidgets('shows quality warning when present', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const RecordingComplete(
          filePath: '/test/audio.wav',
          duration: Duration(seconds: 30),
          qualityWarning: TamilStrings.warningTooQuiet,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(TamilStrings.warningTooQuiet), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('does not show quality warning when null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const RecordingComplete(
          filePath: '/test/audio.wav',
          duration: Duration(seconds: 30),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsNothing);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const RecordingError(message: TamilStrings.errorMicrophone),
      ));
      await tester.pumpAndSettle();

      expect(find.text(TamilStrings.errorMicrophone), findsWidgets);
      expect(find.text(TamilStrings.retry), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('timer shows 0:00 / 2:00 in idle state', (tester) async {
      await tester.pumpWidget(_buildTestApp(const RecordingIdle()));
      await tester.pumpAndSettle();

      expect(find.text('0:00 / 2:00'), findsOneWidget);
    });
  });
}
