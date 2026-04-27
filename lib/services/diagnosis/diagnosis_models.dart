// Domain models for the disease-diagnosis feature.

enum DiagnosisConfidence { high, medium, low }

class DiagnosisRequest {
  const DiagnosisRequest({
    this.cropId,
    this.cropName,
    this.stageName,
    this.dayInStage,
    this.imageBytes,
    this.imageMimeType = 'image/jpeg',
    this.symptomsText,
  });

  final String? cropId;
  final String? cropName;
  final String? stageName;
  final int? dayInStage;
  final List<int>? imageBytes;
  final String imageMimeType;
  final String? symptomsText;

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;
  bool get hasSymptoms =>
      symptomsText != null && symptomsText!.trim().isNotEmpty;
  bool get isValid => hasImage || hasSymptoms;
}

class DiagnosisResult {
  const DiagnosisResult({
    required this.diseaseName,
    required this.confidence,
    required this.cause,
    required this.symptoms,
    required this.treatmentChemical,
    required this.treatmentOrganic,
    required this.dosage,
    required this.safetyPrecautions,
    required this.rawText,
  });

  final String diseaseName;
  final DiagnosisConfidence confidence;
  final String cause;
  final String symptoms;
  final String treatmentChemical;
  final String treatmentOrganic;
  final String dosage;
  final String safetyPrecautions;
  final String rawText;

  /// Used when JSON parsing fails — surfaces the raw text to the user with
  /// a low-confidence banner.
  factory DiagnosisResult.lowConfidenceFallback(String raw) => DiagnosisResult(
        diseaseName: 'Unknown',
        confidence: DiagnosisConfidence.low,
        cause: '',
        symptoms: raw.trim(),
        treatmentChemical: '',
        treatmentOrganic: '',
        dosage: '',
        safetyPrecautions:
            'Could not parse the AI output. Treat this as a low-confidence guess and consult a local agriculture officer before applying any chemical.',
        rawText: raw,
      );
}
