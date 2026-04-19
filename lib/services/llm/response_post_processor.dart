/// Cleans raw Gemma output into TTS-ready plain Tamil text.
///
/// Per `docs/srs_1.0.md` §7.8 the post-processor must:
///   - Strip markdown (headers, bold, backticks, list bullets)
///   - Expand common abbreviations so TTS pronounces them correctly
///   - Preserve paragraph breaks (TTS uses them as pause cues)
///
/// Structured action-item extraction (steps / costs / timeline) is
/// documented in SRS §7.8 as a longer-term goal and is **out of scope**
/// for Phase 6; we preserve line breaks so visible structure survives.
class ResponsePostProcessor {
  ResponsePostProcessor._();

  /// Tamil/English abbreviations Gemma commonly emits, mapped to their
  /// spoken Tamil forms. Kept small and conservative — only high-confidence
  /// expansions that improve TTS clarity.
  static const Map<String, String> _abbreviations = {
    'kg': 'கிலோ',
    'Kg': 'கிலோ',
    'KG': 'கிலோ',
    'gm': 'கிராம்',
    'gms': 'கிராம்',
    'g': 'கிராம்',
    'ha': 'ஹெக்டேர்',
    'mm': 'மில்லிமீட்டர்',
    'cm': 'சென்டிமீட்டர்',
    'ml': 'மில்லிலிட்டர்',
    'L': 'லிட்டர்',
    'ltr': 'லிட்டர்',
    'Rs': 'ரூபாய்',
    'INR': 'ரூபாய்',
    '₹': 'ரூபாய்',
  };

  /// Pipeline: strip markdown → expand abbreviations → collapse excess
  /// whitespace. Idempotent on already-clean input.
  static String process(String raw) {
    var text = raw;
    text = _stripMarkdown(text);
    text = _expandAbbreviations(text);
    text = _collapseWhitespace(text);
    return text.trim();
  }

  static String _stripMarkdown(String input) {
    var t = input;
    // Triple-backtick fenced code blocks.
    t = t.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Inline backticks.
    t = t.replaceAll('`', '');
    // Bold/italic markers (**text**, *text*, __text__, _text_).
    // `replaceAll` with a String doesn't expand $1 backrefs in Dart —
    // `replaceAllMapped` is required to keep the captured content.
    String unwrap(RegExp pattern) => t = t.replaceAllMapped(
          pattern,
          (m) => m.group(1) ?? '',
        );
    unwrap(RegExp(r'\*\*(.*?)\*\*'));
    unwrap(RegExp(r'__(.*?)__'));
    unwrap(RegExp(r'(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)'));
    unwrap(RegExp(r'(?<!_)_(?!_)(.*?)(?<!_)_(?!_)'));
    // ATX headers: leading #+ on a line.
    t = t.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Unordered list bullets: leading -, *, or + (followed by space).
    t = t.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    // Ordered list markers: "1. ", "2. ", ...
    t = t.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    // Blockquote markers.
    t = t.replaceAll(RegExp(r'^\s*>+\s?', multiLine: true), '');
    return t;
  }

  static String _expandAbbreviations(String input) {
    var t = input;
    for (final entry in _abbreviations.entries) {
      // Currency symbol (single char) — no word boundary.
      if (entry.key == '₹') {
        t = t.replaceAll(entry.key, entry.value);
        continue;
      }
      // Whole-word replacement (word boundaries on both sides).
      final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b');
      t = t.replaceAll(pattern, entry.value);
    }
    return t;
  }

  static String _collapseWhitespace(String input) {
    // Collapse 3+ consecutive newlines into a single blank line.
    var t = input.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    // Strip trailing spaces on each line.
    t = t.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    // Collapse runs of non-newline whitespace to single space.
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return t;
  }
}
