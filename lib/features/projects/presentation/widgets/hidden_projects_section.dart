import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/project.dart';
import '../providers/projects_notifier.dart';
import 'project_tile.dart';

class HiddenProjectsSection extends ConsumerWidget {
  const HiddenProjectsSection({
    super.key,
    required this.projects,
    required this.selectedId,
  });

  final List<Project> projects;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projects.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final expanded = ref.watch(hiddenSectionExpandedProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          InkWell(
            onTap: () =>
                ref.read(hiddenSectionExpandedProvider.notifier).toggle(),
            child: Padding(
              padding: const .symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.expand_more,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.hiddenProjectsHeader(projects.length).toUpperCase(),
                    style: AppTypography.label,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: .topCenter,
            child: expanded
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView(
                      padding: .zero,
                      shrinkWrap: true,
                      children: [
                        for (final project in projects)
                          ProjectTile(
                            project: project,
                            selected: project.id == selectedId,
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
