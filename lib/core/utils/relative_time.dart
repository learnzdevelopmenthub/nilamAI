import 'package:intl/intl.dart';

/// Format a past [DateTime] as a Tamil relative-time phrase.
///
/// Buckets: now (<60s), N minutes, N hours, N days, then absolute date.
/// Pass [now] for deterministic tests.
String formatRelativeTamil(DateTime when, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(when);

  if (diff.inSeconds < 60) return 'இப்போது';
  if (diff.inMinutes < 60) return '${diff.inMinutes} நிமிடம் முன்பு';
  if (diff.inHours < 24) return '${diff.inHours} மணி நேரம் முன்பு';
  if (diff.inDays < 7) return '${diff.inDays} நாள் முன்பு';
  return DateFormat('dd/MM/yyyy').format(when);
}
