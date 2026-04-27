import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/llm_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/crop_profile.dart';
import '../../services/database/models/query_history.dart';
import '../../services/llm/prompt_builder.dart';
import '../../services/retrieval/knowledge_chunk.dart';

/// English text-input screen that feeds the LLM. When [cropProfileId] is
/// supplied, the prompt is grounded with that crop's current stage and
/// agronomy notes from the bundled knowledge base.
class QueryInputScreen extends ConsumerStatefulWidget {
  const QueryInputScreen({this.cropProfileId, super.key});

  final String? cropProfileId;

  @override
  ConsumerState<QueryInputScreen> createState() => _QueryInputScreenState();
}

class _QueryInputScreenState extends ConsumerState<QueryInputScreen> {
  static const _tag = 'QueryInputScreen';

  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<({CropContext context, String cropId, String stageId})?>
      _resolveContext() async {
    final cropProfileId = widget.cropProfileId;
    if (cropProfileId == null) return null;
    try {
      final crop = await ref
          .read(cropProfileDaoProvider)
          .getById(cropProfileId);
      if (crop == null) return null;
      final kb = await ref.read(cropKnowledgeProvider.future);
      final tpl = kb.byId(crop.cropId);
      if (tpl == null) return null;
      final daysSince = crop.daysSinceSowing();
      final stage = tpl.stageForDay(daysSince);
      final ctx = CropContext(
        cropName: tpl.name,
        variety: crop.variety,
        stageName: stage.name,
        dayInStage: daysSince - stage.startDay + 1,
        totalDurationDays: tpl.totalDurationDays,
        keyActivities: stage.keyActivities,
        commonDiseases: stage.commonDiseases,
        recommendedFertilizer: stage.recommendedFertilizer,
      );
      return (context: ctx, cropId: crop.cropId, stageId: stage.id);
    } catch (e, st) {
      AppLogger.warning(
        'Failed to build crop context for $cropProfileId: $e\n$st',
        _tag,
      );
      return null;
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);
    try {
      final dao = ref.read(queryHistoryDaoProvider);
      final userId = await ref.read(currentUserIdProvider.future);
      final resolved = await _resolveContext();
      final cropContext = resolved?.context;

      // Sparse retrieval over crops.json + diseases.json, scoped to the
      // tracked crop+stage when available so off-topic chunks don't leak in.
      List<KnowledgeChunk> chunks = const [];
      try {
        final ranked = await ref.read(knowledgeRetrieverProvider).retrieve(
              query: text,
              cropId: resolved?.cropId,
              stageId: resolved?.stageId,
              topK: 4,
            );
        chunks = ranked.map((r) => r.chunk).toList(growable: false);
      } catch (e, st) {
        AppLogger.warning('Retrieval failed; continuing without RAG: $e\n$st',
            _tag);
      }

      final now = DateTime.now();
      final history = QueryHistory(
        id: const Uuid().v4(),
        userId: userId,
        timestamp: now,
        audioFilePath: null,
        transcription: text,
        transcriptionConfidence: null,
        createdAt: now,
        updatedAt: now,
      );
      await dao.insert(history);
      AppLogger.info('Text query saved (id=${history.id})', _tag);

      final gemma = ref.read(gemmaNotifierProvider.notifier);
      gemma.reset();
      unawaited(gemma.generate(
        query: text,
        cropContext: cropContext,
        cropType: cropContext?.cropName,
        retrieved: chunks.isEmpty
            ? null
            : RetrievedContext(chunks: chunks),
      ));

      if (!mounted) return;
      context.go('/response/${history.id}');
    } catch (e, st) {
      AppLogger.error('Failed to save query history', _tag, e, st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final canSubmit = text.isNotEmpty && !_saving;
    final asyncCrop = widget.cropProfileId == null
        ? null
        : ref.watch(cropProfileByIdProvider(widget.cropProfileId!));

    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.askQuestion)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (asyncCrop != null)
                asyncCrop.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (CropProfile? crop) {
                    if (crop == null) return const SizedBox.shrink();
                    return _CropContextChip(crop: crop);
                  },
                ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  autofocus: true,
                  textAlignVertical: TextAlignVertical.top,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    hintText: TamilStrings.queryInputHint,
                    contentPadding: EdgeInsets.all(16),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text(TamilStrings.confirm),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CropContextChip extends ConsumerWidget {
  const _CropContextChip({required this.crop});
  final CropProfile crop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncKb = ref.watch(cropKnowledgeProvider);
    final theme = Theme.of(context);
    return asyncKb.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (kb) {
        final tpl = kb.byId(crop.cropId);
        if (tpl == null) return const SizedBox.shrink();
        final daysSince = crop.daysSinceSowing();
        final stage = tpl.stageForDay(daysSince);
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.agriculture,
                  color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tpl.name} • ${stage.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
