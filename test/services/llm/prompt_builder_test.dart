import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/llm/prompt_builder.dart';

void main() {
  group('PromptBuilder.build', () {
    test('injects query into the prompt', () {
      final built = PromptBuilder.build(query: 'நெல் பயிர் நோய்?');
      expect(built.text, contains('கேள்வி: நெல் பயிர் நோய்?'));
      expect(built.query, equals('நெல் பயிர் நோய்?'));
    });

    test('includes Tamil system and instruction lines', () {
      final built = PromptBuilder.build(query: 'test');
      expect(built.text, contains('நிலம்AI'));
      expect(built.text, contains('தமிழில் சுருக்கமாக'));
    });

    test('injects crop line when cropType is provided', () {
      final built = PromptBuilder.build(query: 'query', cropType: 'நெல்');
      expect(built.text, contains('பயிர்: நெல்'));
    });

    test('omits crop line when cropType is null', () {
      final built = PromptBuilder.build(query: 'query');
      expect(built.text.contains('பயிர்:'), isFalse);
    });

    test('omits crop line when cropType is empty', () {
      final built = PromptBuilder.build(query: 'query', cropType: '');
      expect(built.text.contains('பயிர்:'), isFalse);
    });

    test('omits crop line when cropType is whitespace', () {
      final built = PromptBuilder.build(query: 'query', cropType: '   ');
      expect(built.text.contains('பயிர்:'), isFalse);
    });

    test('trims leading/trailing whitespace on query', () {
      final built = PromptBuilder.build(query: '  hello  ');
      expect(built.query, equals('hello'));
      expect(built.text, contains('கேள்வி: hello'));
    });

    test('throws LlmException(E012) on empty query', () {
      expect(
        () => PromptBuilder.build(query: ''),
        throwsA(
          isA<LlmException>().having((e) => e.code, 'code', equals('E012')),
        ),
      );
    });

    test('throws LlmException(E012) on whitespace-only query', () {
      expect(
        () => PromptBuilder.build(query: '   \n\t  '),
        throwsA(isA<LlmException>()),
      );
    });

    test('preserves crop type trimming', () {
      final built = PromptBuilder.build(query: 'q', cropType: '  நெல்  ');
      expect(built.text, contains('பயிர்: நெல்'));
      expect(built.text.contains('  நெல்  '), isFalse);
    });
  });
}
