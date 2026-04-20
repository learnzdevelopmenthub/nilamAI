/// Minimal abstraction over the LLM backend so tests can substitute a fake
/// without hitting a real network service.
///
/// `modelPath` is retained for interface parity with on-device implementations
/// — the current production backend ([DeepInfraGenerator]) ignores it.
abstract class GemmaGenerator {
  Future<String> generate({
    required String modelPath,
    required String prompt,
    required int maxTokens,
    required double temperature,
  });
}
