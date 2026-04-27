import 'dart:math' as math;

import '../knowledge/crop_knowledge.dart';
import '../knowledge/crop_knowledge_service.dart';
import 'disease_chunk_loader.dart';
import 'knowledge_chunk.dart';
import 'knowledge_retriever.dart';
import 'tokenizer.dart';

/// Pre-tokenized doc with cached length and term-frequency map for BM25.
class _DocStats {
  _DocStats(this.tokens)
      : length = tokens.length,
        tf = _countTf(tokens);
  final List<String> tokens;
  final int length;
  final Map<String, int> tf;
  static Map<String, int> _countTf(List<String> ts) {
    final m = <String, int>{};
    for (final t in ts) {
      m[t] = (m[t] ?? 0) + 1;
    }
    return m;
  }
}

/// Standard Robertson/Spärck Jones BM25 with `k1=1.5`, `b=0.75`. IDF uses
/// the BM25+0.5 smoothing so a term in every doc never goes negative.
double _bm25(
  List<String> queryTokens,
  _DocStats doc,
  double avgDocLength,
  Map<String, double> idf, {
  double k1 = 1.5,
  double b = 0.75,
}) {
  if (queryTokens.isEmpty || doc.length == 0) return 0.0;
  final lenNorm = 1.0 - b + b * (doc.length / avgDocLength);
  double score = 0.0;
  for (final q in queryTokens) {
    final tf = doc.tf[q];
    if (tf == null) continue;
    final qIdf = idf[q];
    if (qIdf == null || qIdf == 0.0) continue;
    final num = tf * (k1 + 1);
    final den = tf + k1 * lenNorm;
    score += qIdf * (num / den);
  }
  return score;
}

/// Sparse BM25 retriever. Loads chunks from the bundled crop knowledge JSON
/// + the disease knowledge JSON on first call, pre-tokenizes once, and
/// scores in-memory thereafter.
class BM25Retriever implements KnowledgeRetriever {
  BM25Retriever({
    required CropKnowledgeService cropKnowledge,
    required DiseaseChunkLoader diseaseLoader,
    Tokenizer tokenizer = const Tokenizer(),
  })  : _cropKnowledge = cropKnowledge,
        _diseaseLoader = diseaseLoader,
        _tokenizer = tokenizer;

  final CropKnowledgeService _cropKnowledge;
  final DiseaseChunkLoader _diseaseLoader;
  final Tokenizer _tokenizer;

  Future<void>? _initFuture;
  late List<KnowledgeChunk> _chunks;
  late List<_DocStats> _docs;
  late Map<String, double> _idf;
  late double _avgDocLen;

  Future<void> _ensureReady() => _initFuture ??= _init();

  Future<void> _init() async {
    final base = await _cropKnowledge.load();
    final chunks = <KnowledgeChunk>[];
    chunks.addAll(_flattenCrops(base));
    chunks.addAll(await _diseaseLoader.load());

    final docs = chunks
        .map((c) => _DocStats(_tokenizer.tokenize(c.text)))
        .toList(growable: false);

    final n = docs.length;
    final df = <String, int>{};
    var totalLen = 0;
    for (final d in docs) {
      totalLen += d.length;
      for (final term in d.tf.keys) {
        df[term] = (df[term] ?? 0) + 1;
      }
    }
    final idf = <String, double>{};
    df.forEach((term, dfi) {
      idf[term] = math.log(1 + (n - dfi + 0.5) / (dfi + 0.5));
    });

    _chunks = chunks;
    _docs = docs;
    _idf = idf;
    _avgDocLen = n == 0 ? 1.0 : totalLen / n;
  }

  @override
  Future<List<RankedChunk>> retrieve({
    required String query,
    String? cropId,
    String? stageId,
    int topK = 5,
  }) async {
    await _ensureReady();
    final qTokens = _tokenizer.tokenize(query);
    if (qTokens.isEmpty) return const [];

    final scored = <RankedChunk>[];
    for (var i = 0; i < _chunks.length; i++) {
      final c = _chunks[i];
      if (cropId != null &&
          c.cropIds.isNotEmpty &&
          !c.cropIds.contains(cropId)) {
        continue;
      }
      if (stageId != null &&
          c.stageIds.isNotEmpty &&
          !c.stageIds.contains(stageId)) {
        continue;
      }
      final s = _bm25(qTokens, _docs[i], _avgDocLen, _idf);
      if (s > 0) scored.add(RankedChunk(chunk: c, score: s));
    }

    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.chunk.id.compareTo(b.chunk.id);
    });
    if (scored.length > topK) return scored.sublist(0, topK);
    return scored;
  }

  /// Flattens [base] into chunks: one per stage (with activities + diseases
  /// + fertilizer rolled in), one per top-disease entry, one harvest, one
  /// storage tip per crop.
  static List<KnowledgeChunk> _flattenCrops(CropKnowledgeBase base) {
    final out = <KnowledgeChunk>[];
    for (final tpl in base.crops) {
      for (final stage in tpl.stages) {
        final buf = StringBuffer()
          ..writeln(
            '${tpl.name} — ${stage.name} (days ${stage.startDay}-${stage.endDay}).',
          );
        if (stage.keyActivities.isNotEmpty) {
          buf.writeln('Activities: ${stage.keyActivities.join(' ')}');
        }
        if (stage.commonDiseases.isNotEmpty) {
          buf.writeln('Common problems: ${stage.commonDiseases.join(', ')}.');
        }
        if (stage.recommendedFertilizer.isNotEmpty) {
          buf.writeln('Fertilizer: ${stage.recommendedFertilizer}');
        }
        out.add(KnowledgeChunk(
          id: '${tpl.id}/stage/${stage.id}',
          text: buf.toString().trimRight(),
          cropIds: [tpl.id],
          stageIds: [stage.id],
          tags: const ['stage', 'activities', 'fertilizer', 'disease'],
          sourceType: ChunkSource.cropStage,
          sourceId: '${tpl.id}/${stage.id}',
        ));
      }
      for (final d in tpl.topDiseases) {
        out.add(KnowledgeChunk(
          id: '${tpl.id}/disease/${_slug(d.name)}',
          text: '${d.name} on ${tpl.name}: ${d.symptoms}',
          cropIds: [tpl.id],
          stageIds: const [],
          tags: const ['disease', 'symptom'],
          sourceType: ChunkSource.disease,
          sourceId: '${tpl.id}/${_slug(d.name)}',
        ));
      }
      out.add(KnowledgeChunk(
        id: '${tpl.id}/harvest',
        text:
            'Harvest indicators for ${tpl.name}: ${tpl.harvestWindowIndicators}',
        cropIds: [tpl.id],
        stageIds: const [],
        tags: const ['harvest'],
        sourceType: ChunkSource.cropHarvest,
        sourceId: '${tpl.id}/harvest',
      ));
      out.add(KnowledgeChunk(
        id: '${tpl.id}/storage',
        text: 'Storage tip for ${tpl.name}: ${tpl.storageTip}',
        cropIds: [tpl.id],
        stageIds: const [],
        tags: const ['storage', 'postharvest'],
        sourceType: ChunkSource.cropStorage,
        sourceId: '${tpl.id}/storage',
      ));
    }
    return out;
  }

  static String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
