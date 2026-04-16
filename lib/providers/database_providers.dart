import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database/database_service.dart';
import '../services/database/daos/user_profile_dao.dart';
import '../services/database/daos/query_history_dao.dart';

/// Provides the initialized [DatabaseService].
///
/// Must be overridden in [ProviderScope] with an initialized instance:
/// ```dart
/// ProviderScope(
///   overrides: [
///     databaseServiceProvider.overrideWithValue(dbService),
///   ],
///   child: const NilamAIApp(),
/// )
/// ```
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError(
    'databaseServiceProvider must be overridden with an initialized DatabaseService',
  );
});

/// Convenience provider for [UserProfileDao].
final userProfileDaoProvider = Provider<UserProfileDao>((ref) {
  return ref.watch(databaseServiceProvider).userProfileDao;
});

/// Convenience provider for [QueryHistoryDao].
final queryHistoryDaoProvider = Provider<QueryHistoryDao>((ref) {
  return ref.watch(databaseServiceProvider).queryHistoryDao;
});
