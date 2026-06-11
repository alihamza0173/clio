class Project {
  const Project({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.hidden = false,
  });

  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final bool hidden;

  Project copyWith({String? name, bool? hidden}) => Project(
    id: id,
    name: name ?? this.name,
    path: path,
    createdAt: createdAt,
    hidden: hidden ?? this.hidden,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          other.id == id &&
          other.name == name &&
          other.path == path &&
          other.createdAt == createdAt &&
          other.hidden == hidden;

  @override
  int get hashCode => Object.hash(id, name, path, createdAt, hidden);
}
