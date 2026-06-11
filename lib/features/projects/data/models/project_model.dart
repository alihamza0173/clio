import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.name,
    required super.path,
    required super.createdAt,
    super.hidden,
  });

  factory ProjectModel.fromEntity(Project project) => ProjectModel(
    id: project.id,
    name: project.name,
    path: project.path,
    createdAt: project.createdAt,
    hidden: project.hidden,
  );

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    hidden: json['hidden'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'createdAt': createdAt.toIso8601String(),
    'hidden': hidden,
  };
}
