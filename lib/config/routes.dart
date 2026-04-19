import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/strings_tamil.dart';
import '../screens/recording/recording_screen.dart';
import '../screens/transcription/transcribing_screen.dart';
import '../screens/transcription/transcription_review_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/record',
      name: 'record',
      builder: (BuildContext context, GoRouterState state) {
        return const RecordingScreen();
      },
    ),
    GoRoute(
      path: '/transcribe',
      name: 'transcribe',
      builder: (BuildContext context, GoRouterState state) {
        final audioPath = state.uri.queryParameters['audioPath'] ?? '';
        return TranscribingScreen(audioPath: audioPath);
      },
    ),
    GoRoute(
      path: '/review',
      name: 'review',
      builder: (BuildContext context, GoRouterState state) {
        final audioPath = state.uri.queryParameters['audioPath'] ?? '';
        final initialText = state.uri.queryParameters['text'] ?? '';
        return TranscriptionReviewScreen(
          audioPath: audioPath,
          initialText: initialText,
        );
      },
    ),
  ],
);

/// Temporary home screen for Phase 1 verification.
/// Will be replaced by the actual home screen in Phase 5a.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NilamAI'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              TamilStrings.appName,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${TamilStrings.greeting} ${TamilStrings.appTagline}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/record'),
        tooltip: TamilStrings.record,
        child: const Icon(Icons.mic),
      ),
    );
  }
}
