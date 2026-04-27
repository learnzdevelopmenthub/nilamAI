import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../providers/feature_providers.dart';
import '../../providers/user_providers.dart';
import '../../services/database/models/crop_profile.dart';
import '../../services/knowledge/crop_knowledge.dart';

class AddCropScreen extends ConsumerStatefulWidget {
  const AddCropScreen({super.key});

  @override
  ConsumerState<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends ConsumerState<AddCropScreen> {
  static const _tag = 'AddCropScreen';

  final _formKey = GlobalKey<FormState>();
  CropTemplate? _selectedCrop;
  String? _variety;
  DateTime _sowingDate = DateTime.now();
  final _landAreaController = TextEditingController();
  String? _soilType;
  String? _irrigationType;
  bool _saving = false;

  static const _soils = [
    'Black soil',
    'Red soil',
    'Alluvial',
    'Sandy',
    'Loam',
  ];
  static const _irrigations = [
    'Rain-fed',
    'Borewell',
    'Canal',
    'Drip',
    'Sprinkler',
  ];

  @override
  void dispose() {
    _landAreaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _sowingDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_selectedCrop == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final dao = ref.read(cropProfileDaoProvider);
      final userId = await ref.read(currentUserIdProvider.future);
      final now = DateTime.now();
      final acres = double.tryParse(_landAreaController.text.trim());
      final crop = CropProfile(
        id: const Uuid().v4(),
        userId: userId,
        cropId: _selectedCrop!.id,
        variety: _variety,
        sowingDate: _sowingDate,
        landAreaAcres: acres,
        soilType: _soilType,
        irrigationType: _irrigationType,
        createdAt: now,
        updatedAt: now,
      );
      await dao.insert(crop);
      ref.invalidate(userCropProfilesProvider(userId));
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      AppLogger.error('Failed to add crop', _tag, e, st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncKb = ref.watch(cropKnowledgeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.addCropTitle)),
      body: SafeArea(
        child: asyncKb.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text(TamilStrings.errorGeneral)),
          data: (kb) => _buildForm(context, kb),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, CropKnowledgeBase kb) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<CropTemplate>(
            initialValue: _selectedCrop,
            decoration: const InputDecoration(
              labelText: TamilStrings.selectCropType,
              border: OutlineInputBorder(),
            ),
            items: kb.crops
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedCrop = v;
              _variety = null;
            }),
            validator: (v) => v == null ? 'Pick a crop' : null,
          ),
          const SizedBox(height: 16),
          if (_selectedCrop != null && _selectedCrop!.varieties.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _variety,
              decoration: const InputDecoration(
                labelText: TamilStrings.cropVariety,
                border: OutlineInputBorder(),
              ),
              items: _selectedCrop!.varieties
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _variety = v),
            ),
          if (_selectedCrop != null && _selectedCrop!.varieties.isNotEmpty)
            const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: TamilStrings.sowingDate,
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(DateFormat.yMMMd().format(_sowingDate)),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _landAreaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: TamilStrings.landAreaAcres,
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter a positive number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _soilType,
            decoration: const InputDecoration(
              labelText: TamilStrings.soilType,
              border: OutlineInputBorder(),
            ),
            items: _soils
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _soilType = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _irrigationType,
            decoration: const InputDecoration(
              labelText: TamilStrings.irrigationType,
              border: OutlineInputBorder(),
            ),
            items: _irrigations
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _irrigationType = v),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: const Text(TamilStrings.saveCrop),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }
}
