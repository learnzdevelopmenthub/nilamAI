import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:http/http.dart' as http;

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'llm_constants.dart';

/// Minimal abstraction over the LLM backend so tests can substitute a fake
/// without pulling in the native plugin or hitting a real Ollama server.
///
/// The `modelPath` parameter is used by the on-device `FlutterGemmaGenerator`
/// to locate the `.litertlm` file; the `OllamaGenerator` dev bridge ignores
/// it and uses its configured model name instead.
abstract class GemmaGenerator {
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  });
}

/// Dev/demo generator that talks to a locally-running Ollama server over
/// HTTP. Enables iteration on prompts and post-processing without needing
/// the full LiteRT-LM native stack.
///
/// SRS references this bridge for the Ollama Prize integration. It is NOT
/// the production path — `FlutterGemmaGenerator` is.
class OllamaGenerator implements GemmaGenerator {
  OllamaGenerator({
    String? baseUrl,
    String? modelName,
    http.Client? client,
  })  : baseUrl = baseUrl ?? LlmConstants.ollamaDefaultUrl,
        modelName = modelName ?? LlmConstants.ollamaDefaultModel,
        _client = client ?? http.Client();

  final String baseUrl;
  final String modelName;
  final http.Client _client;

  @override
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate');
    final body = jsonEncode({
      'model': modelName,
      'prompt': prompt,
      'stream': false,
      'options': {
        'num_predict': maxTokens,
        'temperature': temperature,
      },
    });

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw LlmException(
        message:
            'Ollama returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    // Decode as UTF-8 directly — Ollama doesn't always set charset=utf-8 and
    // `response.body` defaults to Latin-1 in that case, which mangles Tamil.
    final Map<String, dynamic> decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final text = decoded['response'];
    if (text is! String || text.isEmpty) {
      throw const LlmException(
        message: 'Ollama response missing "response" field',
      );
    }
    return text;
  }

  /// Test-only — closes the underlying HTTP client.
  void close() => _client.close();
}

/// Production on-device generator wrapping the `flutter_gemma` plugin
/// (LiteRT-LM backend). Lazily installs the model on first call and
/// reuses the loaded [InferenceModel] across subsequent invocations;
/// a fresh [InferenceModelSession] is created per request so each call
/// is one-shot with no conversation history.
///
/// Not covered by unit tests — trivial delegation to the plugin, which
/// requires a real device for end-to-end validation (see Phase 8).
class FlutterGemmaGenerator implements GemmaGenerator {
  FlutterGemmaGenerator();

  static const _tag = 'FlutterGemmaGenerator';

  InferenceModel? _model;
  String? _installedPath;
  int? _installedMaxTokens;

  @override
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  }) async {
    try {
      if (_model == null ||
          _installedPath != modelPath ||
          _installedMaxTokens != maxTokens) {
        AppLogger.info('Installing Gemma model from $modelPath', _tag);
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
        ).fromFile(modelPath).install();

        _model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
        _installedPath = modelPath;
        _installedMaxTokens = maxTokens;
        AppLogger.info('Gemma model ready', _tag);
      }

      final session = await _model!.createSession(
        temperature: temperature,
      );

      try {
        await session.addQueryChunk(
          Message.text(text: prompt, isUser: true),
        );
        return await session.getResponse();
      } finally {
        await session.close();
      }
    } on LlmException {
      rethrow;
    } catch (e, s) {
      AppLogger.error('Gemma inference failed', _tag, e, s);
      rethrow;
    }
  }

  /// Releases the underlying model. Call on app shutdown or when switching
  /// to a different generator (e.g. from production to Ollama dev bridge).
  Future<void> close() async {
    await _model?.close();
    _model = null;
    _installedPath = null;
    _installedMaxTokens = null;
  }
}
