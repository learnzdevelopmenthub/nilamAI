import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/retrieval/tokenizer.dart';

void main() {
  const t = Tokenizer();

  test('lowercases and splits on non-alphanumeric', () {
    expect(t.tokenize('Rice Blast — Diamond-shaped lesions!'),
        equals(['rice', 'blast', 'diamond', 'shaped', 'lesions']));
  });

  test('drops stopwords and short tokens', () {
    expect(t.tokenize('The cat is on a mat'), equals(['cat', 'mat']));
  });

  test('returns empty for empty input', () {
    expect(t.tokenize(''), isEmpty);
  });

  test('returns empty for stopwords-only input', () {
    expect(t.tokenize('the and or but'), isEmpty);
  });

  test('keeps numerics', () {
    expect(t.tokenize('apply 65 kg urea per hectare'),
        equals(['apply', '65', 'kg', 'urea', 'per', 'hectare']));
  });
}
