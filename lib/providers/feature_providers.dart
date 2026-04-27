import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/diagnosis/diagnosis_service.dart';
import '../services/knowledge/crop_knowledge.dart';
import '../services/knowledge/crop_knowledge_service.dart';
import '../services/market/market_service.dart';
import '../services/notifications/crop_reminder_scheduler.dart';
import '../services/notifications/notification_service.dart';
import '../services/retrieval/bm25_retriever.dart';
import '../services/retrieval/disease_chunk_loader.dart';
import '../services/retrieval/knowledge_retriever.dart';
import '../services/schemes/scheme.dart';
import '../services/schemes/scheme_service.dart';
import '../services/tts/tts_service.dart';
import 'database_providers.dart';
import 'llm_providers.dart';
import 'settings_providers.dart';

// -----------------------------------------------------------------------------
// Crop knowledge (bundled JSON)
// -----------------------------------------------------------------------------

final cropKnowledgeServiceProvider = Provider<CropKnowledgeService>((ref) {
  return CropKnowledgeService();
});

final cropKnowledgeProvider = FutureProvider<CropKnowledgeBase>((ref) async {
  return ref.watch(cropKnowledgeServiceProvider).load();
});

// -----------------------------------------------------------------------------
// Government schemes (bundled JSON + matching against settings.totalLandAcres)
// -----------------------------------------------------------------------------

final schemeServiceProvider = Provider<SchemeService>((ref) {
  return SchemeService();
});

final allSchemesProvider = FutureProvider<List<Scheme>>((ref) async {
  return ref.watch(schemeServiceProvider).loadAll();
});

/// Schemes matched against the farmer's declared land area (set in
/// Settings → "Land area"). When unset, every scheme is shown with the
/// "Check eligibility" badge.
final matchedSchemesProvider = FutureProvider<List<Scheme>>((ref) async {
  final acres = ref.watch(settingsProvider).totalLandAcres;
  return ref.watch(schemeServiceProvider).matchFor(totalLandAcres: acres);
});

// -----------------------------------------------------------------------------
// Disease diagnosis
// -----------------------------------------------------------------------------

final diagnosisServiceProvider = Provider<DiagnosisService>((ref) {
  return DiagnosisService(ref.watch(gemmaServiceProvider));
});

// -----------------------------------------------------------------------------
// Market prices
// -----------------------------------------------------------------------------

final marketServiceProvider = Provider<MarketService>((ref) {
  return MarketService();
});

// -----------------------------------------------------------------------------
// Text-to-speech
// -----------------------------------------------------------------------------

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

// -----------------------------------------------------------------------------
// Knowledge retrieval (BM25 today; vector retriever drops in via override).
// -----------------------------------------------------------------------------

final diseaseChunkLoaderProvider = Provider<DiseaseChunkLoader>((ref) {
  return DiseaseChunkLoader();
});

final knowledgeRetrieverProvider = Provider<KnowledgeRetriever>((ref) {
  return BM25Retriever(
    cropKnowledge: ref.watch(cropKnowledgeServiceProvider),
    diseaseLoader: ref.watch(diseaseChunkLoaderProvider),
  );
});

// -----------------------------------------------------------------------------
// Local notifications (overridden in main.dart after initialize()).
// -----------------------------------------------------------------------------

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main() with an '
    'initialized NotificationService',
  );
});

final cropReminderSchedulerProvider =
    Provider<CropReminderScheduler>((ref) {
  return CropReminderScheduler(
    notifications: ref.watch(notificationServiceProvider),
    knowledgeService: ref.watch(cropKnowledgeServiceProvider),
    cropDao: ref.watch(cropProfileDaoProvider),
    notificationsEnabled: () =>
        ref.read(settingsProvider).notificationsEnabled,
  );
});
