import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import 'gemma_generator.dart';
import 'llm_constants.dart';
import 'model_loader.dart';
import 'prompt_builder.dart';
import 'response_post_processor.dart';

/// Async connectivity probe; returns the current transports (wifi, mobile,
/// ethernet, vpn, or none). Injected so tests can run without the real
/// connectivity plugin. Null means "skip the check".
typedef ConnectivityCheck = Future<List<ConnectivityResult>> Function();

/// Outcome of a successful Gemma inference.
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

/// High-level service that turns an English query + optional crop context
/// into a post-processed English response using Gemma 4 via DeepInfra.
///
/// Deliberately DB-free: the caller is responsible for persisting the
/// [GemmaResponse] fields to `QueryHistory` and invalidating the Riverpod
/// provider. Keeps this service unit-testable without sqflite.
class GemmaService {
  GemmaService({
    required ModelLoader loader,
    required GemmaGenerator generator,
    ConnectivityCheck? connectivityCheck,
  })  : _loader = loader,
        _generator = generator,
        _connectivityCheck = connectivityCheck;

  static const _tag = 'GemmaService';

  final ModelLoader _loader;
  final GemmaGenerator _generator;
  final ConnectivityCheck? _connectivityCheck;

  /// Generates an English response for [query], optionally grounded with a
  /// [cropContext] from a tracked crop profile.
  Future<GemmaResponse> generate({
    required String query,
    String? cropType,
    CropContext? cropContext,
  }) async {
    final built = PromptBuilder.build(
      query: query,
      cropType: cropType,
      cropContext: cropContext,
    );

    await _ensureOnline();
    final modelPath = await _loadModel();

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

  /// Generates a multimodal response (image + text). Used by the disease
  /// diagnosis flow.
  Future<GemmaResponse> generateWithImage({
    required String prompt,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    int? maxTokens,
    double? temperature,
  }) async {
    if (prompt.trim().isEmpty) {
      throw LlmException.invalidQuery('prompt is empty');
    }
    await _ensureOnline();
    final modelPath = await _loadModel();

    final stopwatch = Stopwatch()..start();
    try {
      final raw = await _generator
          .generateWithImage(
            modelPath: modelPath,
            prompt: prompt,
            imageBytes: imageBytes,
            mimeType: mimeType,
            maxTokens: maxTokens ?? LlmConstants.maxOutputTokens,
            temperature: temperature ?? LlmConstants.temperature,
          )
          .timeout(
            const Duration(seconds: LlmConstants.inferenceTimeoutSeconds),
          );
      stopwatch.stop();
      AppLogger.info(
        'Gemma vision inference complete in ${stopwatch.elapsedMilliseconds} ms',
        _tag,
      );
      return GemmaResponse(
        text: ResponsePostProcessor.process(raw),
        rawText: raw,
        prompt: prompt,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on TimeoutException catch (e) {
      throw LlmException.inferenceTimeout(originalError: e);
    } on LlmException {
      rethrow;
    } catch (e, s) {
      AppLogger.error('Gemma vision inference failed', _tag, e, s);
      throw LlmException(
        message: 'Gemma vision inference failed: $e',
        originalError: e,
      );
    }
  }

  Future<void> _ensureOnline() async {
    if (_connectivityCheck == null) return;
    final status = await _connectivityCheck();
    if (status.every((c) => c == ConnectivityResult.none)) {
      throw LlmException.networkOffline();
    }
  }

  Future<String> _loadModel() async {
    try {
      return await _loader.ensureModelAvailable();
    } on LlmException {
      rethrow;
    } catch (e) {
      throw LlmException.modelNotLoaded(originalError: e);
    }
  }
}
