import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/user_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _tag = 'SettingsScreen';

  Future<void> _confirmClearHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
        SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              onChanged: notifier.setNotificationsEnabled,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text(TamilStrings.clearHistoryLabel),
              onTap: () => _confirmClearHistory(context, ref),
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
