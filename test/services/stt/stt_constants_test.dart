import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/stt/stt_constants.dart';

void main() {
  group('SttConstants', () {
    test('model asset path matches bundle location', () {
      expect(
        SttConstants.modelAssetPath,
        equals('assets/models/ggml-base-q8_0.bin'),
      );
    });

    test('model filename is ggml-base-q8_0.bin', () {
      expect(SttConstants.modelFileName, equals('ggml-base-q8_0.bin'));
    });

    test('language is Tamil', () {
      expect(SttConstants.language, equals('ta'));
    });

    test('confidence for unedited transcription is 1.0', () {
      expect(SttConstants.confidenceUnedited, equals(1.0));
    });

    test('confidence for edited transcription is 0.5', () {
      expect(SttConstants.confidenceEdited, equals(0.5));
    });

    test('edited confidence is strictly lower than unedited', () {
      expect(
        SttConstants.confidenceEdited,
        lessThan(SttConstants.confidenceUnedited),
      );
    });

    test('wav extension is dotted', () {
      expect(SttConstants.wavExtension, equals('.wav'));
    });

    test('max transcribe timeout is bounded', () {
      expect(SttConstants.maxTranscribeSeconds, greaterThan(0));
      expect(SttConstants.maxTranscribeSeconds, lessThanOrEqualTo(120));
    });

    test('min audio file bytes is non-trivial', () {
      expect(SttConstants.minAudioFileBytes, greaterThan(0));
    });
  });
}
