import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/services/stt/whisper_stt_service.dart';

void main() {
  group('WhisperSttService.normalizeTranscription', () {
    test('returns empty string unchanged', () {
      expect(WhisperSttService.normalizeTranscription(''), equals(''));
    });

    test('trims surrounding whitespace', () {
      expect(
        WhisperSttService.normalizeTranscription('  நெல் பயிர்  '),
        equals('நெல் பயிர்'),
      );
    });

    test('collapses multiple internal spaces', () {
      expect(
        WhisperSttService.normalizeTranscription('நெல்\t பயிர்\n\nநோய்'),
        equals('நெல் பயிர் நோய்'),
      );
    });

    test('preserves Tamil characters', () {
      const input = 'நெல் பயிரில் மஞ்சள் புள்ளிகள் உள்ளன';
      expect(
        WhisperSttService.normalizeTranscription(input),
        equals(input),
      );
    });
  });

  group('WhisperSttService.validateAudioFile', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stt_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws SttException (E007) when path is empty', () {
      expect(
        () => WhisperSttService.validateAudioFile(''),
        throwsA(
          isA<SttException>().having((e) => e.code, 'code', 'E007'),
        ),
      );
    });

    test('throws SttException (E007) when extension is wrong', () async {
      final file = File('${tempDir.path}/audio.mp3')
        ..writeAsBytesSync(List.filled(2048, 0));
      expect(
        () => WhisperSttService.validateAudioFile(file.path),
        throwsA(
          isA<SttException>().having((e) => e.code, 'code', 'E007'),
        ),
      );
    });

    test('throws SttException (E007) when file missing', () {
      expect(
        () => WhisperSttService.validateAudioFile(
            '${tempDir.path}/does_not_exist.wav'),
        throwsA(
          isA<SttException>().having((e) => e.code, 'code', 'E007'),
        ),
      );
    });

    test('throws SttException (E007) when file is too small', () async {
      final file = File('${tempDir.path}/tiny.wav')
        ..writeAsBytesSync([1, 2, 3]);
      expect(
        () => WhisperSttService.validateAudioFile(file.path),
        throwsA(
          isA<SttException>().having((e) => e.code, 'code', 'E007'),
        ),
      );
    });

    test('accepts a valid .wav file of sufficient size', () async {
      final file = File('${tempDir.path}/ok.wav')
        ..writeAsBytesSync(List.filled(4096, 0));
      expect(
        () => WhisperSttService.validateAudioFile(file.path),
        returnsNormally,
      );
    });

    test('accepts uppercase .WAV extension', () async {
      final file = File('${tempDir.path}/ok.WAV')
        ..writeAsBytesSync(List.filled(4096, 0));
      expect(
        () => WhisperSttService.validateAudioFile(file.path),
        returnsNormally,
      );
    });
  });
}
