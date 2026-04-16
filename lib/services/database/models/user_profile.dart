/// Immutable model representing a user profile stored in SQLite.
///
/// [phoneNumber] is always a SHA-256 hash — never plaintext.
/// Dates are stored as millisecondsSinceEpoch in the database.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.village,
    this.district,
    this.primaryCrop,
    this.language = 'ta-IN',
    this.ttsSpeed = 1.0,
    this.notificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String phoneNumber;
  final String? name;
  final String? village;
  final String? district;
  final String? primaryCrop;
  final String language;
  final double ttsSpeed;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] as String,
      name: map['name'] as String?,
      village: map['village'] as String?,
      district: map['district'] as String?,
      primaryCrop: map['primary_crop'] as String?,
      language: (map['language'] as String?) ?? 'ta-IN',
      ttsSpeed: (map['tts_speed'] as num?)?.toDouble() ?? 1.0,
      notificationsEnabled: (map['notifications_enabled'] as int?) != 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'village': village,
      'district': district,
      'primary_crop': primaryCrop,
      'language': language,
      'tts_speed': ttsSpeed,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  UserProfile copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? village,
    String? district,
    String? primaryCrop,
    String? language,
    double? ttsSpeed,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      village: village ?? this.village,
      district: district ?? this.district,
      primaryCrop: primaryCrop ?? this.primaryCrop,
      language: language ?? this.language,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.phoneNumber == phoneNumber &&
        other.name == name &&
        other.village == village &&
        other.district == district &&
        other.primaryCrop == primaryCrop &&
        other.language == language &&
        other.ttsSpeed == ttsSpeed &&
        other.notificationsEnabled == notificationsEnabled &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        phoneNumber,
        name,
        village,
        district,
        primaryCrop,
        language,
        ttsSpeed,
        notificationsEnabled,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'UserProfile(id: $id, district: $district)';
}
