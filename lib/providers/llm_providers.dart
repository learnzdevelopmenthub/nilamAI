import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/exceptions/app_exception.dart';
import '../core/logging/logger.dart';
import '../services/llm/gemma_generator.dart';
import '../services/llm/gemma_model_loader.dart';
import '../services/llm/gemma_service.dart';

// -----------------------------------------------------------------------------
// Sealed Gemma state
// -----------------------------------------------------------------------------

sealed class GemmaState {
  const GemmaState();
}

class GemmaIdle extends GemmaState {
  const GemmaIdle();
}

class GemmaLoadingModel extends GemmaState {
  const GemmaLoadingModel();
}

class GemmaGenerating extends GemmaState {
  const GemmaGenerating();
}

class GemmaComplete extends GemmaState {
  const GemmaComplete({required this.response});

  final GemmaResponse response;
}

class GemmaError extends GemmaState {
  const GemmaError({required this.code, required this.message});

  final String code;
  final String message;
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final gemmaModelLoaderProvider = Provider<GemmaModelLoader>((ref) {
  return GemmaModelLoader();
});

/// Production generator. Override with [OllamaGenerator] for dev, or with a
/// fake for tests.
final gemmaGeneratorProvider = Provider<GemmaGenerator>((ref) {
  return FlutterGemmaGenerator();
});

final gemmaServiceProvider = Provider<GemmaService>((ref) {
  return GemmaService(
    loader: ref.watch(gemmaModelLoaderProvider),
    generator: ref.watch(gemmaGeneratorProvider),
  );
});

final gemmaNotifierProvider =
    NotifierProvider<GemmaNotifier, GemmaState>(GemmaNotifier.new);

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class GemmaNotifier extends Notifier<GemmaState> {
  static const _tag = 'GemmaNotifier';

  @override
  GemmaState build() => const GemmaIdle();

  GemmaService get _service => ref.read(gemmaServiceProvider);

  /// Kicks off a full inference: LoadingModel → Generating → Complete/Error.
  Future<void> generate({required String query, String? cropType}) async {
    state = const GemmaLoadingModel();
    AppLogger.info('Gemma generation started', _tag);

    // Give the UI a frame to render "loading model" before heavy work.
    await Future<void>.delayed(Duration.zero);

    state = const GemmaGenerating();
    try {
      final response = await _service.generate(
        query: query,
        cropType: cropType,
      );
      state = GemmaComplete(response: response);
      AppLogger.info(
        'Gemma generation complete (${response.latencyMs} ms)',
        _tag,
      );
    } on LlmException catch (e, st) {
      AppLogger.error('Gemma failed (${e.code})', _tag, e, st);
      state = GemmaError(code: e.code, message: e.message);
    } catch (e, st) {
      AppLogger.error('Gemma unexpected failure', _tag, e, st);
      state = GemmaError(code: 'E003', message: e.toString());
    }
  }

  void reset() {
    state = const GemmaIdle();
  }
}
