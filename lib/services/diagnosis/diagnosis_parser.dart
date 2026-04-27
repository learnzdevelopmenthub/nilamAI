import 'dart:convert';

import '../../core/logging/logger.dart';
import 'diagnosis_models.dart';

/// Extracts a structured [DiagnosisResult] from raw Gemma output.
///
/// Strategy:
/// 1. Look for a ```json … ``` fenced block.
/// 2. Fall back to the first {…} blob in the trimmed string.
/// 3. On any error, return [DiagnosisResult.lowConfidenceFallback] so the
///    UI still renders something useful.
class DiagnosisParser {
  DiagnosisParser._();

  static const _tag = 'DiagnosisParser';

  static DiagnosisResult parse(String raw) {
    final extracted = _extractJsonBlock(raw) ?? raw.trim();
    try {
      final decoded = jsonDecode(extracted) as Map<String, dynamic>;
      return DiagnosisResult(
        diseaseName: _str(decoded['disease_name']) ?? 'Unknown',
        confidence: _confidence(decoded['confidence']),
        cause: _str(decoded['cause']) ?? '',
        symptoms: _str(decoded['symptoms']) ?? '',
        treatmentChemical: _str(decoded['treatment_chemical']) ?? '',
        treatmentOrganic: _str(decoded['treatment_organic']) ?? '',
        dosage: _str(decoded['dosage']) ?? '',
        safetyPrecautions: _str(decoded['safety_precautions']) ?? '',
        rawText: raw,
      );
    } catch (e) {
      AppLogger.warning(
        'Diagnosis JSON parse failed; falling back to low-confidence text',
        _tag,
      );
      return DiagnosisResult.lowConfidenceFallback(raw);
    }
  }

  static String? _extractJsonBlock(String raw) {
    final fence = RegExp(r'```json\s*([\s\S]*?)\s*```', caseSensitive: false)
        .firstMatch(raw);
    if (fence != null) return fence.group(1)?.trim();
    final braced = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    return braced?.group(0)?.trim();
  }

  static String? _str(Object? v) {
    if (v is String) return v.trim().isEmpty ? null : v.trim();
    if (v == null) return null;
    return v.toString();
  }

  static DiagnosisConfidence _confidence(Object? v) {
    final s = (v is String) ? v.toLowerCase().trim() : '';
    return switch (s) {
      'high' => DiagnosisConfidence.high,
      'medium' => DiagnosisConfidence.medium,
      _ => DiagnosisConfidence.low,
    };
  }
}
