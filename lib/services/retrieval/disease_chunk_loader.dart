import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'knowledge_chunk.dart';

/// Loads `assets/knowledge/diseases.json` and flattens each entry into one
/// retrieval chunk. Caches after the first call.
class DiseaseChunkLoader {
  DiseaseChunkLoader({this.assetPath = 'assets/knowledge/diseases.json'});

  final String assetPath;
  List<KnowledgeChunk>? _cache;

  Future<List<KnowledgeChunk>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entries = (decoded['diseases'] as List).cast<Map<String, dynamic>>();

    final chunks = <KnowledgeChunk>[];
    for (final e in entries) {
      final id = e['id'] as String;
      final name = e['name'] as String;
      final symptoms = (e['symptoms'] as String?) ?? '';
      final favourable = (e['favourable_conditions'] as String?) ?? '';
      final chemical = (e['treatment_chemical'] as String?) ?? '';
      final organic = (e['treatment_organic'] as String?) ?? '';
      final dosage = (e['dosage'] as String?) ?? '';
      final safety = (e['safety_precautions'] as String?) ?? '';
      final cropIds = (e['crops'] as List?)?.cast<String>() ?? const [];
      final stageIds = (e['stages'] as List?)?.cast<String>() ?? const [];
      final tags = <String>[
        'disease',
        if ((e['type'] as String?) != null) e['type'] as String,
        ...((e['tags'] as List?)?.cast<String>() ?? const <String>[]),
      ];

      final buf = StringBuffer()
        ..writeln('$name.')
        ..writeln('Symptoms: $symptoms')
        ..writeln('Favourable conditions: $favourable')
        ..writeln('Chemical control: $chemical')
        ..writeln('Organic alternative: $organic')
        ..writeln('Dosage: $dosage')
        ..writeln('Safety: $safety');

      // Append search keywords so sparse scoring picks up Latin pathogen
      // names and farmer-facing aliases that don't appear in the prose.
      final keywords =
          (e['search_keywords'] as List?)?.cast<String>() ?? const [];
      if (keywords.isNotEmpty) {
        buf.writeln('Keywords: ${keywords.join(', ')}');
      }

      chunks.add(KnowledgeChunk(
        id: 'disease/$id',
        text: buf.toString().trimRight(),
        cropIds: cropIds,
        stageIds: stageIds,
        tags: tags,
        sourceType: ChunkSource.disease,
        sourceId: id,
      ));
    }

    _cache = chunks;
    return chunks;
  }
}
