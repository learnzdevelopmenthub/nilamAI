import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'core/logging/logger.dart';
import 'providers/database_providers.dart';
import 'providers/settings_providers.dart';
import 'services/database/database_service.dart';

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

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NilamAIApp(),
    ),
  );
}

class NilamAIApp extends StatelessWidget {
  const NilamAIApp({super.key});

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
