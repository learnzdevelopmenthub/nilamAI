import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    required this.ttsSpeed,
    required this.notificationsEnabled,
    required this.totalLandAcres,
  });

  final double ttsSpeed;
  final bool notificationsEnabled;

  /// Total cultivable land holding declared by the farmer (acres). Used by
  /// the Schemes screen to filter eligibility. Null = not declared.
  final double? totalLandAcres;

  SettingsState copyWith({
    double? ttsSpeed,
    bool? notificationsEnabled,
    Object? totalLandAcres = _sentinel,
  }) {
    return SettingsState(
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      totalLandAcres: identical(totalLandAcres, _sentinel)
          ? this.totalLandAcres
          : totalLandAcres as double?,
    );
  }

  static const Object _sentinel = Object();
}

class _Keys {
  static const ttsSpeed = 'tts_speed';
  static const notificationsEnabled = 'notifications_enabled';
  static const totalLandAcres = 'total_land_acres';
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
      totalLandAcres: prefs.getDouble(_Keys.totalLandAcres),
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

  Future<void> setTotalLandAcres(double? acres) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (acres == null) {
      await prefs.remove(_Keys.totalLandAcres);
    } else {
      await prefs.setDouble(_Keys.totalLandAcres, acres);
    }
    state = state.copyWith(totalLandAcres: acres);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
