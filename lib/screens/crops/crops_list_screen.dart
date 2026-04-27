import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/strings_tamil.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/crop_profile.dart';
import '../../services/knowledge/crop_knowledge.dart';

/// Lists every crop the farmer is tracking. Each tile shows the current
/// growth stage computed from sowing-date + bundled knowledge JSON.
class CropsListScreen extends ConsumerWidget {
  const CropsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUserId = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.cropsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/crops/add'),
        icon: const Icon(Icons.add),
        label: const Text(TamilStrings.addCropTitle),
      ),
      body: SafeArea(
        child: asyncUserId.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text(TamilStrings.errorDatabase)),
          data: (userId) => _CropList(userId: userId),
        ),
      ),
    );
  }
}

class _CropList extends ConsumerWidget {
  const _CropList({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCrops = ref.watch(userCropProfilesProvider(userId));
    final asyncKb = ref.watch(cropKnowledgeProvider);
    return asyncCrops.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text(TamilStrings.errorDatabase)),
      data: (crops) {
        if (crops.isEmpty) return const _EmptyCrops();
        return asyncKb.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text(TamilStrings.errorGeneral)),
          data: (kb) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: crops.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _CropCard(crop: crops[i], kb: kb),
          ),
        );
      },
    );
  }
}

class _EmptyCrops extends StatelessWidget {
  const _EmptyCrops();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture,
                size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              TamilStrings.noCropsTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              TamilStrings.noCropsBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  GoRouter.of(context).push('/crops/add'),
              icon: const Icon(Icons.add),
              label: const Text(TamilStrings.addFirstCrop),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop, required this.kb});
  final CropProfile crop;
  final CropKnowledgeBase kb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tpl = kb.byId(crop.cropId);
    final daysSince = crop.daysSinceSowing();
    final stage = tpl?.stageForDay(daysSince);
    final progress = tpl == null
        ? 0.0
        : (daysSince / tpl.totalDurationDays).clamp(0.0, 1.0);
    final daysLeft = tpl == null ? null : tpl.totalDurationDays - daysSince;

    return Card(
      child: InkWell(
        onTap: () =>
            GoRouter.of(context).push('/crops/${crop.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      tpl?.name.substring(0, 1) ?? '?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tpl?.name ?? crop.cropId,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (crop.variety != null && crop.variety!.isNotEmpty)
                          Text(
                            crop.variety!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().format(crop.sowingDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (stage != null)
                Text(
                  '${TamilStrings.currentStage}: ${stage.name} '
                  '(${TamilStrings.dayOfStage} ${daysSince - stage.startDay + 1}/${stage.durationDays})',
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              if (daysLeft != null) ...[
                const SizedBox(height: 6),
                Text(
                  daysLeft > 0
                      ? '${TamilStrings.daysToHarvest}: $daysLeft'
                      : TamilStrings.harvestExpected,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
