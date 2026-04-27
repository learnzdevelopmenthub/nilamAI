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

  /// Multimodal variant: send a prompt plus one image (raw bytes — encoded
  /// as a `data:image/jpeg;base64,…` URL by the implementation).
  ///
  /// Defaults to throwing so existing fakes keep compiling; callers should
  /// only invoke this on backends that advertise vision support.
  Future<String> generateWithImage({
    required String modelPath,
    required String prompt,
    required List<int> imageBytes,
    String mimeType = 'image/jpeg',
    required int maxTokens,
    required double temperature,
  }) {
    throw UnimplementedError(
      'generateWithImage not supported by this backend',
    );
  }
}
