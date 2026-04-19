import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'gemma_generator.dart';
import 'llm_constants.dart';

/// Production LLM backend that calls Google's Gemini `generateContent` REST
/// endpoint. Replaces the on-device `FlutterGemmaGenerator` on 4 GB RAM
/// devices where the 2.58 GB `.litertlm` model OOM-kills the app.
///
/// Implements the same [GemmaGenerator] contract as the on-device and Ollama
/// paths so callers (`GemmaService`, providers, the UI state machine) do not
/// change. The `modelPath` argument is ignored; Gemini hosts the model.
class GeminiGenerator implements GemmaGenerator {
  GeminiGenerator({
    required this.apiKey,
    String? baseUrl,
    String? model,
    http.Client? client,
  })  : baseUrl = baseUrl ?? LlmConstants.geminiBaseUrl,
        model = model ?? LlmConstants.geminiModel,
        _client = client ?? http.Client();

  static const _tag = 'GeminiGenerator';

  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _client;

  @override
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    final uri = Uri.parse('$baseUrl/$model:generateContent?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': temperature,
      },
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: LlmConstants.inferenceTimeoutSeconds),
          );
    } on TimeoutException catch (e) {
      throw LlmException.inferenceTimeout(originalError: e);
    } on SocketException catch (e) {
      throw LlmException.networkOffline(originalError: e);
    } on http.ClientException catch (e) {
      throw LlmException.networkOffline(originalError: e);
    }

    if (response.statusCode != 200) {
      final bodyText = utf8.decode(response.bodyBytes, allowMalformed: true);
      AppLogger.error(
        'Gemini HTTP ${response.statusCode}: $bodyText',
        _tag,
      );
      throw LlmException(
        message: 'Gemini returned HTTP ${response.statusCode}: $bodyText',
      );
    }

    // Decode as UTF-8 directly — matches OllamaGenerator for correct Tamil.
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e) {
      throw LlmException.modelNotLoaded(originalError: e);
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const LlmException(
        message: 'Gemini response missing "candidates"',
        code: 'E009',
      );
    }

    final content = (candidates.first as Map<String, dynamic>)['content'];
    final parts = (content is Map<String, dynamic>) ? content['parts'] : null;
    if (parts is! List || parts.isEmpty) {
      throw const LlmException(
        message: 'Gemini response missing "content.parts"',
        code: 'E009',
      );
    }

    final text = (parts.first as Map<String, dynamic>)['text'];
    if (text is! String || text.isEmpty) {
      throw const LlmException(
        message: 'Gemini response missing text',
        code: 'E009',
      );
    }
    return text;
  }

  /// Test-only — closes the underlying HTTP client.
  void close() => _client.close();
}
