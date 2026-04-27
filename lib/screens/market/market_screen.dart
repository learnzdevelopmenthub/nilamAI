import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/strings_tamil.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/logging/logger.dart';
import '../../providers/feature_providers.dart';
import '../../services/market/market_models.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  static const _tag = 'MarketScreen';

  static const _commodities = [
    'Tomato',
    'Rice',
    'Onion',
    'Banana',
    'Groundnut',
    'Sugarcane',
  ];

  String _selectedCommodity = 'Tomato';
  String? _selectedState = 'Tamil Nadu';
  bool _loading = false;
  List<MandiPrice> _prices = const [];
  String? _errorMessage;
  DateTime? _fetchedAt;

  Future<void> _fetch() async {
    final svc = ref.read(marketServiceProvider);
    if (!svc.isConfigured) {
      setState(() {
        _errorMessage = TamilStrings.marketApiKeyMissing;
        _prices = const [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await svc.fetchPrices(
        commodity: _selectedCommodity,
        state: _selectedState,
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _prices = list;
        _fetchedAt = DateTime.now();
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '[${e.code}] ${e.message}');
    } catch (e, st) {
      AppLogger.error('Market fetch failed', _tag, e, st);
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(TamilStrings.marketTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              TamilStrings.marketHelper,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCommodity,
              decoration: const InputDecoration(
                labelText: 'Commodity',
                border: OutlineInputBorder(),
              ),
              items: _commodities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCommodity = v ?? _selectedCommodity),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedState,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Tamil Nadu', child: Text('Tamil Nadu')),
                DropdownMenuItem(value: 'Karnataka', child: Text('Karnataka')),
                DropdownMenuItem(value: 'Andhra Pradesh', child: Text('Andhra Pradesh')),
                DropdownMenuItem(value: 'Kerala', child: Text('Kerala')),
                DropdownMenuItem(value: null, child: Text('All states')),
              ],
              onChanged: (v) => setState(() => _selectedState = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _fetch,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: const Text(TamilStrings.fetchPrices),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            if (_fetchedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '${TamilStrings.lastUpdated}: ${_fetchedAt!.toIso8601String()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            if (_prices.isEmpty &&
                _errorMessage == null &&
                !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    TamilStrings.noPriceData,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            for (final price in _prices) _PriceCard(price: price),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});
  final MandiPrice price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${price.market} (${price.district})',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  price.arrivalDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${price.commodity}'
              '${price.variety.isNotEmpty ? " — ${price.variety}" : ""}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _priceCol(theme, TamilStrings.priceMin, price.minPrice),
                const SizedBox(width: 16),
                _priceCol(theme, TamilStrings.priceModal, price.modalPrice,
                    highlight: true),
                const SizedBox(width: 16),
                _priceCol(theme, TamilStrings.priceMax, price.maxPrice),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceCol(ThemeData theme, String label, double value,
      {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: highlight
                ? theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
