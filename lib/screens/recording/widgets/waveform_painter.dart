import 'package:flutter/material.dart';

import '../../../services/audio/audio_constants.dart';

/// Custom painter that draws vertical amplitude bars for waveform visualization.
///
/// Each bar is mirrored above and below the horizontal center line.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.amplitudes,
    required this.barColor,
  });

  final List<double> amplitudes;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final barCount = AudioConstants.maxAmplitudeSamples;
    final gap = 1.0;
    final barWidth = (size.width - (barCount - 1) * gap) / barCount;
    final centerY = size.height / 2;
    final maxBarHeight = size.height / 2;

    final paint = Paint()..strokeCap = StrokeCap.round;

    final startIndex =
        amplitudes.length > barCount ? amplitudes.length - barCount : 0;
    final visibleAmplitudes = amplitudes.sublist(startIndex);

    for (var i = 0; i < visibleAmplitudes.length; i++) {
      final amplitude = visibleAmplitudes[i];
      final barHeight = (amplitude * maxBarHeight).clamp(1.0, maxBarHeight);
      final x = i * (barWidth + gap) + barWidth / 2;

      paint.color = barColor.withValues(alpha: 0.4 + amplitude * 0.6);
      paint.strokeWidth = barWidth;

      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }

    // Draw center line.
    final linePaint = Paint()
      ..color = barColor.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return amplitudes.length != oldDelegate.amplitudes.length ||
        !identical(amplitudes, oldDelegate.amplitudes);
  }
}
