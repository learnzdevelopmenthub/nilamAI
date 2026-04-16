import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilam_ai/providers/audio_providers.dart';

void main() {
  group('RecordingState', () {
    test('RecordingIdle is the initial state', () {
      const state = RecordingIdle();
      expect(state, isA<RecordingState>());
      expect(state, isA<RecordingIdle>());
    });

    test('RecordingActive carries elapsed and amplitudes', () {
      const state = RecordingActive(
        elapsed: Duration(seconds: 5),
        amplitudes: [0.1, 0.5, 0.8],
      );
      expect(state.elapsed, equals(const Duration(seconds: 5)));
      expect(state.amplitudes.length, equals(3));
    });

    test('RecordingComplete carries filePath and duration', () {
      const state = RecordingComplete(
        filePath: '/audio/test.wav',
        duration: Duration(seconds: 30),
      );
      expect(state.filePath, equals('/audio/test.wav'));
      expect(state.duration, equals(const Duration(seconds: 30)));
      expect(state.qualityWarning, isNull);
    });

    test('RecordingComplete carries optional quality warning', () {
      const state = RecordingComplete(
        filePath: '/audio/test.wav',
        duration: Duration(seconds: 30),
        qualityWarning: 'too quiet',
      );
      expect(state.qualityWarning, equals('too quiet'));
    });

    test('RecordingError carries message', () {
      const state = RecordingError(message: 'Mic denied');
      expect(state.message, equals('Mic denied'));
    });

    test('exhaustive switch covers all states', () {
      final states = <RecordingState>[
        const RecordingIdle(),
        const RecordingActive(elapsed: Duration.zero, amplitudes: []),
        const RecordingComplete(
          filePath: '/test.wav',
          duration: Duration.zero,
        ),
        const RecordingError(message: 'error'),
      ];

      for (final state in states) {
        final label = switch (state) {
          RecordingIdle() => 'idle',
          RecordingActive() => 'active',
          RecordingComplete() => 'complete',
          RecordingError() => 'error',
        };
        expect(label, isNotEmpty);
      }
    });
  });

  group('recordingNotifierProvider', () {
    test('initial state is RecordingIdle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(recordingNotifierProvider);
      expect(state, isA<RecordingIdle>());
    });

    test('reset returns to RecordingIdle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(recordingNotifierProvider.notifier).reset();
      final state = container.read(recordingNotifierProvider);
      expect(state, isA<RecordingIdle>());
    });
  });
}
