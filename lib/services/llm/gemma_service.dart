import 'dart:async';

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'gemma_generator.dart';
import 'gemma_model_loader.dart';
import 'llm_constants.dart';
import 'prompt_builder.dart';
import 'response_post_processor.dart';

/// Outcome of a successful Gemma inference.
///
/// [text] is the post-processed Tamil response ready for TTS and UI.
/// [rawText] is the untouched model output (kept for diagnostics).
/// [prompt] is the assembled prompt — persist to `QueryHistory.gemmaPrompt`.
/// [latencyMs] is wall-clock inference time — persist to
/// `QueryHistory.gemmaLatencyMs`.
class GemmaResponse {
  const GemmaResponse({
    required this.text,
    required this.rawText,
    required this.prompt,
    required this.latencyMs,
  });

  final String text;
  final String rawText;
  final String prompt;
  final int latencyMs;
}

/// High-level service that turns a Tamil query + optional crop context into
/// a post-processed Tamil response using Gemma 4 E2B on-device.
///
/// Deliberately DB-free: the caller is responsible for persisting the
/// [GemmaResponse] fields to `QueryHistory` and invalidating the Riverpod
/// provider. Keeps this service unit-testable without sqflite.
class GemmaService {
  GemmaService({
    required GemmaModelLoader loader,
    required GemmaGenerator generator,
  })  : _loader = loader,
        _generator = generator;

  static const _tag = 'GemmaService';

  final GemmaModelLoader _loader;
  final GemmaGenerator _generator;

  /// Generates a Tamil response for [query], optionally contextualized with
  /// [cropType] from the user profile.
  ///
  /// Error handling (SRS §10.3):
  /// - [LlmException.invalidQuery] (E012) — empty/whitespace query
  /// - [LlmException.modelNotLoaded] (E009) — model asset missing or I/O error
  /// - [LlmException.inferenceTimeout] (E010) — >30 s without a response
  /// - [LlmException.outOfMemory] (E011) — OOM during inference
  Future<GemmaResponse> generate({
    required String query,
    String? cropType,
  }) async {
    // PromptBuilder throws E012 on empty/whitespace.
    final built = PromptBuilder.build(query: query, cropType: cropType);

    final String modelPath;
    try {
      modelPath = await _loader.ensureModelAvailable();
    } on LlmException {
      rethrow;
    } catch (e) {
      throw LlmException.modelNotLoaded(originalError: e);
    }

    final stopwatch = Stopwatch()..start();
    try {
      final raw = await _generator
          .generate(
            modelPath: modelPath,
            prompt: built.text,
            maxTokens: LlmConstants.maxOutputTokens,
            temperature: LlmConstants.temperature,
          )
          .timeout(
            const Duration(seconds: LlmConstants.inferenceTimeoutSeconds),
          );
      stopwatch.stop();
      AppLogger.info(
        'Gemma inference complete in ${stopwatch.elapsedMilliseconds} ms',
        _tag,
      );

      return GemmaResponse(
        text: ResponsePostProcessor.process(raw),
        rawText: raw,
        prompt: built.text,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on TimeoutException catch (e) {
      AppLogger.error('Gemma inference timed out', _tag, e);
      throw LlmException.inferenceTimeout(originalError: e);
    } on OutOfMemoryError catch (e, s) {
      AppLogger.error('Gemma ran out of memory', _tag, e, s);
      throw LlmException.outOfMemory(originalError: e);
    } on LlmException {
      rethrow;
    } catch (e, s) {
      AppLogger.error('Gemma inference failed', _tag, e, s);
      throw LlmException(
        message: 'Gemma inference failed: $e',
        originalError: e,
      );
    }
  }
}
