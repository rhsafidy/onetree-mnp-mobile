class Tourist {
  final String id;
  final String name;
  final String? email;
  final String? nationality;
  final String? phone;
  final DateTime createdAt;

  const Tourist({
    required this.id,
    required this.name,
    this.email,
    this.nationality,
    this.phone,
    required this.createdAt,
  });

  factory Tourist.fromMap(Map<String, dynamic> map) => Tourist(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String?,
        nationality: map['nationality'] as String?,
        phone: map['phone'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'nationality': nationality,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  Tourist copyWith({
    String? name,
    String? email,
    String? nationality,
    String? phone,
  }) =>
      Tourist(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        nationality: nationality ?? this.nationality,
        phone: phone ?? this.phone,
        createdAt: createdAt,
      );
}