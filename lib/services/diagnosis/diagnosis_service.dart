import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import '../llm/gemma_service.dart';
import '../llm/llm_constants.dart';
import 'diagnosis_models.dart';
import 'diagnosis_parser.dart';
import 'diagnosis_prompt.dart';

/// Orchestrates the disease diagnosis flow.
///
/// Picks the vision path when [LlmConstants.deepInfraVisionCapable] is true
/// and the request includes [DiagnosisRequest.imageBytes]. Otherwise falls
/// back to a text-only call grounded in [DiagnosisRequest.symptomsText].
class DiagnosisService {
  DiagnosisService(this._gemma);

  static const _tag = 'DiagnosisService';

  final GemmaService _gemma;

  Future<DiagnosisResult> diagnose(DiagnosisRequest req) async {
    if (!req.isValid) {
      throw LlmException.invalidQuery(
        'Add a photo or describe symptoms to run a diagnosis.',
      );
    }

    final prompt = DiagnosisPrompt.fullPrompt(req);
    final useVision =
        LlmConstants.deepInfraVisionCapable && req.hasImage;
    AppLogger.info(
      'Running diagnosis (vision=$useVision, hasSymptoms=${req.hasSymptoms})',
      _tag,
    );

    final response = useVision
        ? await _gemma.generateWithImage(
            prompt: prompt,
            imageBytes: req.imageBytes!,
            mimeType: req.imageMimeType,
            maxTokens: 400,
          )
        : await _gemma.generate(query: prompt);

    return DiagnosisParser.parse(response.text);
  }
}
