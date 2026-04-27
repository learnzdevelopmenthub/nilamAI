import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilam_ai/providers/feature_providers.dart';
import 'package:nilam_ai/services/knowledge/crop_knowledge.dart';
import 'package:nilam_ai/services/knowledge/crop_knowledge_service.dart';
import 'package:nilam_ai/services/schemes/scheme.dart';
import 'package:nilam_ai/services/schemes/scheme_service.dart';

/// Pre-loads `assets/knowledge/*.json` from `rootBundle` and parses them into
/// in-memory objects. Tests use the returned overrides to skip the live
/// FutureProvider race that otherwise flakes in batch test runs.
class TestKnowledge {
  TestKnowledge._({required this.crops, required this.schemes});

  final CropKnowledgeBase crops;
  final List<Scheme> schemes;

  static Future<TestKnowledge> load() async {
    final cropsRaw =
        await rootBundle.loadString('assets/knowledge/crops.json');
    final schemesRaw =
        await rootBundle.loadString('assets/knowledge/schemes.json');
    final crops = CropKnowledgeBase.fromJson(
      jsonDecode(cropsRaw) as Map<String, dynamic>,
    );
    final schemesList = (jsonDecode(schemesRaw)['schemes'] as List)
        .cast<Map<String, dynamic>>()
        .map(Scheme.fromJson)
        .toList(growable: false);
    return TestKnowledge._(crops: crops, schemes: schemesList);
  }

  /// Riverpod overrides that hand the pre-parsed knowledge to consumers
  /// without any asset I/O at run time.
  List<Override> overrides() {
    return [
      cropKnowledgeServiceProvider
          .overrideWithValue(_StubCropKnowledgeService(crops)),
      schemeServiceProvider.overrideWithValue(_StubSchemeService(schemes)),
    ];
  }
}

class _StubCropKnowledgeService extends CropKnowledgeService {
  _StubCropKnowledgeService(this._base);
  final CropKnowledgeBase _base;

  @override
  Future<CropKnowledgeBase> load() async => _base;

  @override
  Future<CropTemplate?> crop(String id) async => _base.byId(id);

  @override
  Future<CropStage?> stageForDay(String cropId, int daysSinceSowing) async {
    final tpl = _base.byId(cropId);
    return tpl?.stageForDay(daysSinceSowing);
  }
}

class _StubSchemeService extends SchemeService {
  _StubSchemeService(this._all);
  final List<Scheme> _all;

  @override
  Future<List<Scheme>> loadAll() async => _all;

  @override
  Future<List<Scheme>> matchFor({double? totalLandAcres}) async =>
      _all.where((s) => s.isEligibleFor(totalLandAcres)).toList();
}
