import 'package:flutter_tts/flutter_tts.dart';

import '../../core/logging/logger.dart';

/// Thin wrapper around `flutter_tts` for English read-aloud of AI answers.
///
/// Speech speed is controlled by [Settings] via [setRate]. Using the
/// device's default English voice keeps install size small.
class TtsService {
  TtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  static const _tag = 'TtsService';

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (e, st) {
      AppLogger.error('TTS init failed', _tag, e, st);
    }
  }

  Future<void> speak(String text, {double? speed}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _ensureReady();
    if (speed != null) {
      // flutter_tts speech rate: 0.0 (slowest) – 1.0 (fastest); 0.5 is the
      // platform's "normal". Map our 0.8x – 1.2x slider onto a usable range.
      final mapped = (0.30 + (speed - 0.5) * 0.4).clamp(0.20, 0.90);
      try {
        await _tts.setSpeechRate(mapped);
      } catch (e) {
        AppLogger.warning('TTS setSpeechRate failed: $e', _tag);
      }
    }
    try {
      await _tts.speak(clean);
    } catch (e, st) {
      AppLogger.error('TTS speak failed', _tag, e, st);
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Swallow — stopping when nothing is speaking is benign.
    }
  }
}
