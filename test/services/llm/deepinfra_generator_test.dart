import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/llm/deepinfra_generator.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('DeepInfraGenerator.generate', () {
    test('POSTs OpenAI-shaped body to DeepInfra and returns Tamil text',
        () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return _json({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'தக்காளிச் செடிக்கு நீம் எண்ணெய் பயன்படுத்துங்கள்.',
              },
            },
          ],
        });
      });

      final gen = DeepInfraGenerator(
        apiKey: 'test-key',
        model: 'google/gemma-4-26B-A4B-it',
        client: client,
      );

      final result = await gen.generate(
        modelPath: '/ignored',
        prompt: 'test prompt',
        maxTokens: 300,
        temperature: 0.3,
      );

      expect(
        result,
        equals('தக்காளிச் செடிக்கு நீம் எண்ணெய் பயன்படுத்துங்கள்.'),
      );
      expect(captured, isNotNull);
      expect(captured!.method, equals('POST'));
      expect(captured!.url.host, equals('api.deepinfra.com'));
      expect(
        captured!.url.path,
        equals('/v1/openai/chat/completions'),
      );
      expect(
        captured!.headers['authorization'],
        equals('Bearer test-key'),
      );

      final decoded = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(decoded['model'], equals('google/gemma-4-26B-A4B-it'));
      final messages = decoded['messages'] as List;
      expect((messages.first as Map)['role'], equals('user'));
      expect((messages.first as Map)['content'], equals('test prompt'));
      expect(decoded['max_tokens'], equals(300));
      expect(decoded['temperature'], equals(0.3));
    });

    test('throws LlmException on non-200 status (e.g. 401 auth)', () async {
      final client = MockClient((request) async {
        return http.Response('bad api key', 401);
      });
      final gen = DeepInfraGenerator(apiKey: 'bad-key', client: client);

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

    test('maps SocketException to networkOffline (E013)', () async {
      final client = MockClient((request) async {
        throw const SocketException('no route to host');
      });
      final gen = DeepInfraGenerator(apiKey: 'k', client: client);

      try {
        await gen.generate(
          modelPath: '',
          prompt: 'hi',
          maxTokens: 100,
          temperature: 0.3,
        );
        fail('expected LlmException');
      } on LlmException catch (e) {
        expect(e.code, equals('E013'));
      }
    });

    test('maps TimeoutException to inferenceTimeout (E010)', () async {
      final client = MockClient((request) async {
        throw TimeoutException('slow');
      });
      final gen = DeepInfraGenerator(apiKey: 'k', client: client);

      try {
        await gen.generate(
          modelPath: '',
          prompt: 'hi',
          maxTokens: 100,
          temperature: 0.3,
        );
        fail('expected LlmException');
      } on LlmException catch (e) {
        expect(e.code, equals('E010'));
      }
    });

    test('throws when choices array is empty', () async {
      final client = MockClient((request) async {
        return _json({'choices': <Object>[]});
      });
      final gen = DeepInfraGenerator(apiKey: 'k', client: client);

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

    test('throws on malformed JSON body', () async {
      final client = MockClient((request) async {
        return http.Response('<html>oops</html>', 200);
      });
      final gen = DeepInfraGenerator(apiKey: 'k', client: client);

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

    test('throws when message.content is missing', () async {
      final client = MockClient((request) async {
        return _json({
          'choices': [
            {
              'message': <String, Object>{'role': 'assistant'},
            },
          ],
        });
      });
      final gen = DeepInfraGenerator(apiKey: 'k', client: client);

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
  });
}
