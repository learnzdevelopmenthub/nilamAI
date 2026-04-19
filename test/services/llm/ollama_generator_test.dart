import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/llm/gemma_generator.dart';

void main() {
  group('OllamaGenerator.generate', () {
    test('POSTs prompt and returns the response field', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response.bytes(
          utf8.encode(jsonEncode({'response': 'தமிழ் பதில்.', 'done': true})),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final gen = OllamaGenerator(
        baseUrl: 'http://localhost:11434',
        modelName: 'gemma2:2b',
        client: client,
      );

      final result = await gen.generate(
        modelPath: '/ignored',
        prompt: 'test prompt',
        maxTokens: 300,
        temperature: 0.3,
      );

      expect(result, equals('தமிழ் பதில்.'));
      expect(captured, isNotNull);
      expect(captured!.method, equals('POST'));
      expect(captured!.url.toString(),
          equals('http://localhost:11434/api/generate'));

      final decoded = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(decoded['model'], equals('gemma2:2b'));
      expect(decoded['prompt'], equals('test prompt'));
      expect(decoded['stream'], equals(false));
      expect((decoded['options'] as Map)['num_predict'], equals(300));
      expect((decoded['options'] as Map)['temperature'], equals(0.3));
    });

    test('throws LlmException on non-200 status', () async {
      final client = MockClient((request) async {
        return http.Response('server boom', 500);
      });
      final gen = OllamaGenerator(client: client);

      await expectLater(
        gen.generate(
          modelPath: '',
          prompt: 'hi',
          maxTokens: 100,
          temperature: 0.3,
        ),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws LlmException when response field is missing', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'done': true}), 200);
      });
      final gen = OllamaGenerator(client: client);

      await expectLater(
        gen.generate(
          modelPath: '',
          prompt: 'hi',
          maxTokens: 100,
          temperature: 0.3,
        ),
        throwsA(isA<LlmException>()),
      );
    });

    test('throws LlmException when response field is empty', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'response': ''}), 200);
      });
      final gen = OllamaGenerator(client: client);

      await expectLater(
        gen.generate(
          modelPath: '',
          prompt: 'hi',
          maxTokens: 100,
          temperature: 0.3,
        ),
        throwsA(isA<LlmException>()),
      );
    });

    test('defaults baseUrl and modelName from LlmConstants', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'response': 'ok'}), 200);
      });
      final gen = OllamaGenerator(client: client);

      await gen.generate(
        modelPath: '',
        prompt: 'p',
        maxTokens: 1,
        temperature: 0.0,
      );

      expect(captured!.url.host, equals('localhost'));
      expect(captured!.url.port, equals(11434));
      final decoded = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(decoded['model'], equals('gemma2:2b'));
    });
  });
}
