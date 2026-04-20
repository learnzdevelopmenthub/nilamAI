/// Swap point for resolving a model file path before inference.
///
/// Implementations return the absolute path to a model file that the active
/// [GemmaGenerator] can consume. Remote generators (e.g.
/// [DeepInfraGenerator]) pair this with a no-op loader that returns an empty
/// path.
abstract class ModelLoader {
  Future<String> ensureModelAvailable();
}
