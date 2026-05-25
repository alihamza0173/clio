class Project {
  const Project({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String path;
  final DateTime createdAt;

  Project copyWith({String? name}) => Project(
        id: id,
        name: name ?? this.name,
        path: path,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          other.id == id &&
          other.name == name &&
          other.path == path &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, path, createdAt);
}
