import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilam_ai/core/constants/strings_tamil.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:nilam_ai/screens/schemes/schemes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/knowledge_test_helpers.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/schemes',
      routes: [
        GoRoute(path: '/schemes', builder: (_, _) => const SchemesScreen()),
      ],
    );

Widget _app(SharedPreferences prefs, TestKnowledge knowledge) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...knowledge.overrides(),
    ],
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
  late TestKnowledge knowledge;

  setUpAll(() async {
    // Stub url_launcher so the "Open portal" button can be tapped without
    // crashing if a future test wires it up.
    TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async => true,
    );
    knowledge = await TestKnowledge.load();
  });

  group('SchemesScreen', () {
    testWidgets('3 acres → PM-KISAN shows Eligible badge', (tester) async {
      SharedPreferences.setMockInitialValues({'total_land_acres': 3.0});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_app(prefs, knowledge));
      await _settle(tester);

      final pmCard = find.ancestor(
        of: find.textContaining('PM-KISAN'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: pmCard,
          matching: find.text(TamilStrings.eligibleBadge),
        ),
        findsOneWidget,
      );
      expect(find.text(TamilStrings.setLandAreaPrompt), findsNothing);
    });

    testWidgets('8 acres filters out PM-KISAN (cap 5)', (tester) async {
      SharedPreferences.setMockInitialValues({'total_land_acres': 8.0});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_app(prefs, knowledge));
      await _settle(tester);

      // matchedSchemesProvider filters out PM-KISAN (cap=5 < 8).
      expect(find.textContaining('PM-KISAN'), findsNothing);
      // The remaining 3 schemes (PMFBY, TN crop loan, Soil Health) all pass
      // the cap test against 8 acres so they show the "Eligible" badge.
      expect(
        find.text(TamilStrings.eligibleBadge, skipOffstage: false),
        findsWidgets,
      );
    });

    testWidgets('unset land area → all schemes need check + prompt banner',
        (tester) async {
      // ListView lazily builds children — give the test a tall enough
      // viewport so all 4 scheme cards mount in one pass.
      await tester.binding.setSurfaceSize(const Size(800, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(_app(prefs, knowledge));
      await _settle(tester);

      expect(find.text(TamilStrings.setLandAreaPrompt), findsOneWidget);
      expect(find.text(TamilStrings.eligibleBadge), findsNothing);
      expect(
        find.text(TamilStrings.checkRequiredBadge),
        findsNWidgets(4),
      );
    });
  });
}
