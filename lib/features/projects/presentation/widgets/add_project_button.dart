import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/projects_notifier.dart';

class AddProjectButton extends ConsumerWidget {
  const AddProjectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _pickAndAdd(ref),
        icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
        label: Text(
          l10n.addProject,
          style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
        ),
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: const RoundedRectangleBorder(),
        ),
      ),
    );
  }

  Future<void> _pickAndAdd(WidgetRef ref) async {
    final path = await getDirectoryPath();
    if (path == null) return;
    final notifier = ref.read(projectsProvider.notifier);
    await notifier.addProjectByPath(path);
  }
}
