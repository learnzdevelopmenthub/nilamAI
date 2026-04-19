import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database/database_service.dart';
import '../services/database/daos/user_profile_dao.dart';
import '../services/database/daos/query_history_dao.dart';
import '../services/database/models/query_history.dart';

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

/// Loads a single [QueryHistory] by id. Returns `null` if not found.
final queryByIdProvider =
    FutureProvider.family<QueryHistory?, String>((ref, id) async {
  return ref.watch(queryHistoryDaoProvider).getById(id);
});

/// Loads up to 5 most recent queries for the given user — used by the Home
/// screen recent-questions list.
final recentQueriesProvider =
    FutureProvider.family<List<QueryHistory>, String>((ref, userId) async {
  return ref.watch(queryHistoryDaoProvider).getByUserId(userId, limit: 5);
});

/// Lookup parameters for [historyQueriesProvider].
class HistoryQuery {
  const HistoryQuery({required this.userId, this.keyword});

  final String userId;
  final String? keyword;

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery &&
      other.userId == userId &&
      other.keyword == keyword;

  @override
  int get hashCode => Object.hash(userId, keyword);
}

/// Loads the History screen's query list — applies search if a keyword is set,
/// otherwise returns the user's queries (newest first, max 50).
final historyQueriesProvider =
    FutureProvider.family<List<QueryHistory>, HistoryQuery>(
        (ref, query) async {
  final dao = ref.watch(queryHistoryDaoProvider);
  final keyword = query.keyword?.trim();
  if (keyword != null && keyword.isNotEmpty) {
    return dao.searchByKeyword(keyword, userId: query.userId, limit: 50);
  }
  return dao.getByUserId(query.userId, limit: 50);
});
