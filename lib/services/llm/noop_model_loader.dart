import 'model_loader.dart';

/// Stand-in [ModelLoader] when the active generator is remote (e.g.
/// [DeepInfraGenerator]). Returns an empty path that the remote generator
/// ignores; keeps [GemmaService] unchanged.
class NoopModelLoader implements ModelLoader {
  NoopModelLoader();

  @override
  Future<String> ensureModelAvailable() async => '';
}
