import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/providers/llm_providers.dart';
import 'package:nilam_ai/services/llm/gemma_generator.dart';
import 'package:nilam_ai/services/llm/model_loader.dart';

class _FakeGenerator implements GemmaGenerator {
  _FakeGenerator({this.text = 'தமிழ் பதில்.'});

  final String text;

  @override
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    return text;
  }
}

class _FakeLoader implements ModelLoader {
  _FakeLoader({this.shouldThrow = false});

  final bool shouldThrow;

  @override
  Future<String> ensureModelAvailable() async {
    if (shouldThrow) throw LlmException.modelNotLoaded();
    return '/fake/model.path';
  }
}

void main() {
  group('GemmaNotifier state transitions', () {
    late ProviderContainer container;

    tearDown(() => container.dispose());

    test('initial state is GemmaIdle', () {
      container = ProviderContainer();
      expect(container.read(gemmaNotifierProvider), isA<GemmaIdle>());
    });

    test('happy path: LoadingModel → Generating → Complete', () async {
      container = ProviderContainer(
        overrides: [
          gemmaModelLoaderProvider.overrideWithValue(_FakeLoader()),
          gemmaGeneratorProvider.overrideWithValue(
            _FakeGenerator(text: 'சுத்தமான பதில்.'),
          ),
          connectivityCheckProvider.overrideWithValue(null),
        ],
      );

      final states = <GemmaState>[];
      container.listen<GemmaState>(
        gemmaNotifierProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await container
          .read(gemmaNotifierProvider.notifier)
          .generate(query: 'q', cropType: 'நெல்');

      expect(states.first, isA<GemmaIdle>());
      expect(states.any((s) => s is GemmaLoadingModel), isTrue);
      expect(states.any((s) => s is GemmaGenerating), isTrue);
      expect(states.last, isA<GemmaComplete>());

      final complete = states.last as GemmaComplete;
      expect(complete.response.text, equals('சுத்தமான பதில்.'));
      expect(complete.response.prompt, contains('கேள்வி: q'));
      expect(complete.response.prompt, contains('பயிர்: நெல்'));
    });

    test('model-load failure surfaces GemmaError with E009', () async {
      container = ProviderContainer(
        overrides: [
          gemmaModelLoaderProvider
              .overrideWithValue(_FakeLoader(shouldThrow: true)),
          gemmaGeneratorProvider.overrideWithValue(_FakeGenerator()),
          connectivityCheckProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(gemmaNotifierProvider.notifier)
          .generate(query: 'q');

      final state = container.read(gemmaNotifierProvider);
      expect(state, isA<GemmaError>());
      expect((state as GemmaError).code, equals('E009'));
    });

    test('empty query surfaces GemmaError with E012', () async {
      container = ProviderContainer(
        overrides: [
          gemmaModelLoaderProvider.overrideWithValue(_FakeLoader()),
          gemmaGeneratorProvider.overrideWithValue(_FakeGenerator()),
          connectivityCheckProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(gemmaNotifierProvider.notifier)
          .generate(query: '');

      final state = container.read(gemmaNotifierProvider);
      expect(state, isA<GemmaError>());
      expect((state as GemmaError).code, equals('E012'));
    });

    test('reset returns state to GemmaIdle', () async {
      container = ProviderContainer(
        overrides: [
          gemmaModelLoaderProvider.overrideWithValue(_FakeLoader()),
          gemmaGeneratorProvider.overrideWithValue(_FakeGenerator()),
          connectivityCheckProvider.overrideWithValue(null),
        ],
      );

      await container
          .read(gemmaNotifierProvider.notifier)
          .generate(query: 'q');
      expect(container.read(gemmaNotifierProvider), isA<GemmaComplete>());

      container.read(gemmaNotifierProvider.notifier).reset();
      expect(container.read(gemmaNotifierProvider), isA<GemmaIdle>());
    });

    test('exhaustive sealed switch compiles for every state', () {
      String label(GemmaState s) => switch (s) {
            GemmaIdle() => 'idle',
            GemmaLoadingModel() => 'loading',
            GemmaGenerating() => 'generating',
            GemmaComplete() => 'complete',
            GemmaError() => 'error',
          };

      expect(label(const GemmaIdle()), 'idle');
      expect(label(const GemmaLoadingModel()), 'loading');
      expect(label(const GemmaGenerating()), 'generating');
      expect(
        label(const GemmaError(code: 'E003', message: 'm')),
        'error',
      );
    });
  });
}
