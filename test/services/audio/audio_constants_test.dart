import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/audio/audio_constants.dart';

void main() {
  group('AudioConstants', () {
    test('sampleRate is 16kHz for Whisper STT', () {
      expect(AudioConstants.sampleRate, equals(16000));
    });

    test('numChannels is mono', () {
      expect(AudioConstants.numChannels, equals(1));
    });

    test('bitRate matches 16-bit * 16kHz', () {
      expect(AudioConstants.bitRate, equals(256000));
    });

    test('maxDurationSeconds is 120', () {
      expect(AudioConstants.maxDurationSeconds, equals(120));
    });

    test('minDurationSeconds is 10', () {
      expect(AudioConstants.minDurationSeconds, equals(10));
    });

    test('amplitudeIntervalMs targets ~30 FPS', () {
      expect(AudioConstants.amplitudeIntervalMs, equals(33));
      // 1000ms / 33ms ≈ 30 FPS
      expect(1000 / AudioConstants.amplitudeIntervalMs,
          closeTo(30, 1));
    });

    test('silence threshold is below clipping threshold', () {
      expect(AudioConstants.silenceThresholdDb,
          lessThan(AudioConstants.clippingThresholdDb));
    });

    test('file extension is .wav', () {
      expect(AudioConstants.fileExtension, equals('.wav'));
    });

    test('normalization range spans 60 dB', () {
      expect(
        AudioConstants.maxDb - AudioConstants.minDb,
        equals(60.0),
      );
    });
  });
}
