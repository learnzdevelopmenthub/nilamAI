import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/feature_providers.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:nilam_ai/screens/crops/crop_detail_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/crop_profile.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:nilam_ai/services/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/knowledge_test_helpers.dart';

class _NoopNotificationService extends NotificationService {
  _NoopNotificationService() : super(FlutterLocalNotificationsPlugin());
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleStageReminder({
    required String cropId,
    required String stageId,
    required DateTime scheduledFor,
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> cancelForCrop(String cropId) async {}
  @override
  Future<void> cancelAll() async {}
}

GoRouter _router(String cropId, List<String> visited) => GoRouter(
      initialLocation: '/crops/$cropId',
      routes: [
        GoRoute(
          path: '/crops/:id',
          builder: (_, state) => CropDetailScreen(
            cropProfileId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) {
            visited.add('/');
            return const Scaffold(body: Text('LIST'));
          },
        ),
        GoRoute(
          path: '/ask',
          builder: (_, state) {
            visited.add('/ask?cropId=${state.uri.queryParameters['cropId']}');
            return const Scaffold(body: Text('ASK'));
          },
        ),
      ],
    );

Widget _app({
  required DatabaseService db,
  required SharedPreferences prefs,
  required TestKnowledge knowledge,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
      ...knowledge.overrides(),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<String> _seedRice(DatabaseService db) async {
  final userId = const Uuid().v4();
  final now = DateTime.now();
  await db.userProfileDao.insert(UserProfile(
    id: userId,
    phoneNumber: 'local_user_default',
    createdAt: now,
    updatedAt: now,
  ));
  await db.cropProfileDao.insert(CropProfile(
    id: 'rice-1',
    userId: userId,
    cropId: 'rice',
    sowingDate: DateTime.now().subtract(const Duration(days: 40)),
    createdAt: now,
    updatedAt: now,
  ));
  return 'rice-1';
}

void main() {
  late DatabaseService db;
  late SharedPreferences prefs;
  late TestKnowledge knowledge;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    knowledge = await TestKnowledge.load();
  });

  setUp(() async {
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('CropDetailScreen', () {
    testWidgets('renders name and current-stage section', (tester) async {
      final id = await tester.runAsync(() => _seedRice(db));
      await tester.pumpWidget(
          _app(db: db, prefs: prefs, knowledge: knowledge, router: _router(id!, [])));
      await _settle(tester);

      expect(find.text('Rice'), findsOneWidget);
      expect(find.textContaining('Active Tillering'), findsOneWidget);
      expect(find.text(TamilStrings.stageActivities), findsOneWidget);
      expect(find.text(TamilStrings.stageDiseasesWatch), findsOneWidget);
      expect(find.text(TamilStrings.stageFertilizer), findsOneWidget);
    });

    testWidgets('delete confirm pops route and removes the row',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final id = await tester.runAsync(() => _seedRice(db));
      final visited = <String>[];
      await tester.pumpWidget(
          _app(db: db, prefs: prefs, knowledge: knowledge, router: _router(id!, visited)));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await _settle(tester);
      await tester.tap(find.text(TamilStrings.delete));
      await _settle(tester);

      final remaining =
          await tester.runAsync(() => db.cropProfileDao.getById(id));
      expect(remaining, isNull);
      expect(visited, contains('/'));
    });

    testWidgets('Ask CTA pushes /ask?cropId=:id', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final id = await tester.runAsync(() => _seedRice(db));
      final visited = <String>[];
      await tester.pumpWidget(
          _app(db: db, prefs: prefs, knowledge: knowledge, router: _router(id!, visited)));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.askAboutThisCrop));
      await _settle(tester);

      expect(visited.any((p) => p.startsWith('/ask?cropId=rice-1')), isTrue);
    });
  });
}
