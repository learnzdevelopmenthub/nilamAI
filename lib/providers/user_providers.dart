import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/logging/logger.dart';
import '../services/database/models/user_profile.dart';
import 'database_providers.dart';

const String _localUserPhoneHash = 'local_user_default';

/// Resolves the current local user id, bootstrapping a default profile if none
/// exists. Single-user MVP — first launch creates the row, subsequent launches
/// reuse it.
final currentUserIdProvider = FutureProvider<String>((ref) async {
  const tag = 'currentUserIdProvider';
  final dao = ref.read(userProfileDaoProvider);

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
  AppLogger.info('Bootstrapped local user ${profile.id}', tag);
  return profile.id;
});
