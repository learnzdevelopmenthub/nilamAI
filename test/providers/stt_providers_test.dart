import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/providers/stt_providers.dart';
import 'package:nilam_ai/services/stt/whisper_model_loader.dart';
import 'package:nilam_ai/services/stt/whisper_stt_service.dart';

class _FakeTranscriber implements WhisperTranscriber {
  _FakeTranscriber({this.text = 'நெல் பயிர்', this.error});

  final String text;
  final Object? error;

  @override
  Future<String> transcribe({
    required String modelPath,
    required String audioPath,
    required String language,
  }) async {
    if (error != null) throw error!;
    return text;
  }
}

class _FakeLoader extends WhisperModelLoader {
  _FakeLoader({required this.modelPath, this.shouldThrow = false})
      : super(appDirProvider: () async => Directory.systemTemp);

  final String modelPath;
  final bool shouldThrow;

  @override
  Future<String> ensureModelAvailable() async {
    if (shouldThrow) throw SttException.modelNotLoaded();
    return modelPath;
  }
}

Future<File> _makeWavFile() async {
  final dir = await Directory.systemTemp.createTemp('stt_provider_test_');
  final file = File('${dir.path}/sample.wav')
    ..writeAsBytesSync(List<int>.filled(8192, 0));
  return file;
}

void main() {
  group('SttNotifier state transitions', () {
    late ProviderContainer container;
    late File wav;

    setUp(() async {
      wav = await _makeWavFile();
    });

    tearDown(() async {
      container.dispose();
      final parent = wav.parent;
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    });

    test('initial state is SttIdle', () {
      container = ProviderContainer();
      expect(container.read(sttNotifierProvider), isA<SttIdle>());
    });

    test(
        'happy path transitions LoadingModel → Transcribing → Complete',
        () async {
      final fakeLoader = _FakeLoader(modelPath: '/fake/model.bin');
      final fakeTranscriber = _FakeTranscriber(text: 'நெல் நோய்');

      container = ProviderContainer(
        overrides: [
          whisperModelLoaderProvider.overrideWithValue(fakeLoader),
          whisperTranscriberProvider.overrideWithValue(fakeTranscriber),
        ],
      );

      final states = <SttState>[];
      container.listen<SttState>(
        sttNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await container.read(sttNotifierProvider.notifier).transcribe(wav.path);

      expect(states.first, isA<SttIdle>());
      expect(states.any((s) => s is SttLoadingModel), isTrue);
      expect(states.any((s) => s is SttTranscribing), isTrue);
      expect(states.last, isA<SttComplete>());

      final complete = states.last as SttComplete;
      expect(complete.text, equals('நெல் நோய்'));
      expect(complete.audioPath, equals(wav.path));
    });

    test('model-load failure surfaces SttError with E006', () async {
      final fakeLoader = _FakeLoader(
        modelPath: '/unused',
        shouldThrow: true,
      );
      final fakeTranscriber = _FakeTranscriber();

      container = ProviderContainer(
        overrides: [
          whisperModelLoaderProvider.overrideWithValue(fakeLoader),
          whisperTranscriberProvider.overrideWithValue(fakeTranscriber),
        ],
      );

      await container.read(sttNotifierProvider.notifier).transcribe(wav.path);

      final state = container.read(sttNotifierProvider);
      expect(state, isA<SttError>());
      expect((state as SttError).code, equals('E006'));
    });

    test('transcription failure surfaces SttError with E007', () async {
      final fakeLoader = _FakeLoader(modelPath: '/fake/model.bin');
      final fakeTranscriber = _FakeTranscriber(
        error: Exception('native crash'),
      );

      container = ProviderContainer(
        overrides: [
          whisperModelLoaderProvider.overrideWithValue(fakeLoader),
          whisperTranscriberProvider.overrideWithValue(fakeTranscriber),
        ],
      );

      await container.read(sttNotifierProvider.notifier).transcribe(wav.path);

      final state = container.read(sttNotifierProvider);
      expect(state, isA<SttError>());
      expect((state as SttError).code, equals('E007'));
    });

    test('reset returns state to SttIdle', () async {
      final fakeLoader = _FakeLoader(modelPath: '/fake/model.bin');
      final fakeTranscriber = _FakeTranscriber();

      container = ProviderContainer(
        overrides: [
          whisperModelLoaderProvider.overrideWithValue(fakeLoader),
          whisperTranscriberProvider.overrideWithValue(fakeTranscriber),
        ],
      );

      await container.read(sttNotifierProvider.notifier).transcribe(wav.path);
      expect(container.read(sttNotifierProvider), isA<SttComplete>());

      container.read(sttNotifierProvider.notifier).reset();
      expect(container.read(sttNotifierProvider), isA<SttIdle>());
    });

    test('exhaustive sealed switch compiles for every state', () {
      String label(SttState s) => switch (s) {
            SttIdle() => 'idle',
            SttLoadingModel() => 'loading',
            SttTranscribing() => 'transcribing',
            SttComplete() => 'complete',
            SttError() => 'error',
          };

      expect(label(const SttIdle()), 'idle');
      expect(label(const SttLoadingModel()), 'loading');
      expect(label(const SttTranscribing()), 'transcribing');
      expect(
        label(const SttComplete(text: 't', audioPath: 'a')),
        'complete',
      );
      expect(
        label(const SttError(code: 'E007', message: 'm')),
        'error',
      );
    });
  });
}
