import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recording/recording_screen.dart';
import '../screens/response/response_screen.dart';
import '../screens/settings/settings_screen.dart';
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
    GoRoute(
      path: '/response/:queryId',
      name: 'response',
      builder: (BuildContext context, GoRouterState state) {
        return ResponseScreen(
          queryId: state.pathParameters['queryId']!,
        );
      },
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (BuildContext context, GoRouterState state) {
        return const HistoryScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
  ],
);
