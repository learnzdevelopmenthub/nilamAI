import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/llm/response_post_processor.dart';

void main() {
  group('ResponsePostProcessor.process — markdown stripping', () {
    test('strips bold markers', () {
      final out = ResponsePostProcessor.process('It is **important** to apply.');
      expect(out, equals('It is important to apply.'));
    });

    test('strips italic markers (underscore)', () {
      final out = ResponsePostProcessor.process('hello _world_ today');
      expect(out, equals('hello world today'));
    });

    test('strips headers', () {
      final out = ResponsePostProcessor.process('## Title\nBody.');
      expect(out, contains('Title'));
      expect(out.contains('##'), isFalse);
    });

    test('strips inline backticks', () {
      final out = ResponsePostProcessor.process('Use `kubectl` command.');
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
    test('handles markdown + whitespace in one pass', () {
      const input = '## Title\n\n**Apply 5 kg** of seed.\n\n\n- First step';
      final out = ResponsePostProcessor.process(input);
      expect(out, contains('Title'));
      expect(out, contains('Apply 5 kg of seed.'));
      expect(out, contains('First step'));
      expect(out.contains('##'), isFalse);
      expect(out.contains('**'), isFalse);
      expect(out.contains('- '), isFalse);
    });

    test('is idempotent on clean input', () {
      const clean = 'A clean English response.';
      expect(ResponsePostProcessor.process(clean), equals(clean));
    });
  });
}
