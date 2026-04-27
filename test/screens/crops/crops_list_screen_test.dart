import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/screens/crops/crops_list_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/crop_profile.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/knowledge_test_helpers.dart';

GoRouter _router(List<String> visited) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const CropsListScreen()),
        GoRoute(
          path: '/crops/add',
          builder: (_, _) {
            visited.add('/crops/add');
            return const Scaffold(body: Text('ADD'));
          },
        ),
        GoRoute(
          path: '/crops/:id',
          builder: (_, state) {
            visited.add('/crops/${state.pathParameters['id']}');
            return const Scaffold(body: Text('DETAIL'));
          },
        ),
      ],
    );

Widget _app({
  required DatabaseService db,
  required TestKnowledge knowledge,
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      ...knowledge.overrides(),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // Drain real-async (asset bundle load, sqflite_ffi I/O) and fake-async
  // (Riverpod listeners, frame scheduling) repeatedly until stable.
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<String> _seedUser(DatabaseService db) async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  await db.userProfileDao.insert(UserProfile(
    id: id,
    phoneNumber: 'local_user_default',
    createdAt: now,
    updatedAt: now,
  ));
  return id;
}

CropProfile _crop({
  required String id,
  required String userId,
  required String cropId,
  String status = 'active',
  DateTime? sowing,
}) {
  final now = DateTime.now();
  return CropProfile(
    id: id,
    userId: userId,
    cropId: cropId,
    sowingDate: sowing ?? now.subtract(const Duration(days: 30)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late DatabaseService db;
  late TestKnowledge knowledge;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    knowledge = await TestKnowledge.load();
  });

  setUp(() async {
    db = DatabaseService.create();
    await db.initialize(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  group('CropsListScreen', () {
    testWidgets('empty state shows the first-crop CTA', (tester) async {
      await tester.runAsync(() => _seedUser(db));
      await tester.pumpWidget(_app(db: db, knowledge: knowledge, router: _router([])));
      await _settle(tester);

      expect(find.text(TamilStrings.noCropsTitle), findsOneWidget);
      expect(find.text(TamilStrings.addFirstCrop), findsOneWidget);
    });

    testWidgets('renders one card per crop row', (tester) async {
      final userId = await tester.runAsync(() => _seedUser(db));
      await tester.runAsync(() => db.cropProfileDao.insert(
            _crop(id: 'c1', userId: userId!, cropId: 'rice'),
          ));
      await tester.runAsync(() => db.cropProfileDao.insert(
            _crop(id: 'c2', userId: userId!, cropId: 'tomato'),
          ));

      await tester.pumpWidget(_app(db: db, knowledge: knowledge, router: _router([])));
      await _settle(tester);

      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
    });

    testWidgets('tapping FAB navigates to /crops/add', (tester) async {
      await tester.runAsync(() => _seedUser(db));
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, knowledge: knowledge, router: _router(visited)));
      await _settle(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await _settle(tester);

      expect(visited, contains('/crops/add'));
    });

    testWidgets('tapping a crop card navigates to /crops/:id', (tester) async {
      final userId = await tester.runAsync(() => _seedUser(db));
      await tester.runAsync(() => db.cropProfileDao.insert(
            _crop(id: 'crop-x', userId: userId!, cropId: 'rice'),
          ));
      final visited = <String>[];
      await tester.pumpWidget(_app(db: db, knowledge: knowledge, router: _router(visited)));
      await _settle(tester);

      await tester.tap(find.text('Rice'));
      await _settle(tester);

      expect(visited, contains('/crops/crop-x'));
    });
  });
}
