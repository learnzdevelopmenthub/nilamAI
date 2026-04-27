// Domain models for the bundled crop knowledge base.
//
// The JSON shape is loaded from `assets/knowledge/crops.json`. These types
// are deliberately immutable and free of Flutter dependencies so they can
// be unit-tested without a widget binding.

class CropKnowledgeBase {
  const CropKnowledgeBase({
    required this.version,
    required this.language,
    required this.crops,
  });

  final int version;
  final String language;
  final List<CropTemplate> crops;

  factory CropKnowledgeBase.fromJson(Map<String, dynamic> j) {
    return CropKnowledgeBase(
      version: j['version'] as int,
      language: j['language'] as String,
      crops: (j['crops'] as List)
          .cast<Map<String, dynamic>>()
          .map(CropTemplate.fromJson)
          .toList(growable: false),
    );
  }

  CropTemplate? byId(String id) {
    for (final c in crops) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class CropTemplate {
  const CropTemplate({
    required this.id,
    required this.name,
    required this.varieties,
    required this.totalDurationDays,
    required this.stages,
    required this.topDiseases,
    required this.harvestWindowIndicators,
    required this.storageTip,
  });

  final String id;
  final String name;
  final List<String> varieties;
  final int totalDurationDays;
  final List<CropStage> stages;
  final List<DiseaseInfo> topDiseases;
  final String harvestWindowIndicators;
  final String storageTip;

  factory CropTemplate.fromJson(Map<String, dynamic> j) {
    return CropTemplate(
      id: j['id'] as String,
      name: j['name'] as String,
      varieties: (j['varieties'] as List).cast<String>(),
      totalDurationDays: j['total_duration_days'] as int,
      stages: (j['stages'] as List)
          .cast<Map<String, dynamic>>()
          .map(CropStage.fromJson)
          .toList(growable: false),
      topDiseases: (j['top_diseases'] as List)
          .cast<Map<String, dynamic>>()
          .map(DiseaseInfo.fromJson)
          .toList(growable: false),
      harvestWindowIndicators: j['harvest_window_indicators'] as String,
      storageTip: j['storage_tip'] as String,
    );
  }

  /// Returns the stage that owns [daysSinceSowing], or the last stage if
  /// [daysSinceSowing] exceeds [totalDurationDays].
  CropStage stageForDay(int daysSinceSowing) {
    if (daysSinceSowing < 0) return stages.first;
    for (final s in stages) {
      if (daysSinceSowing >= s.startDay && daysSinceSowing <= s.endDay) {
        return s;
      }
    }
    return stages.last;
  }
}

class CropStage {
  const CropStage({
    required this.id,
    required this.name,
    required this.startDay,
    required this.endDay,
    required this.keyActivities,
    required this.commonDiseases,
    required this.recommendedFertilizer,
  });

  final String id;
  final String name;
  final int startDay;
  final int endDay;
  final List<String> keyActivities;
  final List<String> commonDiseases;
  final String recommendedFertilizer;

  int get durationDays => endDay - startDay + 1;

  factory CropStage.fromJson(Map<String, dynamic> j) {
    return CropStage(
      id: j['id'] as String,
      name: j['name'] as String,
      startDay: j['start_day'] as int,
      endDay: j['end_day'] as int,
      keyActivities: (j['key_activities'] as List).cast<String>(),
      commonDiseases: (j['common_diseases'] as List).cast<String>(),
      recommendedFertilizer: j['recommended_fertilizer'] as String,
    );
  }
}

class DiseaseInfo {
  const DiseaseInfo({required this.name, required this.symptoms});

  final String name;
  final String symptoms;

  factory DiseaseInfo.fromJson(Map<String, dynamic> j) => DiseaseInfo(
        name: j['name'] as String,
        symptoms: j['symptoms'] as String,
      );
}
