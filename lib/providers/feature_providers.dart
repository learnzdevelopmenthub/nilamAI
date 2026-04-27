import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/diagnosis/diagnosis_service.dart';
import '../services/knowledge/crop_knowledge.dart';
import '../services/knowledge/crop_knowledge_service.dart';
import '../services/market/market_service.dart';
import '../services/schemes/scheme.dart';
import '../services/schemes/scheme_service.dart';
import '../services/tts/tts_service.dart';
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
