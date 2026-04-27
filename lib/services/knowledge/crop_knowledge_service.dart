import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'crop_knowledge.dart';

/// Loads and caches the bundled crop knowledge JSON.
///
/// Single instance per app run; caches the parsed [CropKnowledgeBase] so
/// subsequent reads are zero-IO.
class CropKnowledgeService {
  CropKnowledgeService({this.assetPath = 'assets/knowledge/crops.json'});

  final String assetPath;
  CropKnowledgeBase? _cache;

  Future<CropKnowledgeBase> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(assetPath);
    final base = CropKnowledgeBase.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    _cache = base;
    return base;
  }

  Future<CropTemplate?> crop(String id) async {
    final base = await load();
    return base.byId(id);
  }

  Future<CropStage?> stageForDay(String cropId, int daysSinceSowing) async {
    final tpl = await crop(cropId);
    if (tpl == null) return null;
    return tpl.stageForDay(daysSinceSowing);
  }
}
