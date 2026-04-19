import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/llm/gemma_generator.dart';
import 'package:nilam_ai/services/llm/gemma_service.dart';
import 'package:nilam_ai/services/llm/llm_constants.dart';
import 'package:nilam_ai/services/llm/model_loader.dart';

class _FakeGenerator implements GemmaGenerator {
  _FakeGenerator({
    this.text = 'தமிழ் பதில்.',
    this.error,
    this.delay = Duration.zero,
  });

  final String text;
  final Object? error;
  final Duration delay;

  String? lastPrompt;
  int? lastMaxTokens;
  double? lastTemperature;
  String? lastModelPath;
  int callCount = 0;

  @override
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    callCount += 1;
    lastModelPath = modelPath;
    lastPrompt = prompt;
    lastMaxTokens = maxTokens;
    lastTemperature = temperature;
    if (delay != Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (error != null) {
      throw error!;
    }
    return text;
  }
}

class _FakeLoader implements ModelLoader {
  _FakeLoader({this.path = '/fake/model.path', this.error});

  final String path;
  final Object? error;
  int calls = 0;

  @override
  Future<String> ensureModelAvailable() async {
    calls += 1;
    if (error != null) {
      throw error!;
    }
    return path;
  }
}

void main() {
  group('GemmaService.generate — happy path', () {
    test('returns post-processed text, raw text, prompt, and latency', () async {
      final gen = _FakeGenerator(text: '**5 kg** விதை போடு.');
      final svc = GemmaService(loader: _FakeLoader(), generator: gen);

      final result = await svc.generate(query: 'query', cropType: 'நெல்');

      expect(result.rawText, equals('**5 kg** விதை போடு.'));
      // Post-processor strips bold and expands kg.
      expect(result.text, equals('5 கிலோ விதை போடு.'));
      expect(result.prompt, contains('கேள்வி: query'));
      expect(result.prompt, contains('பயிர்: நெல்'));
      expect(result.latencyMs, greaterThanOrEqualTo(0));
    });

    test('uses LlmConstants for maxTokens and temperature', () async {
      final gen = _FakeGenerator();
      final svc = GemmaService(loader: _FakeLoader(), generator: gen);

      await svc.generate(query: 'q');

      expect(gen.lastMaxTokens, equals(LlmConstants.maxOutputTokens));
      expect(gen.lastTemperature, equals(LlmConstants.temperature));
    });

    test('passes the resolved model path from the loader to the generator',
        () async {
      final gen = _FakeGenerator();
      final loader = _FakeLoader(path: '/tmp/gemma.litertlm');
      final svc = GemmaService(loader: loader, generator: gen);

      await svc.generate(query: 'q');

      expect(gen.lastModelPath, equals('/tmp/gemma.litertlm'));
      expect(loader.calls, equals(1));
    });

    test('omits crop context from prompt when cropType is null', () async {
      final gen = _FakeGenerator();
      final svc = GemmaService(loader: _FakeLoader(), generator: gen);

      await svc.generate(query: 'q');

      expect(gen.lastPrompt!.contains('பயிர்:'), isFalse);
    });
  });

  group('GemmaService.generate — error mapping', () {
    test('empty query throws LlmException(E012)', () async {
      final svc = GemmaService(
        loader: _FakeLoader(),
        generator: _FakeGenerator(),
      );

      await expectLater(
        svc.generate(query: ''),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', 'E012'),
        ),
      );
    });

    test('model-not-loaded bubbles up as E009', () async {
      final svc = GemmaService(
        loader: _FakeLoader(error: LlmException.modelNotLoaded()),
        generator: _FakeGenerator(),
      );

      await expectLater(
        svc.generate(query: 'q'),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', 'E009'),
        ),
      );
    });

    test('non-LlmException loader error is wrapped as E009', () async {
      final svc = GemmaService(
        loader: _FakeLoader(error: StateError('disk full')),
        generator: _FakeGenerator(),
      );

      await expectLater(
        svc.generate(query: 'q'),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', 'E009'),
        ),
      );
    });

    test('generator timeout throws LlmException(E010)', () async {
      // Delay longer than the configured inference timeout.
      final longDelay = Duration(
        seconds: LlmConstants.inferenceTimeoutSeconds + 5,
      );
      final svc = GemmaService(
        loader: _FakeLoader(),
        generator: _FakeGenerator(delay: longDelay),
      );

      await expectLater(
        svc.generate(query: 'q'),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', 'E010'),
        ),
      );
    }, timeout: Timeout(Duration(seconds: 60)));

    test('generator OutOfMemoryError throws LlmException(E011)', () async {
      final svc = GemmaService(
        loader: _FakeLoader(),
        generator: _FakeGenerator(error: OutOfMemoryError()),
      );

      await expectLater(
        svc.generate(query: 'q'),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', 'E011'),
        ),
      );
    });

    test('unknown generator exception wraps as generic LlmException(E003)',
        () async {
      final svc = GemmaService(
        loader: _FakeLoader(),
        generator: _FakeGenerator(error: FormatException('boom')),
      );

      await expectLater(
        svc.generate(query: 'q'),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', 'E003'),
        ),
      );
    });
  });
}
