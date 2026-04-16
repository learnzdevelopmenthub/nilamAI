/// Audio recording configuration constants for NilamAI.
///
/// PCM 16-bit, 16 kHz, mono — optimized for Whisper STT ingestion.
class AudioConstants {
  AudioConstants._();

  // -- Recording config --
  static const int sampleRate = 16000;
  static const int numChannels = 1;
  static const int bitRate = 256000; // 16-bit * 16000 Hz

  // -- Duration constraints --
  static const int minDurationSeconds = 10;
  static const int maxDurationSeconds = 120;

  // -- Amplitude monitoring --
  static const int amplitudeIntervalMs = 33; // ~30 FPS
  static const int maxAmplitudeSamples = 150;

  // -- Audio quality thresholds (dBFS) --
  static const double silenceThresholdDb = -30.0;
  static const double clippingThresholdDb = -1.0;

  // -- Normalization range --
  static const double minDb = -60.0;
  static const double maxDb = 0.0;

  // -- File naming --
  static const String filePrefix = 'nilam_query_';
  static const String fileExtension = '.wav';
  static const String audioSubDir = 'audio';
}
