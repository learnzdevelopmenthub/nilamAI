import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    required this.ttsSpeed,
    required this.notificationsEnabled,
  });

  final double ttsSpeed;
  final bool notificationsEnabled;

  SettingsState copyWith({double? ttsSpeed, bool? notificationsEnabled}) {
    return SettingsState(
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class _Keys {
  static const ttsSpeed = 'tts_speed';
  static const notificationsEnabled = 'notifications_enabled';
}

const double _defaultTtsSpeed = 1.0;
const bool _defaultNotifications = true;

/// Holds the SharedPreferences instance. Override in main() after async init.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a SharedPreferences instance',
  );
});

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return SettingsState(
      ttsSpeed: prefs.getDouble(_Keys.ttsSpeed) ?? _defaultTtsSpeed,
      notificationsEnabled:
          prefs.getBool(_Keys.notificationsEnabled) ?? _defaultNotifications,
    );
  }

  Future<void> setTtsSpeed(double speed) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_Keys.ttsSpeed, speed);
    state = state.copyWith(ttsSpeed: speed);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_Keys.notificationsEnabled, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
