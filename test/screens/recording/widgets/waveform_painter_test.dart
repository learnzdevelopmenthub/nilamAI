import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/screens/recording/widgets/waveform_painter.dart';

void main() {
  group('WaveformPainter', () {
    test('shouldRepaint returns true for different amplitude lists', () {
      final painter1 = WaveformPainter(
        amplitudes: const [0.1, 0.2],
        barColor: Colors.green,
      );
      final painter2 = WaveformPainter(
        amplitudes: const [0.1, 0.2, 0.3],
        barColor: Colors.green,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false for identical lists', () {
      final amplitudes = [0.1, 0.2, 0.3];
      final painter1 = WaveformPainter(
        amplitudes: amplitudes,
        barColor: Colors.green,
      );
      final painter2 = WaveformPainter(
        amplitudes: amplitudes,
        barColor: Colors.green,
      );
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true for non-identical same-length lists', () {
      final painter1 = WaveformPainter(
        amplitudes: [0.1, 0.2],
        barColor: Colors.green,
      );
      final painter2 = WaveformPainter(
        amplitudes: [0.1, 0.2],
        barColor: Colors.green,
      );
      // Non-const list instances are not identical
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('paint does not crash with empty amplitudes', () {
      final painter = WaveformPainter(
        amplitudes: const [],
        barColor: Colors.green,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 200);

      // Should complete without throwing.
      painter.paint(canvas, size);
      recorder.endRecording();
    });

    test('paint draws bars for non-empty amplitudes', () {
      final painter = WaveformPainter(
        amplitudes: const [0.5, 0.8, 0.3],
        barColor: Colors.green,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 200);

      // Should complete without throwing.
      painter.paint(canvas, size);
      recorder.endRecording();
    });
  });
}
