import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import '../llm/llm_constants.dart';
import 'market_models.dart';

/// Fetches daily commodity prices from data.gov.in's AgMarknet OGD API.
///
/// Free tier; an API key is required (register at https://data.gov.in/).
/// Configure via `DATA_GOV_IN_API_KEY` in `.env` or `--dart-define=…`.
class MarketService {
  MarketService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? LlmConstants.agMarknetApiKey;

  static const _tag = 'MarketService';

  final http.Client _client;
  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<List<MandiPrice>> fetchPrices({
    required String commodity,
    String? state,
    String? district,
    int limit = 30,
  }) async {
    if (_apiKey.isEmpty) {
      throw const LlmException(
        message:
            'AgMarknet API key not configured. Add DATA_GOV_IN_API_KEY to .env.',
        code: 'E020',
      );
    }
    final params = <String, String>{
      'api-key': _apiKey,
      'format': 'json',
      'limit': '$limit',
      'filters[commodity]': commodity,
    };
    if (state != null && state.isNotEmpty) params['filters[state]'] = state;
    if (district != null && district.isNotEmpty) {
      params['filters[district]'] = district;
    }
    final uri = Uri.parse(LlmConstants.agMarknetBaseUrl).replace(
      path: '/resource/${LlmConstants.agMarknetResourceId}',
      queryParameters: params,
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw LlmException.inferenceTimeout(originalError: e);
    } on SocketException catch (e) {
      throw LlmException.networkOffline(originalError: e);
    } on http.ClientException catch (e) {
      throw LlmException.networkOffline(originalError: e);
    }

    if (response.statusCode != 200) {
      AppLogger.error(
        'AgMarknet HTTP ${response.statusCode}: ${response.body}',
        _tag,
      );
      throw LlmException(
        message: 'Market price API returned HTTP ${response.statusCode}',
        code: 'E021',
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final records = (decoded['records'] as List?) ?? const [];
    return records
        .cast<Map<String, dynamic>>()
        .map(MandiPrice.fromMap)
        .toList();
  }

  void close() => _client.close();
}
