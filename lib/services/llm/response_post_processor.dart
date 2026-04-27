/// Cleans raw Gemma output into TTS-ready plain text.
///
/// - Strips markdown (headers, bold, backticks, list bullets)
/// - Collapses excess whitespace
/// - Preserves paragraph breaks (TTS uses them as pause cues)
class ResponsePostProcessor {
  ResponsePostProcessor._();

  static String process(String raw) {
    var text = raw;
    text = _stripMarkdown(text);
    text = _collapseWhitespace(text);
    return text.trim();
  }

  static String _stripMarkdown(String input) {
    var t = input;
    // Triple-backtick fenced code blocks.
    t = t.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Inline backticks.
    t = t.replaceAll('`', '');
    // Bold/italic markers.
    String unwrap(RegExp pattern) => t = t.replaceAllMapped(
          pattern,
          (m) => m.group(1) ?? '',
        );
    unwrap(RegExp(r'\*\*(.*?)\*\*'));
    unwrap(RegExp(r'__(.*?)__'));
    unwrap(RegExp(r'(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)'));
    unwrap(RegExp(r'(?<!_)_(?!_)(.*?)(?<!_)_(?!_)'));
    // ATX headers.
    t = t.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Unordered list bullets.
    t = t.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    // Ordered list markers.
    t = t.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    // Blockquote markers.
    t = t.replaceAll(RegExp(r'^\s*>+\s?', multiLine: true), '');
    return t;
  }

  static String _collapseWhitespace(String input) {
    var t = input.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return t;
  }
}
