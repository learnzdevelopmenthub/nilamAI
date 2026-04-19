import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../core/constants/strings_tamil.dart';
import '../../core/logging/logger.dart';
import '../../providers/database_providers.dart';
import '../../services/database/daos/user_profile_dao.dart';
import '../../services/database/models/query_history.dart';
import '../../services/database/models/user_profile.dart';
import '../../services/stt/stt_constants.dart';

/// Editable review of the Whisper transcription.
///
/// The user can fix any wrong words, then confirm to persist the query to
/// SQLite. Retake deletes the audio file and returns to the recording flow.
class TranscriptionReviewScreen extends ConsumerStatefulWidget {
  const TranscriptionReviewScreen({
    required this.audioPath,
    required this.initialText,
    super.key,
  });

  final String audioPath;
  final String initialText;

  @override
  ConsumerState<TranscriptionReviewScreen> createState() =>
      _TranscriptionReviewScreenState();
}

class _TranscriptionReviewScreenState
    extends ConsumerState<TranscriptionReviewScreen> {
  static const _tag = 'TranscriptionReviewScreen';
  static const _localUserPhoneHash = 'local_user_default';

  late final TextEditingController _controller;
  late final String _originalText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _originalText = widget.initialText;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _saving = true);

    try {
      final userProfileDao = ref.read(userProfileDaoProvider);
      final queryHistoryDao = ref.read(queryHistoryDaoProvider);

      final userId = await _ensureLocalUser(userProfileDao);
      final now = DateTime.now();
      final confidence = text == _originalText
          ? SttConstants.confidenceUnedited
          : SttConstants.confidenceEdited;

      final history = QueryHistory(
        id: const Uuid().v4(),
        userId: userId,
        timestamp: now,
        audioFilePath: widget.audioPath,
        transcription: text,
        transcriptionConfidence: confidence,
        createdAt: now,
        updatedAt: now,
      );
      await queryHistoryDao.insert(history);
      AppLogger.info(
        'Query saved (id=${history.id}, conf=$confidence)',
        _tag,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TamilStrings.transcriptionSaved)),
      );
      context.go('/');
    } catch (e, st) {
      AppLogger.error('Failed to save query history', _tag, e, st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TamilStrings.errorDatabase)),
      );
    }
  }

  Future<String> _ensureLocalUser(UserProfileDao dao) async {
    final existing = await dao.getCurrent();
    if (existing != null) return existing.id;

    final now = DateTime.now();
    final profile = UserProfile(
      id: const Uuid().v4(),
      phoneNumber: _localUserPhoneHash,
      createdAt: now,
      updatedAt: now,
    );
    await dao.insert(profile);
    AppLogger.info('Bootstrapped local user ${profile.id}', _tag);
    return profile.id;
  }

  Future<void> _retake() async {
    try {
      final file = File(widget.audioPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.debug('Deleted audio file on retake', _tag);
      }
    } catch (e) {
      AppLogger.warning('Could not delete audio file: $e', _tag);
    }
    if (!mounted) return;
    context.go('/record');
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final canConfirm = text.isNotEmpty && !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.reviewTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                TamilStrings.reviewInstructions,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: InputDecoration(
                    hintText: widget.initialText.isEmpty
                        ? TamilStrings.transcriptionEmpty
                        : null,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _retake,
                      icon: const Icon(Icons.mic),
                      label: const Text(TamilStrings.retake),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(120, 56),
                        side: const BorderSide(color: NilamTheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canConfirm ? _confirm : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text(TamilStrings.confirm),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 56),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
