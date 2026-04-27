import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/crops/add_crop_screen.dart';
import '../screens/crops/crop_detail_screen.dart';
import '../screens/diagnose/diagnose_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/query/query_input_screen.dart';
import '../screens/response/response_screen.dart';
import '../screens/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const MainScaffold();
      },
    ),
    GoRoute(
      path: '/ask',
      name: 'ask',
      builder: (BuildContext context, GoRouterState state) {
        final cropId = state.uri.queryParameters['cropId'];
        return QueryInputScreen(cropProfileId: cropId);
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
    GoRoute(
      path: '/crops/add',
      name: 'crops-add',
      builder: (BuildContext context, GoRouterState state) {
        return const AddCropScreen();
      },
    ),
    GoRoute(
      path: '/crops/:cropId',
      name: 'crop-detail',
      builder: (BuildContext context, GoRouterState state) {
        return CropDetailScreen(
          cropProfileId: state.pathParameters['cropId']!,
        );
      },
    ),
    GoRoute(
      path: '/diagnose',
      name: 'diagnose-pushed',
      builder: (BuildContext context, GoRouterState state) {
        return DiagnoseScreen(
          preselectedCropProfileId: state.uri.queryParameters['cropId'],
        );
      },
    ),
  ],
);
