import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/user_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _tag = 'SettingsScreen';

  late final TextEditingController _landAreaController;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(settingsProvider).totalLandAcres;
    _landAreaController =
        TextEditingController(text: saved == null ? '' : saved.toString());
  }

  @override
  void dispose() {
    _landAreaController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(TamilStrings.clearHistoryConfirmTitle),
        content: const Text(TamilStrings.clearHistoryConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(TamilStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(TamilStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      await ref.read(queryHistoryDaoProvider).deleteAllForUser(userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.historyCleared)),
      );
    } catch (e, st) {
      AppLogger.error('Failed to clear history', _tag, e, st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    }
  }

  Future<void> _saveLandArea() async {
    final raw = _landAreaController.text.trim();
    final notifier = ref.read(settingsProvider.notifier);
    if (raw.isEmpty) {
      await notifier.setTotalLandAcres(null);
    } else {
      final n = double.tryParse(raw);
      if (n == null || n <= 0) return;
      await notifier.setTotalLandAcres(n);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(TamilStrings.ratingSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: const Text(TamilStrings.ttsSpeedLabel),
              subtitle: Slider(
                min: 0.8,
                max: 1.2,
                divisions: 2,
                value: settings.ttsSpeed,
                label: '${settings.ttsSpeed.toStringAsFixed(1)}x',
                onChanged: notifier.setTtsSpeed,
              ),
              trailing: Text('${settings.ttsSpeed.toStringAsFixed(1)}x'),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text(TamilStrings.notificationsLabel),
              value: settings.notificationsEnabled,
              onChanged: (enabled) async {
                await notifier.setNotificationsEnabled(enabled);
                // Re-arm or cancel scheduled reminders. Best-effort.
                try {
                  final userId =
                      await ref.read(currentUserIdProvider.future);
                  await ref
                      .read(cropReminderSchedulerProvider)
                      .rescheduleAll(userId);
                } catch (e, st) {
                  AppLogger.warning(
                    'Reschedule on toggle failed: $e\n$st',
                    _tag,
                  );
                }
              },
            ),
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TamilStrings.landAreaSetting,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    TamilStrings.landAreaHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _landAreaController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveLandArea,
                        child: const Text(TamilStrings.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text(TamilStrings.clearHistoryLabel),
              onTap: () => _confirmClearHistory(context),
            ),
            const Divider(height: 1),
            const _AboutTile(),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final info = snap.data;
        final subtitle = info == null
            ? '...'
            : '${TamilStrings.versionLabel}: ${info.version}+${info.buildNumber}';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text(TamilStrings.aboutLabel),
          subtitle: Text(subtitle),
        );
      },
    );
  }
}
