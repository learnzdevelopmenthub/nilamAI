import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/crop_profile.dart';
import '../../services/knowledge/crop_knowledge.dart';

class CropDetailScreen extends ConsumerWidget {
  const CropDetailScreen({required this.cropProfileId, super.key});

  final String cropProfileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCrop = ref.watch(cropProfileByIdProvider(cropProfileId));
    final asyncKb = ref.watch(cropKnowledgeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(TamilStrings.cropsTitle),
        actions: [
          IconButton(
            tooltip: TamilStrings.deleteCrop,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: asyncCrop.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text(TamilStrings.errorDatabase)),
          data: (crop) {
            if (crop == null) {
              return const Center(child: Text(TamilStrings.errorGeneral));
            }
            return asyncKb.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text(TamilStrings.errorGeneral)),
              data: (kb) {
                final tpl = kb.byId(crop.cropId);
                if (tpl == null) {
                  return const Center(
                      child: Text(TamilStrings.errorGeneral));
                }
                return _CropDetailBody(crop: crop, tpl: tpl);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(TamilStrings.deleteCrop),
        content: const Text(TamilStrings.deleteCropConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(TamilStrings.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(TamilStrings.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(cropProfileDaoProvider).delete(cropProfileId);
      final userId = await ref.read(currentUserIdProvider.future);
      ref.invalidate(userCropProfilesProvider(userId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.deleted)),
      );
      context.pop();
    } catch (e, st) {
      AppLogger.error('Failed to delete crop', 'CropDetailScreen', e, st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    }
  }
}

class _CropDetailBody extends StatelessWidget {
  const _CropDetailBody({required this.crop, required this.tpl});

  final CropProfile crop;
  final CropTemplate tpl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysSince = crop.daysSinceSowing();
    final stage = tpl.stageForDay(daysSince);
    final dayInStage = (daysSince - stage.startDay + 1).clamp(1, stage.durationDays);
    final daysLeft = tpl.totalDurationDays - daysSince;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tpl.name, style: theme.textTheme.headlineSmall),
                if (crop.variety != null && crop.variety!.isNotEmpty)
                  Text(
                    crop.variety!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  '${TamilStrings.sowingDate}: ${DateFormat.yMMMd().format(crop.sowingDate)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (crop.landAreaAcres != null)
                  Text(
                    '${TamilStrings.landAreaAcres}: ${crop.landAreaAcres}',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (crop.soilType != null)
                  Text(
                    '${TamilStrings.soilType}: ${crop.soilType}',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (crop.irrigationType != null)
                  Text(
                    '${TamilStrings.irrigationType}: ${crop.irrigationType}',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                Text(
                  daysLeft > 0
                      ? '${TamilStrings.daysToHarvest}: $daysLeft (of ${tpl.totalDurationDays})'
                      : TamilStrings.harvestExpected,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TamilStrings.currentStage,
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  '${stage.name} (day $dayInStage / ${stage.durationDays})',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _SectionTitle(text: TamilStrings.stageActivities),
                ...stage.keyActivities.map(_bullet),
                const SizedBox(height: 8),
                _SectionTitle(text: TamilStrings.stageDiseasesWatch),
                Text(stage.commonDiseases.join(', '),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                _SectionTitle(text: TamilStrings.stageFertilizer),
                Text(stage.recommendedFertilizer,
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(text: TamilStrings.topDiseases),
                ...tpl.topDiseases.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${d.name}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: d.symptoms),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
                _SectionTitle(text: TamilStrings.harvestIndicators),
                Text(tpl.harvestWindowIndicators,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                _SectionTitle(text: TamilStrings.storageTip),
                Text(tpl.storageTip, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () =>
              context.push('/ask?cropId=${crop.id}'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text(TamilStrings.askAboutThisCrop),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () =>
              context.push('/diagnose?cropId=${crop.id}'),
          icon: const Icon(Icons.medical_services_outlined),
          label: const Text(TamilStrings.diagnoseFromCrop),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String activity) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: Text(activity)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
