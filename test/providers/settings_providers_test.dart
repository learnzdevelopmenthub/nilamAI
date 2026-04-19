import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(
      Map<String, Object> initialPrefs) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsNotifier', () {
    test('uses defaults when prefs are empty', () async {
      final container = await makeContainer({});
      final state = container.read(settingsProvider);
      expect(state.ttsSpeed, equals(1.0));
      expect(state.notificationsEnabled, isTrue);
    });

    test('reads stored values from prefs', () async {
      final container = await makeContainer({
        'tts_speed': 1.2,
        'notifications_enabled': false,
      });
      final state = container.read(settingsProvider);
      expect(state.ttsSpeed, equals(1.2));
      expect(state.notificationsEnabled, isFalse);
    });

    test('setTtsSpeed updates state and persists', () async {
      final container = await makeContainer({});
      await container.read(settingsProvider.notifier).setTtsSpeed(0.8);
      expect(container.read(settingsProvider).ttsSpeed, equals(0.8));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('tts_speed'), equals(0.8));
    });

    test('setNotificationsEnabled updates state and persists', () async {
      final container = await makeContainer({});
      await container
          .read(settingsProvider.notifier)
          .setNotificationsEnabled(false);
      expect(container.read(settingsProvider).notificationsEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifications_enabled'), isFalse);
    });
  });
}
