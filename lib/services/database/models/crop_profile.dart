/// Per-field crop tracking record persisted in SQLite.
///
/// `cropId` is the slug from the bundled crop knowledge JSON
/// (e.g. `rice`, `tomato`). The current growth stage is computed at read
/// time from `sowingDate` against the JSON template — not stored — so the
/// row stays tiny and survives knowledge-base updates.
class CropProfile {
  const CropProfile({
    required this.id,
    required this.userId,
    required this.cropId,
    this.variety,
    required this.sowingDate,
    this.landAreaAcres,
    this.soilType,
    this.irrigationType,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String cropId;
  final String? variety;
  final DateTime sowingDate;
  final double? landAreaAcres;
  final String? soilType;
  final String? irrigationType;

  /// `active` | `harvested` | `archived`. New rows default to `active`.
  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory CropProfile.fromMap(Map<String, dynamic> map) {
    return CropProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      cropId: map['crop_id'] as String,
      variety: map['variety'] as String?,
      sowingDate:
          DateTime.fromMillisecondsSinceEpoch(map['sowing_date'] as int),
      landAreaAcres: (map['land_area_acres'] as num?)?.toDouble(),
      soilType: map['soil_type'] as String?,
      irrigationType: map['irrigation_type'] as String?,
      status: (map['status'] as String?) ?? 'active',
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'crop_id': cropId,
        'variety': variety,
        'sowing_date': sowingDate.millisecondsSinceEpoch,
        'land_area_acres': landAreaAcres,
        'soil_type': soilType,
        'irrigation_type': irrigationType,
        'status': status,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  CropProfile copyWith({
    String? id,
    String? userId,
    String? cropId,
    Object? variety = _sentinel,
    DateTime? sowingDate,
    Object? landAreaAcres = _sentinel,
    Object? soilType = _sentinel,
    Object? irrigationType = _sentinel,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cropId: cropId ?? this.cropId,
      variety:
          identical(variety, _sentinel) ? this.variety : variety as String?,
      sowingDate: sowingDate ?? this.sowingDate,
      landAreaAcres: identical(landAreaAcres, _sentinel)
          ? this.landAreaAcres
          : landAreaAcres as double?,
      soilType:
          identical(soilType, _sentinel) ? this.soilType : soilType as String?,
      irrigationType: identical(irrigationType, _sentinel)
          ? this.irrigationType
          : irrigationType as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const Object _sentinel = Object();

  /// Days elapsed since sowing (today minus sowing date), clamped to >= 0.
  int daysSinceSowing([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(sowingDate).inDays;
    return diff < 0 ? 0 : diff;
  }
}
