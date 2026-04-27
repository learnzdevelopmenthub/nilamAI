import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/crop_profile.dart';
import '../../services/diagnosis/diagnosis_models.dart';
import '../../services/knowledge/crop_knowledge.dart';
import '../../services/retrieval/knowledge_chunk.dart';

class DiagnoseScreen extends ConsumerStatefulWidget {
  const DiagnoseScreen({this.preselectedCropProfileId, super.key});

  final String? preselectedCropProfileId;

  @override
  ConsumerState<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends ConsumerState<DiagnoseScreen> {
  static const _tag = 'DiagnoseScreen';

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _symptomsController = TextEditingController();

  CropProfile? _selectedCrop;
  XFile? _imageFile;
  bool _running = false;
  DiagnosisResult? _result;
  String? _errorCode;
  String? _errorMessage;

  bool _autoSelected = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() => _pickImage(ImageSource.camera);
  Future<void> _pickFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() {
        _imageFile = picked;
        _result = null;
        _errorCode = null;
      });
    } catch (e, st) {
      AppLogger.error('Image pick failed', _tag, e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.errorGeneral)),
      );
    }
  }

  Future<void> _runDiagnosis(CropKnowledgeBase kb) async {
    if (_running) return;
    final hasImage = _imageFile != null;
    final hasSymptoms = _symptomsController.text.trim().isNotEmpty;
    if (!hasImage && !hasSymptoms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.diagnoseInputRequired)),
      );
      return;
    }
    setState(() {
      _running = true;
      _result = null;
      _errorCode = null;
    });
    try {
      final tpl = _selectedCrop != null ? kb.byId(_selectedCrop!.cropId) : null;
      final stage = (tpl != null && _selectedCrop != null)
          ? tpl.stageForDay(_selectedCrop!.daysSinceSowing())
          : null;
      List<int>? bytes;
      if (hasImage) {
        bytes = await File(_imageFile!.path).readAsBytes();
      }
      final req = DiagnosisRequest(
        cropId: _selectedCrop?.cropId,
        cropName: tpl?.name,
        stageName: stage?.name,
        dayInStage: stage == null
            ? null
            : (_selectedCrop!.daysSinceSowing() - stage.startDay + 1),
        imageBytes: bytes,
        symptomsText: hasSymptoms ? _symptomsController.text.trim() : null,
      );

      // Pull top-K disease + stage chunks to ground the diagnosis prompt.
      final retrievalQuery = hasSymptoms
          ? _symptomsController.text.trim()
          : '${tpl?.name ?? ''} ${stage?.name ?? ''} disease symptoms'.trim();
      final ranked = retrievalQuery.isEmpty
          ? const <RankedChunk>[]
          : await ref.read(knowledgeRetrieverProvider).retrieve(
                query: retrievalQuery,
                cropId: _selectedCrop?.cropId,
                stageId: stage?.id,
                topK: 5,
              );
      final res = await ref.read(diagnosisServiceProvider).diagnose(
            req,
            retrievedChunks:
                ranked.map((r) => r.chunk).toList(growable: false),
          );
      if (!mounted) return;
      setState(() => _result = res);
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCode = e.code;
        _errorMessage = e.message;
      });
    } catch (e, st) {
      AppLogger.error('Diagnosis failed', _tag, e, st);
      if (!mounted) return;
      setState(() {
        _errorCode = 'E003';
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncKb = ref.watch(cropKnowledgeProvider);
    final asyncUserId = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.diagnoseTitle)),
      body: SafeArea(
        child: asyncKb.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text(TamilStrings.errorGeneral)),
          data: (kb) => asyncUserId.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text(TamilStrings.errorDatabase)),
            data: (userId) => _buildBody(context, kb, userId),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CropKnowledgeBase kb,
    String userId,
  ) {
    final asyncCrops = ref.watch(userCropProfilesProvider(userId));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          TamilStrings.diagnoseSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        asyncCrops.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (crops) {
            if (crops.isEmpty) return const SizedBox.shrink();
            // Auto-select first active crop if user came from /diagnose root.
            if (!_autoSelected) {
              _autoSelected = true;
              final pre = widget.preselectedCropProfileId;
              CropProfile? candidate;
              if (pre != null) {
                for (final c in crops) {
                  if (c.id == pre) {
                    candidate = c;
                    break;
                  }
                }
              }
              candidate ??= crops.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedCrop = candidate);
              });
            }
            return DropdownButtonFormField<CropProfile>(
              initialValue: _selectedCrop,
              decoration: const InputDecoration(
                labelText: TamilStrings.selectCropForDiagnosis,
                border: OutlineInputBorder(),
              ),
              items: crops
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                            '${kb.byId(c.cropId)?.name ?? c.cropId} (${c.variety ?? 'no variety'})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCrop = v),
            );
          },
        ),
        const SizedBox(height: 16),
        if (_imageFile != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_imageFile!.path),
              fit: BoxFit.cover,
              height: 220,
            ),
          )
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  TamilStrings.diagnoseEmptyState,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _running ? null : _pickFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text(TamilStrings.capturePhoto),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _running ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text(TamilStrings.chooseFromGallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _symptomsController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: TamilStrings.describeSymptoms,
            hintText: TamilStrings.symptomsHint,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _running ? null : () => _runDiagnosis(kb),
          icon: _running
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.medical_services),
          label: const Text(TamilStrings.runDiagnosis),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
        ),
        if (_errorCode != null) ...[
          const SizedBox(height: 16),
          _ErrorCard(code: _errorCode!, message: _errorMessage ?? ''),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          _ResultCard(result: _result!),
        ],
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.code, required this.message});
  final String code;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  TamilStrings.gemmaError,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('[$code] $message'),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final DiagnosisResult result;

  String _confidenceLabel(DiagnosisConfidence c) => switch (c) {
        DiagnosisConfidence.high => TamilStrings.confidenceHigh,
        DiagnosisConfidence.medium => TamilStrings.confidenceMedium,
        DiagnosisConfidence.low => TamilStrings.confidenceLow,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowConfidence = result.confidence == DiagnosisConfidence.low;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TamilStrings.diagnosisResultTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _kv(theme, TamilStrings.diseaseName, result.diseaseName),
            _kv(theme, TamilStrings.confidence,
                _confidenceLabel(result.confidence)),
            if (result.cause.isNotEmpty)
              _kv(theme, TamilStrings.cause, result.cause),
            if (result.symptoms.isNotEmpty)
              _kv(theme, TamilStrings.symptoms, result.symptoms),
            if (result.treatmentChemical.isNotEmpty)
              _kv(theme, TamilStrings.treatmentChemical,
                  result.treatmentChemical),
            if (result.treatmentOrganic.isNotEmpty)
              _kv(theme, TamilStrings.treatmentOrganic,
                  result.treatmentOrganic),
            if (result.dosage.isNotEmpty)
              _kv(theme, TamilStrings.dosage, result.dosage),
            if (result.safetyPrecautions.isNotEmpty)
              _kv(theme, TamilStrings.safetyPrecautions,
                  result.safetyPrecautions),
            if (lowConfidence) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  TamilStrings.diagnoseLowConfidenceAdvice,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
}
