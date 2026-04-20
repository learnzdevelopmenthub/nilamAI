import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'gemma_generator.dart';
import 'llm_constants.dart';

/// Production LLM backend that calls DeepInfra's OpenAI-compatible
/// chat-completions endpoint to run Gemma 4.
///
/// Implements the [GemmaGenerator] contract so callers (`GemmaService`,
/// providers, the UI state machine) are unchanged. The `modelPath` argument
/// is ignored; DeepInfra hosts the model.
class DeepInfraGenerator implements GemmaGenerator {
  DeepInfraGenerator({
    required this.apiKey,
    String? baseUrl,
    String? model,
    http.Client? client,
  })  : baseUrl = baseUrl ?? LlmConstants.deepInfraBaseUrl,
        model = model ?? LlmConstants.deepInfraModel,
        _client = client ?? http.Client();

  static const _tag = 'DeepInfraGenerator';

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
    final uri = Uri.parse(baseUrl);
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
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
        'DeepInfra HTTP ${response.statusCode}: $bodyText',
        _tag,
      );
      throw LlmException(
        message:
            'DeepInfra returned HTTP ${response.statusCode}: $bodyText',
      );
    }

    // Decode as UTF-8 directly so Tamil round-trips correctly.
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e) {
      throw LlmException.modelNotLoaded(originalError: e);
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const LlmException(
        message: 'DeepInfra response missing "choices"',
        code: 'E009',
      );
    }

    final message = (choices.first as Map<String, dynamic>)['message'];
    final content =
        (message is Map<String, dynamic>) ? message['content'] : null;
    if (content is! String || content.isEmpty) {
      throw const LlmException(
        message: 'DeepInfra response missing "message.content"',
        code: 'E009',
      );
    }
    return content;
  }

  /// Test-only — closes the underlying HTTP client.
  void close() => _client.close();
}
