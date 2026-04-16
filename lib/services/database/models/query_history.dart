/// Immutable model representing a query history record stored in SQLite.
///
/// Each record captures a farmer's voice query, its transcription,
/// and the Gemma LLM response with associated metadata.
class QueryHistory {
  const QueryHistory({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.audioFilePath,
    required this.transcription,
    this.transcriptionConfidence,
    this.gemmaPrompt,
    this.gemmaResponse,
    this.gemmaLatencyMs,
    this.userRating,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime timestamp;
  final String? audioFilePath;
  final String transcription;
  final double? transcriptionConfidence;
  final String? gemmaPrompt;
  final String? gemmaResponse;
  final int? gemmaLatencyMs;
  final String? userRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory QueryHistory.fromMap(Map<String, dynamic> map) {
    return QueryHistory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      audioFilePath: map['audio_file_path'] as String?,
      transcription: map['transcription'] as String,
      transcriptionConfidence:
          (map['transcription_confidence'] as num?)?.toDouble(),
      gemmaPrompt: map['gemma_prompt'] as String?,
      gemmaResponse: map['gemma_response'] as String?,
      gemmaLatencyMs: map['gemma_latency_ms'] as int?,
      userRating: map['user_rating'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'audio_file_path': audioFilePath,
      'transcription': transcription,
      'transcription_confidence': transcriptionConfidence,
      'gemma_prompt': gemmaPrompt,
      'gemma_response': gemmaResponse,
      'gemma_latency_ms': gemmaLatencyMs,
      'user_rating': userRating,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  QueryHistory copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? audioFilePath,
    String? transcription,
    double? transcriptionConfidence,
    String? gemmaPrompt,
    String? gemmaResponse,
    int? gemmaLatencyMs,
    String? userRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueryHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      transcription: transcription ?? this.transcription,
      transcriptionConfidence:
          transcriptionConfidence ?? this.transcriptionConfidence,
      gemmaPrompt: gemmaPrompt ?? this.gemmaPrompt,
      gemmaResponse: gemmaResponse ?? this.gemmaResponse,
      gemmaLatencyMs: gemmaLatencyMs ?? this.gemmaLatencyMs,
      userRating: userRating ?? this.userRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryHistory &&
        other.id == id &&
        other.userId == userId &&
        other.timestamp == timestamp &&
        other.audioFilePath == audioFilePath &&
        other.transcription == transcription &&
        other.transcriptionConfidence == transcriptionConfidence &&
        other.gemmaPrompt == gemmaPrompt &&
        other.gemmaResponse == gemmaResponse &&
        other.gemmaLatencyMs == gemmaLatencyMs &&
        other.userRating == userRating &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        timestamp,
        audioFilePath,
        transcription,
        transcriptionConfidence,
        gemmaPrompt,
        gemmaResponse,
        gemmaLatencyMs,
        userRating,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'QueryHistory(id: $id, userId: $userId, timestamp: $timestamp)';
}
