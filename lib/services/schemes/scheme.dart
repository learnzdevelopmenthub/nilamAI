// Domain model for a government agricultural scheme bundled in
// `assets/knowledge/schemes.json`.

enum SchemeType { incomeSupport, insurance, credit, advisory }

class Scheme {
  const Scheme({
    required this.id,
    required this.name,
    required this.type,
    required this.benefitSummary,
    required this.eligibilityCriteria,
    required this.applicationSteps,
    required this.applyUrl,
    this.maxLandAcresForEligibility,
  });

  final String id;
  final String name;
  final SchemeType type;
  final String benefitSummary;
  final List<String> eligibilityCriteria;
  final List<String> applicationSteps;
  final String applyUrl;
  final double? maxLandAcresForEligibility;

  factory Scheme.fromJson(Map<String, dynamic> j) => Scheme(
        id: j['id'] as String,
        name: j['name'] as String,
        type: _parseType(j['type'] as String),
        benefitSummary: j['benefit_summary'] as String,
        eligibilityCriteria:
            (j['eligibility_criteria'] as List).cast<String>(),
        applicationSteps: (j['application_steps'] as List).cast<String>(),
        applyUrl: j['apply_url'] as String,
        maxLandAcresForEligibility:
            (j['max_land_acres_for_eligibility'] as num?)?.toDouble(),
      );

  static SchemeType _parseType(String s) => switch (s) {
        'income_support' => SchemeType.incomeSupport,
        'insurance' => SchemeType.insurance,
        'credit' => SchemeType.credit,
        'advisory' => SchemeType.advisory,
        _ => throw ArgumentError('unknown scheme type: $s'),
      };

  /// Returns true when [totalLandAcres] is null (unknown — show all schemes
  /// as "check eligibility") or when the scheme has no land cap, or when
  /// the farmer's holding is at or below the cap.
  bool isEligibleFor(double? totalLandAcres) {
    final cap = maxLandAcresForEligibility;
    if (cap == null) return true;
    if (totalLandAcres == null) return true;
    return totalLandAcres <= cap;
  }
}
