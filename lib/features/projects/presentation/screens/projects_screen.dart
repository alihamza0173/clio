import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../sessions/presentation/screens/project_sessions_screen.dart';
import '../../domain/entities/project.dart';
import '../providers/projects_notifier.dart';
import '../widgets/project_tile.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    final selectedId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Padding(
                  padding: const .fromLTRB(12, 14, 12, 8),
                  child: Text(
                    l10n.projectsTitle.toUpperCase(),
                    style: AppTypography.label,
                  ),
                ),
                Expanded(
                  child: projectsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (e, _) => Padding(
                      padding: const .all(12),
                      child: Text('$e', style: AppTypography.label),
                    ),
                    data: (projects) => _ProjectsList(
                      projects: projects,
                      selectedId: selectedId,
                      emptyLabel: l10n.noProjects,
                    ),
                  ),
                ),
                const Divider(height: 0.5),
                TextButton.icon(
                  onPressed: () => _pickAndAdd(ref),
                  icon: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    l10n.addProject,
                    style: const TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: .centerLeft,
                    padding: const .symmetric(horizontal: 12, vertical: 12),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 0.5, color: AppColors.border),
          Expanded(
            child: _detail(context, l10n, projectsAsync.value, selectedId),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAdd(WidgetRef ref) async {
    final path = await getDirectoryPath();
    if (path == null) return;
    final notifier = ref.read(projectsProvider.notifier);
    await notifier.addProjectByPath(path);
  }

  Widget _detail(
    BuildContext context,
    AppLocalizations l10n,
    List<Project>? projects,
    String? selectedId,
  ) {
    final selected = _selectedProject(projects, selectedId);
    if (selected == null) {
      return Center(
        child: Text(l10n.noSessionSelected, style: AppTypography.label),
      );
    }
    return ProjectSessionsScreen(project: selected);
  }

  Project? _selectedProject(List<Project>? projects, String? selectedId) {
    if (projects == null || selectedId == null) return null;
    for (final p in projects) {
      if (p.id == selectedId) return p;
    }
    return null;
  }
}

class _ProjectsList extends StatelessWidget {
  const _ProjectsList({
    required this.projects,
    required this.selectedId,
    required this.emptyLabel,
  });

  final List<Project> projects;
  final String? selectedId;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Padding(
        padding: const .all(12),
        child: Text(emptyLabel, style: AppTypography.label),
      );
    }
    return ListView.builder(
      padding: .zero,
      itemCount: projects.length,
      itemBuilder: (_, i) => ProjectTile(
        project: projects[i],
        selected: projects[i].id == selectedId,
      ),
    );
  }
}
