import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/project.dart';
import '../providers/projects_notifier.dart';

class ProjectTile extends ConsumerWidget {
  const ProjectTile({super.key, required this.project, required this.selected});

  final Project project;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: selected ? AppColors.background : Colors.transparent,
      child: InkWell(
        onTap: () =>
            ref.read(selectedProjectIdProvider.notifier).select(project.id),
        child: Container(
          padding: const .symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: AppTypography.tab.copyWith(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSubtle,
                      ),
                    ),
                    Text(
                      project.path,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 13),
                color: AppColors.textMuted,
                splashRadius: 12,
                tooltip: l10n.removeProject,
                onPressed: () => _confirmRemove(context, ref, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        backgroundColor: AppColors.surface,
        content: Text(l10n.removeProjectConfirm(project.name)),
        actions: [
          if (Platform.isMacOS) ...[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: Text(l10n.remove),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.remove),
            ),
          ],
        ],
      ),
    );
    if (confirmed != true) return;
    final selectedNotifier = ref.read(selectedProjectIdProvider.notifier);
    if (ref.read(selectedProjectIdProvider) == project.id) {
      selectedNotifier.select(null);
    }
    await ref.read(projectsProvider.notifier).removeProject(project.id);
  }
}
