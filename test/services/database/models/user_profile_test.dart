import 'package:flutter_test/flutter_test.dart';
import 'package:nilam_ai/services/database/models/user_profile.dart';

void main() {
  final now = DateTime(2026, 4, 17, 10, 0);

  UserProfile createProfile({
    String id = 'test-uuid',
    String phoneNumber = 'hashed-phone',
    String? name = 'Test Farmer',
    String? district = 'Thanjavur',
    bool notificationsEnabled = true,
  }) {
    return UserProfile(
      id: id,
      phoneNumber: phoneNumber,
      name: name,
      village: 'TestVillage',
      district: district,
      primaryCrop: 'rice',
      language: 'ta-IN',
      ttsSpeed: 1.0,
      notificationsEnabled: notificationsEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('UserProfile', () {
    test('fromMap/toMap round-trips correctly', () {
      final original = createProfile();
      final map = original.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored, equals(original));
    });

    test('toMap stores DateTime as millisecondsSinceEpoch', () {
      final profile = createProfile();
      final map = profile.toMap();
      expect(map['created_at'], equals(now.millisecondsSinceEpoch));
      expect(map['updated_at'], equals(now.millisecondsSinceEpoch));
    });

    test('toMap stores bool as int (1/0)', () {
      final enabled = createProfile(notificationsEnabled: true);
      final disabled = createProfile(notificationsEnabled: false);
      expect(enabled.toMap()['notifications_enabled'], equals(1));
      expect(disabled.toMap()['notifications_enabled'], equals(0));
    });

    test('fromMap converts int to bool for notifications', () {
      final map = createProfile().toMap();

      map['notifications_enabled'] = 1;
      expect(UserProfile.fromMap(map).notificationsEnabled, isTrue);

      map['notifications_enabled'] = 0;
      expect(UserProfile.fromMap(map).notificationsEnabled, isFalse);
    });

    test('fromMap uses defaults for missing optional fields', () {
      final map = {
        'id': 'test-id',
        'phone_number': 'hash',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };
      final profile = UserProfile.fromMap(map);
      expect(profile.language, equals('ta-IN'));
      expect(profile.ttsSpeed, equals(1.0));
      expect(profile.notificationsEnabled, isTrue);
      expect(profile.name, isNull);
      expect(profile.village, isNull);
      expect(profile.district, isNull);
      expect(profile.primaryCrop, isNull);
    });

    test('copyWith produces new instance with changed field', () {
      final original = createProfile();
      final copy = original.copyWith(name: 'New Name');
      expect(copy.name, equals('New Name'));
      expect(copy.id, equals(original.id));
      expect(copy, isNot(equals(original)));
    });

    test('equality compares all fields', () {
      final a = createProfile();
      final b = createProfile();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ', () {
      final a = createProfile(id: 'id-1');
      final b = createProfile(id: 'id-2');
      expect(a, isNot(equals(b)));
    });

    test('toString does not expose phoneNumber', () {
      final profile = createProfile();
      final str = profile.toString();
      expect(str, contains('id'));
      expect(str, contains('district'));
      expect(str, isNot(contains('hashed-phone')));
    });
  });
}
