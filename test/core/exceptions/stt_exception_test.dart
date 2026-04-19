import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';

void main() {
  group('SttException factories', () {
    test('default constructor uses E002', () {
      const e = SttException(message: 'generic failure');
      expect(e.code, equals('E002'));
    });

    test('modelNotLoaded has code E006', () {
      final e = SttException.modelNotLoaded();
      expect(e.code, equals('E006'));
      expect(e.message, contains('model'));
    });

    test('modelNotLoaded preserves originalError', () {
      final original = FormatException('io error');
      final e = SttException.modelNotLoaded(originalError: original);
      expect(e.originalError, same(original));
    });

    test('transcriptionFailed has code E007 with detail', () {
      final e = SttException.transcriptionFailed('timeout');
      expect(e.code, equals('E007'));
      expect(e.message, contains('timeout'));
    });

    test('lowConfidence has code E008 with formatted score', () {
      final e = SttException.lowConfidence(0.72);
      expect(e.code, equals('E008'));
      expect(e.message, contains('0.72'));
    });

    test('toString includes the error code', () {
      final e = SttException.modelNotLoaded();
      expect(e.toString(), contains('E006'));
    });
  });
}
