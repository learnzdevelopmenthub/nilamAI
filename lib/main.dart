import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'core/logging/logger.dart';
import 'providers/database_providers.dart';
import 'services/database/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService.create();
  try {
    await dbService.initialize();
  } catch (e) {
    AppLogger.error('Database initialization failed', 'main', e);
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
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
