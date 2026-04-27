import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/llm/prompt_builder.dart';

void main() {
  group('PromptBuilder.build', () {
    test('injects query into the prompt', () {
      final built = PromptBuilder.build(query: 'Rice disease?');
      expect(built.text, contains('Farmer question: Rice disease?'));
      expect(built.query, equals('Rice disease?'));
    });

    test('includes English system and instruction lines', () {
      final built = PromptBuilder.build(query: 'test');
      expect(built.text, contains('NilamAI'));
      expect(built.text, contains('Reply in clear, concise English.'));
    });

    test('injects crop line when cropType is provided', () {
      final built = PromptBuilder.build(query: 'query', cropType: 'rice');
      expect(built.text, contains('Crop is rice.'));
    });

    test('omits crop line when cropType is null', () {
      final built = PromptBuilder.build(query: 'query');
      expect(built.text.contains('Crop is'), isFalse);
    });

    test('omits crop line when cropType is empty', () {
      final built = PromptBuilder.build(query: 'query', cropType: '');
      expect(built.text.contains('Crop is'), isFalse);
    });

    test('omits crop line when cropType is whitespace', () {
      final built = PromptBuilder.build(query: 'query', cropType: '   ');
      expect(built.text.contains('Crop is'), isFalse);
    });

    test('trims leading/trailing whitespace on query', () {
      final built = PromptBuilder.build(query: '  hello  ');
      expect(built.query, equals('hello'));
      expect(built.text, contains('Farmer question: hello'));
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
      final built = PromptBuilder.build(query: 'q', cropType: '  rice  ');
      expect(built.text, contains('Crop is rice.'));
      expect(built.text.contains('  rice  '), isFalse);
    });

    test('renders rich CropContext when supplied', () {
      final ctx = CropContext(
        cropName: 'Rice',
        variety: 'Ponni',
        stageName: 'Tillering',
        dayInStage: 12,
        totalDurationDays: 135,
        keyActivities: const ['Top-dress urea', 'Hand-weed'],
        commonDiseases: const ['Sheath blight'],
        recommendedFertilizer: '65 kg Urea per hectare',
      );
      final built =
          PromptBuilder.build(query: 'When to apply urea?', cropContext: ctx);
      expect(built.text, contains('Crop: Rice (Ponni)'));
      expect(built.text, contains('Tillering'));
      expect(built.text, contains('day 12'));
      expect(built.text, contains('Top-dress urea'));
      expect(built.text, contains('Sheath blight'));
      expect(built.text, contains('65 kg Urea'));
    });
  });
}
