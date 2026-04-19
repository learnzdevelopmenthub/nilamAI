import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/llm/response_post_processor.dart';

void main() {
  group('ResponsePostProcessor.process — markdown stripping', () {
    test('strips bold markers', () {
      final out = ResponsePostProcessor.process('இது **முக்கியம்** ஆகும்.');
      expect(out, equals('இது முக்கியம் ஆகும்.'));
    });

    test('strips italic markers (underscore)', () {
      final out = ResponsePostProcessor.process('hello _world_ today');
      expect(out, equals('hello world today'));
    });

    test('strips headers', () {
      final out = ResponsePostProcessor.process('## தலைப்பு\nதகவல்.');
      expect(out, contains('தலைப்பு'));
      expect(out.contains('##'), isFalse);
    });

    test('strips inline backticks', () {
      final out = ResponsePostProcessor.process('Use `kubectl` command.');
      // "kubectl" becomes whole-word after backtick strip — no abbreviation
      // match (not in map).
      expect(out.contains('`'), isFalse);
      expect(out, contains('kubectl'));
    });

    test('strips fenced code blocks', () {
      const input = 'Before\n```dart\nvoid main() {}\n```\nAfter';
      final out = ResponsePostProcessor.process(input);
      expect(out.contains('```'), isFalse);
      expect(out.contains('void main'), isFalse);
      expect(out, contains('Before'));
      expect(out, contains('After'));
    });

    test('strips unordered list bullets', () {
      const input = '- item one\n- item two\n* item three';
      final out = ResponsePostProcessor.process(input);
      expect(out, contains('item one'));
      expect(out, contains('item two'));
      expect(out, contains('item three'));
      expect(out.contains('- '), isFalse);
      expect(out.contains('* '), isFalse);
    });

    test('strips ordered list markers', () {
      const input = '1. first\n2. second\n3. third';
      final out = ResponsePostProcessor.process(input);
      expect(out, contains('first'));
      expect(out.contains('1.'), isFalse);
      expect(out.contains('2.'), isFalse);
    });

    test('strips blockquotes', () {
      final out = ResponsePostProcessor.process('> quoted text');
      expect(out, equals('quoted text'));
    });
  });

  group('ResponsePostProcessor.process — abbreviation expansion', () {
    test('expands kg to கிலோ', () {
      final out = ResponsePostProcessor.process('5 kg விதை போடு.');
      expect(out, equals('5 கிலோ விதை போடு.'));
    });

    test('expands Rs to ரூபாய்', () {
      final out = ResponsePostProcessor.process('விலை Rs 500.');
      expect(out, contains('ரூபாய்'));
      expect(out.contains(RegExp(r'\bRs\b')), isFalse);
    });

    test('expands ₹ currency symbol', () {
      final out = ResponsePostProcessor.process('விலை ₹500.');
      expect(out, contains('ரூபாய்'));
      expect(out.contains('₹'), isFalse);
    });

    test('expands ha (hectare)', () {
      final out = ResponsePostProcessor.process('1 ha நிலம்');
      expect(out, contains('ஹெக்டேர்'));
    });

    test('does not expand abbreviations inside words', () {
      // "kgf" should not have "kg" replaced.
      final out = ResponsePostProcessor.process('kgfoobar');
      expect(out, equals('kgfoobar'));
    });
  });

  group('ResponsePostProcessor.process — whitespace', () {
    test('preserves single paragraph breaks', () {
      const input = 'Para one.\n\nPara two.';
      final out = ResponsePostProcessor.process(input);
      expect(out, equals('Para one.\n\nPara two.'));
    });

    test('collapses 3+ newlines to a single blank line', () {
      const input = 'A.\n\n\n\n\nB.';
      final out = ResponsePostProcessor.process(input);
      expect(out, equals('A.\n\nB.'));
    });

    test('collapses runs of spaces', () {
      final out = ResponsePostProcessor.process('too    many   spaces');
      expect(out, equals('too many spaces'));
    });

    test('trims leading and trailing whitespace', () {
      final out = ResponsePostProcessor.process('   \n\ntext\n\n   ');
      expect(out, equals('text'));
    });
  });

  group('ResponsePostProcessor.process — combined pipeline', () {
    test('handles markdown + abbreviation + whitespace in one pass', () {
      const input = '## தலைப்பு\n\n**5 kg** விதை போடு.\n\n\n- முதல் படி';
      final out = ResponsePostProcessor.process(input);
      expect(out, contains('தலைப்பு'));
      expect(out, contains('5 கிலோ விதை போடு.'));
      expect(out, contains('முதல் படி'));
      expect(out.contains('##'), isFalse);
      expect(out.contains('**'), isFalse);
      expect(out.contains('- '), isFalse);
    });

    test('is idempotent on clean input', () {
      const clean = 'சுத்தமான தமிழ் பதில்.';
      expect(ResponsePostProcessor.process(clean), equals(clean));
    });
  });
}
