import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: NilamAIApp(),
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
