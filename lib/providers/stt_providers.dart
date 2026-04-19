import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/exceptions/app_exception.dart';
import '../core/logging/logger.dart';
import '../services/stt/whisper_model_loader.dart';
import '../services/stt/whisper_stt_service.dart';

// -----------------------------------------------------------------------------
// Sealed STT state
// -----------------------------------------------------------------------------

sealed class SttState {
  const SttState();
}

class SttIdle extends SttState {
  const SttIdle();
}

class SttLoadingModel extends SttState {
  const SttLoadingModel();
}

class SttTranscribing extends SttState {
  const SttTranscribing();
}

class SttComplete extends SttState {
  const SttComplete({required this.text, required this.audioPath});

  final String text;
  final String audioPath;
}

class SttError extends SttState {
  const SttError({required this.code, required this.message});

  final String code;
  final String message;
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final whisperModelLoaderProvider = Provider<WhisperModelLoader>((ref) {
  return WhisperModelLoader();
});

final whisperTranscriberProvider = Provider<WhisperTranscriber>((ref) {
  return const WhisperGgmlTranscriber();
});

final whisperSttServiceProvider = Provider<WhisperSttService>((ref) {
  return WhisperSttService(
    loader: ref.watch(whisperModelLoaderProvider),
    transcriber: ref.watch(whisperTranscriberProvider),
  );
});

final sttNotifierProvider =
    NotifierProvider<SttNotifier, SttState>(SttNotifier.new);

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class SttNotifier extends Notifier<SttState> {
  static const _tag = 'SttNotifier';

  @override
  SttState build() => const SttIdle();

  WhisperSttService get _service => ref.read(whisperSttServiceProvider);

  /// Kicks off a full transcription: LoadingModel → Transcribing → Complete/Error.
  Future<void> transcribe(String audioPath) async {
    state = const SttLoadingModel();
    AppLogger.info('STT started for $audioPath', _tag);

    // Give the UI a frame to render the "loading model" state before we start
    // the heavy work (asset copy on first launch).
    await Future<void>.delayed(Duration.zero);

    state = const SttTranscribing();
    try {
      final result = await _service.transcribe(audioPath);
      state = SttComplete(text: result.text, audioPath: audioPath);
      AppLogger.info('STT complete: "${result.text}"', _tag);
    } on SttException catch (e, st) {
      AppLogger.error('STT failed (${e.code})', _tag, e, st);
      state = SttError(code: e.code, message: e.message);
    } catch (e, st) {
      AppLogger.error('STT unexpected failure', _tag, e, st);
      state = SttError(code: 'E007', message: e.toString());
    }
  }

  void reset() {
    state = const SttIdle();
  }
}
