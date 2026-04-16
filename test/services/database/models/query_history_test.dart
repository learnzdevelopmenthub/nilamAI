import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/database/models/query_history.dart';

void main() {
  final now = DateTime(2026, 4, 17, 10, 0);

  QueryHistory createQuery({
    String id = 'query-uuid',
    String? gemmaResponse,
    double? transcriptionConfidence,
  }) {
    return QueryHistory(
      id: id,
      userId: 'user-uuid',
      timestamp: now,
      audioFilePath: '/audio/test.wav',
      transcription: 'நெல் விலை என்ன?',
      transcriptionConfidence: transcriptionConfidence,
      gemmaPrompt: 'What is the rice price?',
      gemmaResponse: gemmaResponse,
      gemmaLatencyMs: 350,
      userRating: 'helpful',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('QueryHistory', () {
    test('fromMap/toMap round-trips correctly', () {
      final original = createQuery(gemmaResponse: 'Rice price is ₹2000/quintal');
      final map = original.toMap();
      final restored = QueryHistory.fromMap(map);
      expect(restored, equals(original));
    });

    test('toMap stores DateTime as millisecondsSinceEpoch', () {
      final query = createQuery();
      final map = query.toMap();
      expect(map['timestamp'], equals(now.millisecondsSinceEpoch));
      expect(map['created_at'], equals(now.millisecondsSinceEpoch));
    });

    test('nullable fields survive round-trip as null', () {
      final query = QueryHistory(
        id: 'q-null',
        userId: 'user-uuid',
        timestamp: now,
        transcription: 'test',
        createdAt: now,
        updatedAt: now,
      );
      final map = query.toMap();
      final restored = QueryHistory.fromMap(map);

      expect(restored.audioFilePath, isNull);
      expect(restored.transcriptionConfidence, isNull);
      expect(restored.gemmaPrompt, isNull);
      expect(restored.gemmaResponse, isNull);
      expect(restored.gemmaLatencyMs, isNull);
      expect(restored.userRating, isNull);
      expect(restored, equals(query));
    });

    test('copyWith produces new instance with changed field', () {
      final original = createQuery();
      final copy = original.copyWith(gemmaResponse: 'Updated response');
      expect(copy.gemmaResponse, equals('Updated response'));
      expect(copy.id, equals(original.id));
    });

    test('equality compares all fields', () {
      final a = createQuery(gemmaResponse: 'response');
      final b = createQuery(gemmaResponse: 'response');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ', () {
      final a = createQuery(id: 'q-1');
      final b = createQuery(id: 'q-2');
      expect(a, isNot(equals(b)));
    });

    test('toString includes id, userId, and timestamp', () {
      final query = createQuery();
      final str = query.toString();
      expect(str, contains('query-uuid'));
      expect(str, contains('user-uuid'));
    });
  });
}
