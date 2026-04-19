import 'gemma_model_loader.dart';

/// Stand-in for [GemmaModelLoader] when the active generator is remote
/// (e.g. [GeminiGenerator]). Skips the 2.6 GB asset copy entirely and
/// returns an empty path that the remote generator ignores.
///
/// Wired via the provider layer in API mode; keeps `GemmaService` unchanged.
class NoopModelLoader extends GemmaModelLoader {
  NoopModelLoader() : super();

  @override
  Future<String> ensureModelAvailable() async => '';
}
