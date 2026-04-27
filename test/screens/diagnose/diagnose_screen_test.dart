import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/database_providers.dart';
import 'package:nilam_ai/providers/feature_providers.dart';
import 'package:nilam_ai/screens/diagnose/diagnose_screen.dart';
import 'package:nilam_ai/services/database/database_service.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';
import 'package:nilam_ai/services/diagnosis/diagnosis_models.dart';
import 'package:nilam_ai/services/diagnosis/diagnosis_service.dart';
import 'package:nilam_ai/services/retrieval/knowledge_chunk.dart';
import 'package:nilam_ai/services/retrieval/knowledge_retriever.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/knowledge_test_helpers.dart';

class _NoopRetriever implements KnowledgeRetriever {
  @override
  Future<List<RankedChunk>> retrieve({
    required String query,
    String? cropId,
    String? stageId,
    int topK = 5,
  }) async => const [];
}

class _FakeDiagnosisService implements DiagnosisService {
  _FakeDiagnosisService({this.result});
  final DiagnosisResult? result;
  int calls = 0;

  @override
  Future<DiagnosisResult> diagnose(
    DiagnosisRequest req, {
    List<KnowledgeChunk> retrievedChunks = const [],
  }) async {
    calls++;
    return result!;
  }
}

GoRouter _router() => GoRouter(
      initialLocation: '/diagnose',
      routes: [
        GoRoute(
          path: '/diagnose',
          builder: (_, _) => const DiagnoseScreen(),
        ),
      ],
    );

Widget _app({
  required DatabaseService db,
  required TestKnowledge knowledge,
  _FakeDiagnosisService? diagnosis,
}) {
  return ProviderScope(
    overrides: [
      databaseServiceProvider.overrideWithValue(db),
      knowledgeRetrieverProvider.overrideWithValue(_NoopRetriever()),
      ...knowledge.overrides(),
      if (diagnosis != null)
        diagnosisServiceProvider.overrideWithValue(diagnosis),
    ],
    child: MaterialApp.router(routerConfig: _router()),
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

  group('DiagnoseScreen', () {
    testWidgets('renders empty-state guidance', (tester) async {
      await tester.runAsync(() => _seedUser(db));
      await tester.pumpWidget(_app(db: db, knowledge: knowledge));
      await _settle(tester);

      expect(find.text(TamilStrings.diagnoseEmptyState), findsOneWidget);
    });

    testWidgets('run with no input shows snackbar', (tester) async {
      await tester.runAsync(() => _seedUser(db));
      await tester.pumpWidget(_app(db: db, knowledge: knowledge));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.runDiagnosis));
      await tester.pump();

      expect(
        find.text(TamilStrings.diagnoseInputRequired),
        findsOneWidget,
      );
    });

    testWidgets('symptoms + run shows result card with high confidence',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.runAsync(() => _seedUser(db));
      final fake = _FakeDiagnosisService(
        result: const DiagnosisResult(
          diseaseName: 'Leaf Blast',
          confidence: DiagnosisConfidence.high,
          cause: 'Magnaporthe oryzae',
          symptoms: 'diamond grey lesions',
          treatmentChemical: 'Tricyclazole 75% WP',
          treatmentOrganic: 'Pseudomonas spray',
          dosage: '0.6 g/L',
          safetyPrecautions: 'PPE; PHI 14 days',
          rawText: 'raw',
        ),
      );
      await tester.pumpWidget(_app(db: db, knowledge: knowledge, diagnosis: fake));
      await _settle(tester);

      await tester.enterText(
        find.byType(TextField).last,
        'leaves yellow with diamond marks',
      );
      await _settle(tester);
      await tester.tap(find.text(TamilStrings.runDiagnosis));
      await _settle(tester);

      expect(fake.calls, equals(1));
      expect(find.text(TamilStrings.diagnosisResultTitle), findsOneWidget);
      expect(find.text('Leaf Blast'), findsOneWidget);
      expect(find.text(TamilStrings.confidenceHigh), findsOneWidget);
    });

    testWidgets('low-confidence result renders the advisory banner',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.runAsync(() => _seedUser(db));
      final fake = _FakeDiagnosisService(
        result: const DiagnosisResult(
          diseaseName: 'Unknown',
          confidence: DiagnosisConfidence.low,
          cause: '',
          symptoms: 'unclear',
          treatmentChemical: '',
          treatmentOrganic: '',
          dosage: '',
          safetyPrecautions: 'consult officer',
          rawText: 'raw',
        ),
      );
      await tester.pumpWidget(_app(db: db, knowledge: knowledge, diagnosis: fake));
      await _settle(tester);

      await tester.enterText(find.byType(TextField).last, 'something is wrong');
      await _settle(tester);
      await tester.tap(find.text(TamilStrings.runDiagnosis));
      await _settle(tester);

      expect(find.text(TamilStrings.confidenceLow), findsOneWidget);
      expect(
        find.text(TamilStrings.diagnoseLowConfidenceAdvice),
        findsOneWidget,
      );
    });
  });
}
