import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../services/audio/audio_constants.dart';

/// Displays elapsed recording time as `M:SS / 2:00`.
///
/// Text turns red when elapsed exceeds the warning threshold (100s).
class RecordingTimer extends StatelessWidget {
  const RecordingTimer({
    super.key,
    required this.elapsed,
    this.maxSeconds = AudioConstants.maxDurationSeconds,
  });

  final Duration elapsed;
  final int maxSeconds;

  static const int _warningThresholdSeconds = 100;

  @override
  Widget build(BuildContext context) {
    final isWarning = elapsed.inSeconds >= _warningThresholdSeconds;
    final theme = Theme.of(context);

    return Text(
      '${_format(elapsed)} / ${_format(Duration(seconds: maxSeconds))}',
      style: theme.textTheme.headlineSmall?.copyWith(
        color: isWarning ? NilamTheme.redPrimary : NilamTheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
