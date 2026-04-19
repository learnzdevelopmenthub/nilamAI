import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';

void main() {
  group('LlmException factories', () {
    test('default constructor uses E003', () {
      const e = LlmException(message: 'generic failure');
      expect(e.code, equals('E003'));
    });

    test('modelNotLoaded has code E009', () {
      final e = LlmException.modelNotLoaded();
      expect(e.code, equals('E009'));
      expect(e.message, contains('model'));
    });

    test('modelNotLoaded preserves originalError', () {
      final original = FormatException('io error');
      final e = LlmException.modelNotLoaded(originalError: original);
      expect(e.originalError, same(original));
    });

    test('inferenceTimeout has code E010', () {
      final e = LlmException.inferenceTimeout();
      expect(e.code, equals('E010'));
      expect(e.message, contains('30'));
    });

    test('inferenceTimeout preserves originalError', () {
      final original = StateError('timed out');
      final e = LlmException.inferenceTimeout(originalError: original);
      expect(e.originalError, same(original));
    });

    test('outOfMemory has code E011', () {
      final e = LlmException.outOfMemory();
      expect(e.code, equals('E011'));
      expect(e.message, contains('memory'));
    });

    test('outOfMemory preserves originalError', () {
      final original = OutOfMemoryError();
      final e = LlmException.outOfMemory(originalError: original);
      expect(e.originalError, same(original));
    });

    test('invalidQuery has code E012 with detail', () {
      final e = LlmException.invalidQuery('empty transcription');
      expect(e.code, equals('E012'));
      expect(e.message, contains('empty transcription'));
    });

    test('toString includes the error code', () {
      final e = LlmException.modelNotLoaded();
      expect(e.toString(), contains('E009'));
    });
  });
}
