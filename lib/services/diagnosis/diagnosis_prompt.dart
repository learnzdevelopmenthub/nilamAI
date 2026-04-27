import 'diagnosis_models.dart';

/// Builds the diagnosis prompt sent to Gemma 4. Output asks the model to
/// emit ONLY a JSON object inside a ```json ... ``` fence so [DiagnosisParser]
/// can extract structured fields cleanly.
class DiagnosisPrompt {
  DiagnosisPrompt._();

  static const String system = '''
You are NilamAI, an English-speaking plant pathology assistant for small farmers in Tamil Nadu, India.
You diagnose crop diseases and recommend safe, low-cost treatments.

Rules:
- Respond in ENGLISH only.
- Output ONLY a single JSON object inside a ```json ... ``` code fence. No prose before or after.
- If you are uncertain, set "confidence" to "low" and explain what additional information is needed in the "symptoms" field.
- Prefer treatments commonly available in rural Indian agri-input shops.
- Always include safety_precautions for any chemical recommendation.

Required JSON shape:
{
  "disease_name": "string",
  "confidence": "high" | "medium" | "low",
  "cause": "string",
  "symptoms": "string",
  "treatment_chemical": "string",
  "treatment_organic": "string",
  "dosage": "string",
  "safety_precautions": "string"
}
''';

  static String userMessage(DiagnosisRequest req) {
    final lines = <String>[];
    lines.add('Crop: ${req.cropName ?? req.cropId ?? "unknown"}');
    if (req.stageName != null) {
      final dayStr = req.dayInStage != null ? ' (day ${req.dayInStage})' : '';
      lines.add('Growth stage: ${req.stageName}$dayStr');
    }
    if (req.hasImage) {
      lines.add(
        'The attached image shows leaves or plant parts the farmer is worried about.',
      );
    }
    if (req.hasSymptoms) {
      lines.add('Farmer-described symptoms: ${req.symptomsText!.trim()}');
    }
    lines.add(
      'Diagnose the most likely disease and fill the JSON exactly as specified.',
    );
    return lines.join('\n');
  }

  static String fullPrompt(DiagnosisRequest req) =>
      '$system\n\n${userMessage(req)}';
}
