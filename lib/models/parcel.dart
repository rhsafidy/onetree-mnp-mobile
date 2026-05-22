class Parcel {
  final String id;
  final String name;
  final String code;
  final String? park;
  final double? areaHa;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? shapefileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parcel({
    required this.id,
    required this.name,
    required this.code,
    this.park,
    this.areaHa,
    this.latitude,
    this.longitude,
    this.notes,
    this.shapefileName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parcel.fromMap(Map<String, dynamic> map) => Parcel(
        id: map['id'] as String,
        name: map['name'] as String,
        code: map['code'] as String,
        park: map['park'] as String?,
        areaHa: map['area_ha'] as double?,
        latitude: map['latitude'] as double?,
        longitude: map['longitude'] as double?,
        notes: map['notes'] as String?,
        shapefileName: map['shapefile_name'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        'park': park,
        'area_ha': areaHa,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'shapefile_name': shapefileName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Parcel copyWith({
    String? name,
    String? park,
    double? areaHa,
    double? latitude,
    double? longitude,
    String? notes,
  }) =>
      Parcel(
        id: id,
        name: name ?? this.name,
        code: code,
        park: park ?? this.park,
        areaHa: areaHa ?? this.areaHa,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        notes: notes ?? this.notes,
        shapefileName: shapefileName,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}