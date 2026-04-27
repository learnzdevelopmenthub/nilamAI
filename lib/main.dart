import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'core/logging/logger.dart';
import 'providers/database_providers.dart';
import 'providers/feature_providers.dart';
import 'providers/settings_providers.dart';
import 'providers/user_providers.dart';
import 'services/database/database_service.dart';
import 'services/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    AppLogger.error('.env load failed — continuing with empty env', 'main', e);
  }

  final dbService = DatabaseService.create();
  try {
    await dbService.initialize();
  } catch (e) {
    AppLogger.error('Database initialization failed', 'main', e);
  }

  final prefs = await SharedPreferences.getInstance();

  final notifications = NotificationService();
  await notifications.initialize();
  // Permission request runs in the background — first launch surfaces the
  // system dialog without blocking app start.
  // ignore: unawaited_futures
  notifications.requestPermission();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const NilamAIApp(),
    ),
  );
}

class NilamAIApp extends ConsumerStatefulWidget {
  const NilamAIApp({super.key});

  @override
  ConsumerState<NilamAIApp> createState() => _NilamAIAppState();
}

class _NilamAIAppState extends ConsumerState<NilamAIApp> {
  @override
  void initState() {
    super.initState();
    // Re-arm any reminders the OS may have lost (boot, force-stop, etc.) once
    // the user is bootstrapped and Riverpod is fully wired.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userId = await ref.read(currentUserIdProvider.future);
        await ref
            .read(cropReminderSchedulerProvider)
            .rescheduleAll(userId);
      } catch (e, st) {
        AppLogger.warning('Cold-start reminder rearm failed: $e\n$st', 'main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NilamAI',
      debugShowCheckedModeBanner: false,
      theme: NilamTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
