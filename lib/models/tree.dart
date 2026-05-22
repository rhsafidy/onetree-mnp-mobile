enum TreeStatus { pending, planted, monitored, dead, replaced }

enum HealthStatus { good, degraded, dead }

class Tree {
  final String id;
  final String externalId;
  final String? speciesScientific;
  final String? speciesVernacular;
  final String? planterName;
  final String? planterFunction;
  final DateTime? plantationDate;
  final String? area;
  final String? family;
  final int? heightCm;
  final int? holeNumber;
  final String? healthStatus;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? parcelId;
  final String? touristId;
  final String? plantedByUserId;
  final bool syncPending;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tree({
    required this.id,
    required this.externalId,
    this.speciesScientific,
    this.speciesVernacular,
    this.planterName,
    this.planterFunction,
    this.plantationDate,
    this.area,
    this.family,
    this.heightCm,
    this.holeNumber,
    this.healthStatus,
    this.latitude,
    this.longitude,
    this.notes,
    this.parcelId,
    this.touristId,
    this.plantedByUserId,
    this.syncPending = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TreeStatus get status {
    switch (healthStatus) {
      case 'dead':     return TreeStatus.dead;
      case 'replaced': return TreeStatus.replaced;
      case 'planted':  return TreeStatus.planted;
      case 'monitored': return TreeStatus.monitored;
      default:         return TreeStatus.pending;
    }
  }

  factory Tree.fromMap(Map<String, dynamic> map) => Tree(
        id: map['id'] as String,
        externalId: map['external_id'] as String,
        speciesScientific: map['species_scientific'] as String?,
        speciesVernacular: map['species_vernacular'] as String?,
        planterName: map['planter_name'] as String?,
        planterFunction: map['planter_function'] as String?,
        plantationDate: map['plantation_date'] != null
            ? DateTime.parse(map['plantation_date'] as String)
            : null,
        area: map['area'] as String?,
        family: map['family'] as String?,
        heightCm: map['height_cm'] as int?,
        holeNumber: map['hole_number'] as int?,
        healthStatus: map['health_status'] as String?,
        latitude: map['latitude'] as double?,
        longitude: map['longitude'] as double?,
        notes: map['notes'] as String?,
        parcelId: map['parcel_id'] as String?,
        touristId: map['tourist_id'] as String?,
        plantedByUserId: map['planted_by_user_id'] as String?,
        syncPending: (map['sync_pending'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'external_id': externalId,
        'species_scientific': speciesScientific,
        'species_vernacular': speciesVernacular,
        'planter_name': planterName,
        'planter_function': planterFunction,
        'plantation_date': plantationDate?.toIso8601String(),
        'area': area,
        'family': family,
        'height_cm': heightCm,
        'hole_number': holeNumber,
        'health_status': healthStatus,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'parcel_id': parcelId,
        'tourist_id': touristId,
        'planted_by_user_id': plantedByUserId,
        'sync_pending': syncPending ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Tree copyWith({
    String? healthStatus,
    double? latitude,
    double? longitude,
    int? heightCm,
    String? touristId,
    String? plantedByUserId,
    bool? syncPending,
  }) =>
      Tree(
        id: id,
        externalId: externalId,
        speciesScientific: speciesScientific,
        speciesVernacular: speciesVernacular,
        planterName: planterName,
        planterFunction: planterFunction,
        plantationDate: plantationDate,
        area: area,
        family: family,
        heightCm: heightCm ?? this.heightCm,
        holeNumber: holeNumber,
        healthStatus: healthStatus ?? this.healthStatus,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        notes: notes,
        parcelId: parcelId,
        touristId: touristId ?? this.touristId,
        plantedByUserId: plantedByUserId ?? this.plantedByUserId,
        syncPending: syncPending ?? this.syncPending,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}