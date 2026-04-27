import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/core/exceptions/app_exception.dart';
import 'package:nilam_ai/providers/feature_providers.dart';
import 'package:nilam_ai/screens/market/market_screen.dart';
import 'package:nilam_ai/services/market/market_models.dart';
import 'package:nilam_ai/services/market/market_service.dart';

class _FakeMarketService extends MarketService {
  _FakeMarketService({
    required this.configured,
    this.rows,
    this.error,
  }) : super(apiKey: configured ? 'fake-key' : '');

  final bool configured;
  final List<MandiPrice>? rows;
  final Object? error;

  @override
  bool get isConfigured => configured;

  @override
  Future<List<MandiPrice>> fetchPrices({
    required String commodity,
    String? state,
    String? district,
    int limit = 30,
  }) async {
    if (error != null) throw error!;
    return rows ?? const [];
  }
}

GoRouter _router() => GoRouter(
      initialLocation: '/market',
      routes: [
        GoRoute(path: '/market', builder: (_, _) => const MarketScreen()),
      ],
    );

Widget _app(_FakeMarketService fake) {
  return ProviderScope(
    overrides: [marketServiceProvider.overrideWithValue(fake)],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('MarketScreen', () {
    testWidgets('initial state shows the no-data hint', (tester) async {
      await tester.pumpWidget(_app(_FakeMarketService(configured: true)));
      await _settle(tester);

      expect(find.text(TamilStrings.noPriceData), findsOneWidget);
    });

    testWidgets('fetch with rows renders the price cards', (tester) async {
      final fake = _FakeMarketService(
        configured: true,
        rows: const [
          MandiPrice(
            commodity: 'Tomato',
            market: 'Koyambedu',
            district: 'Chennai',
            state: 'Tamil Nadu',
            variety: 'Hybrid',
            modalPrice: 2500,
            minPrice: 2000,
            maxPrice: 3000,
            arrivalDate: '2026-04-26',
          ),
          MandiPrice(
            commodity: 'Tomato',
            market: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            variety: 'Local',
            modalPrice: 2300,
            minPrice: 1900,
            maxPrice: 2700,
            arrivalDate: '2026-04-26',
          ),
        ],
      );
      await tester.pumpWidget(_app(fake));
      await _settle(tester);

      await tester.tap(find.text(TamilStrings.fetchPrices));
      await _settle(tester);

      expect(find.textContaining('Koyambedu'), findsOneWidget);
      expect(find.textContaining('Madurai'), findsOneWidget);
      expect(find.text(TamilStrings.noPriceData), findsNothing);
    });

    testWidgets('error path renders the error card', (tester) async {
      final fake = _FakeMarketService(
        configured: true,
        error: const LlmException(message: 'boom', code: 'E020'),
      );
      await tester.pumpWidget(_app(fake));
      await _settle(tester);
      await tester.tap(find.text(TamilStrings.fetchPrices));
      await _settle(tester);

      expect(find.textContaining('[E020]'), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
    });

    testWidgets('not-configured banner appears when API key is missing',
        (tester) async {
      final fake = _FakeMarketService(configured: false);
      await tester.pumpWidget(_app(fake));
      await _settle(tester);
      await tester.tap(find.text(TamilStrings.fetchPrices));
      await _settle(tester);

      expect(find.text(TamilStrings.marketApiKeyMissing), findsOneWidget);
    });
  });
}
