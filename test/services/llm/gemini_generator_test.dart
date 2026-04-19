import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/llm/gemini_generator.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('GeminiGenerator.generate', () {
    test('POSTs prompt to v1beta endpoint and returns Tamil text', () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return _json({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'தக்காளிச் செடிக்கு நீம் எண்ணெய் பயன்படுத்துங்கள்.'},
                ],
              },
            },
          ],
        });
      });

      final gen = GeminiGenerator(
        apiKey: 'test-key',
        model: 'gemini-1.5-flash-latest',
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
      expect(captured!.url.host, equals('generativelanguage.googleapis.com'));
      expect(
        captured!.url.path,
        equals('/v1beta/models/gemini-1.5-flash-latest:generateContent'),
      );
      expect(captured!.url.queryParameters['key'], equals('test-key'));

      final decoded = jsonDecode(captured!.body) as Map<String, dynamic>;
      final parts =
          ((decoded['contents'] as List).first as Map)['parts'] as List;
      expect((parts.first as Map)['text'], equals('test prompt'));
      final cfg = decoded['generationConfig'] as Map;
      expect(cfg['maxOutputTokens'], equals(300));
      expect(cfg['temperature'], equals(0.3));
    });

    test('throws LlmException on non-200 status (e.g. 400 auth)', () async {
      final client = MockClient((request) async {
        return http.Response('bad api key', 400);
      });
      final gen = GeminiGenerator(apiKey: 'bad-key', client: client);

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
      final gen = GeminiGenerator(apiKey: 'k', client: client);

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
      final gen = GeminiGenerator(apiKey: 'k', client: client);

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

    test('throws when candidates array is empty', () async {
      final client = MockClient((request) async {
        return _json({'candidates': <Object>[]});
      });
      final gen = GeminiGenerator(apiKey: 'k', client: client);

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
      final gen = GeminiGenerator(apiKey: 'k', client: client);

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

    test('throws when text field is missing from parts', () async {
      final client = MockClient((request) async {
        return _json({
          'candidates': [
            {
              'content': {
                'parts': [<String, Object>{}],
              },
            },
          ],
        });
      });
      final gen = GeminiGenerator(apiKey: 'k', client: client);

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
