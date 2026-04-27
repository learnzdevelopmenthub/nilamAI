import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/feature_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/schemes/scheme.dart';

class SchemesScreen extends ConsumerWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final acres = ref.watch(settingsProvider).totalLandAcres;
    final asyncSchemes = ref.watch(matchedSchemesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.schemesTitle)),
      body: SafeArea(
        child: asyncSchemes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text(TamilStrings.errorGeneral)),
          data: (schemes) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                TamilStrings.schemesSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (acres == null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    TamilStrings.setLandAreaPrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (final s in schemes)
                _SchemeCard(scheme: s, declaredAcres: acres),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  const _SchemeCard({required this.scheme, required this.declaredAcres});

  final Scheme scheme;
  final double? declaredAcres;

  bool get _confidentlyEligible {
    if (declaredAcres == null) return false;
    final cap = scheme.maxLandAcresForEligibility;
    if (cap == null) return true;
    return declaredAcres! <= cap;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = _confidentlyEligible
        ? TamilStrings.eligibleBadge
        : TamilStrings.checkRequiredBadge;
    final badgeColor = _confidentlyEligible
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(scheme.name,
                      style: theme.textTheme.titleLarge),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section(theme, TamilStrings.benefitLabel, scheme.benefitSummary),
            const SizedBox(height: 8),
            _bulletSection(
                theme, TamilStrings.eligibilityLabel, scheme.eligibilityCriteria),
            const SizedBox(height: 8),
            _bulletSection(
                theme, TamilStrings.howToApply, scheme.applicationSteps),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(scheme.applyUrl);
                if (uri == null) return;
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e, st) {
                  AppLogger.error('Failed to open scheme URL', 'SchemesScreen',
                      e, st);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text(TamilStrings.openOfficialPortal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(ThemeData theme, String label, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      );

  Widget _bulletSection(ThemeData theme, String label, List<String> items) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              )),
          const SizedBox(height: 4),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(s, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      );
}
