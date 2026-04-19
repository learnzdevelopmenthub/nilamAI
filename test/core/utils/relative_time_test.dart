import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/core/utils/relative_time.dart';

void main() {
  final now = DateTime(2026, 4, 19, 12, 0, 0);

  group('formatRelativeTamil', () {
    test('<60s returns "now"', () {
      expect(
        formatRelativeTamil(now.subtract(const Duration(seconds: 30)),
            now: now),
        equals('இப்போது'),
      );
    });

    test('minutes bucket', () {
      expect(
        formatRelativeTamil(now.subtract(const Duration(minutes: 5)), now: now),
        equals('5 நிமிடம் முன்பு'),
      );
    });

    test('hours bucket', () {
      expect(
        formatRelativeTamil(now.subtract(const Duration(hours: 4)), now: now),
        equals('4 மணி நேரம் முன்பு'),
      );
    });

    test('days bucket', () {
      expect(
        formatRelativeTamil(now.subtract(const Duration(days: 3)), now: now),
        equals('3 நாள் முன்பு'),
      );
    });

    test('>=7d falls back to absolute date', () {
      final old = DateTime(2025, 12, 1);
      expect(formatRelativeTamil(old, now: now), equals('01/12/2025'));
    });
  });
}
