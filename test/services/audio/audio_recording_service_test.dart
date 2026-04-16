import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/audio/audio_constants.dart';
import 'package:nilam_ai/services/audio/audio_recording_service.dart';

void main() {
  group('AudioRecordingService.normalizeAmplitude', () {
    test('maps minDb (-60) to 0.0', () {
      expect(
        AudioRecordingService.normalizeAmplitude(AudioConstants.minDb),
        equals(0.0),
      );
    });

    test('maps maxDb (0) to 1.0', () {
      expect(
        AudioRecordingService.normalizeAmplitude(AudioConstants.maxDb),
        equals(1.0),
      );
    });

    test('maps midpoint (-30) to 0.5', () {
      expect(
        AudioRecordingService.normalizeAmplitude(-30.0),
        equals(0.5),
      );
    });

    test('clamps values below minDb to 0.0', () {
      expect(
        AudioRecordingService.normalizeAmplitude(-100.0),
        equals(0.0),
      );
    });

    test('clamps values above maxDb to 1.0', () {
      expect(
        AudioRecordingService.normalizeAmplitude(5.0),
        equals(1.0),
      );
    });

    test('returns proportional value for -15 dBFS', () {
      // (-15 - (-60)) / (0 - (-60)) = 45/60 = 0.75
      expect(
        AudioRecordingService.normalizeAmplitude(-15.0),
        closeTo(0.75, 0.001),
      );
    });
  });

  group('AudioRecordingService.analyzeQuality', () {
    test('returns null for empty amplitudes', () {
      expect(AudioRecordingService.analyzeQuality([]), isNull);
    });

    test('returns null for normal audio levels', () {
      final amplitudes = List.filled(100, -15.0);
      expect(AudioRecordingService.analyzeQuality(amplitudes), isNull);
    });

    test('returns too_quiet for very low average', () {
      final amplitudes = List.filled(100, -45.0);
      expect(
        AudioRecordingService.analyzeQuality(amplitudes),
        equals('too_quiet'),
      );
    });

    test('returns too_quiet when average is exactly at threshold', () {
      // Average < -30 dBFS
      final amplitudes = List.filled(100, -31.0);
      expect(
        AudioRecordingService.analyzeQuality(amplitudes),
        equals('too_quiet'),
      );
    });

    test('returns clipping when any sample exceeds threshold', () {
      final amplitudes = List.filled(100, -15.0);
      amplitudes[50] = -0.5; // Above -1.0 dBFS
      expect(
        AudioRecordingService.analyzeQuality(amplitudes),
        equals('clipping'),
      );
    });

    test('too_quiet takes priority over clipping', () {
      // If average is too quiet, that's the primary issue
      final amplitudes = List.filled(100, -50.0);
      amplitudes[50] = -0.5;
      expect(
        AudioRecordingService.analyzeQuality(amplitudes),
        equals('too_quiet'),
      );
    });

    test('returns null when average is exactly at silence boundary', () {
      // Average == -30 is NOT < -30, so should be null
      final amplitudes = List.filled(100, -30.0);
      expect(AudioRecordingService.analyzeQuality(amplitudes), isNull);
    });
  });

  group('AudioRecordingService.generateFilePath', () {
    test('generates path with correct prefix and extension', () {
      final path = AudioRecordingService.generateFilePath(
        '/test/dir',
        DateTime(2026, 4, 17, 10, 0),
      );
      expect(path, startsWith('/test/dir/${AudioConstants.filePrefix}'));
      expect(path, endsWith(AudioConstants.fileExtension));
    });

    test('includes timestamp in milliseconds', () {
      final now = DateTime(2026, 4, 17, 10, 0);
      final path = AudioRecordingService.generateFilePath('/dir', now);
      expect(path, contains(now.millisecondsSinceEpoch.toString()));
    });

    test('different timestamps produce different paths', () {
      final t1 = DateTime(2026, 4, 17, 10, 0);
      final t2 = DateTime(2026, 4, 17, 10, 1);
      final path1 = AudioRecordingService.generateFilePath('/dir', t1);
      final path2 = AudioRecordingService.generateFilePath('/dir', t2);
      expect(path1, isNot(equals(path2)));
    });
  });
}
