/// Pure-Dart English tokenizer for the BM25 retriever.
///
/// Lowercases, splits on non-alphanumeric, drops a small stopword set, and
/// drops tokens shorter than 2 chars. No stemming.
class Tokenizer {
  const Tokenizer();

  static const _stopwords = <String>{
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'of', 'in', 'on', 'at', 'to', 'for', 'from', 'by', 'with', 'as',
    'and', 'or', 'but', 'if', 'then', 'than', 'that', 'this', 'these',
    'those', 'it', 'its', 'i', 'you', 'we', 'they',
  };

  static final _splitter = RegExp(r'[^a-z0-9]+');

  List<String> tokenize(String input) {
    if (input.isEmpty) return const [];
    final lower = input.toLowerCase();
    final out = <String>[];
    for (final t in lower.split(_splitter)) {
      if (t.length < 2) continue;
      if (_stopwords.contains(t)) continue;
      out.add(t);
    }
    return out;
  }
}
