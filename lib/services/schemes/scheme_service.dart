import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'scheme.dart';

/// Loads bundled `assets/knowledge/schemes.json` and matches schemes
/// against a farmer's land holding.
class SchemeService {
  SchemeService({this.assetPath = 'assets/knowledge/schemes.json'});

  final String assetPath;
  List<Scheme>? _cache;

  Future<List<Scheme>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['schemes'] as List)
        .cast<Map<String, dynamic>>()
        .map(Scheme.fromJson)
        .toList(growable: false);
    _cache = list;
    return list;
  }

  /// Returns every scheme whose land cap accommodates [totalLandAcres].
  /// Pass null when the farmer hasn't declared land area; everything is
  /// returned with `eligibilityUnknown=true` semantics handled in the UI.
  Future<List<Scheme>> matchFor({double? totalLandAcres}) async {
    final all = await loadAll();
    return all.where((s) => s.isEligibleFor(totalLandAcres)).toList();
  }
}
