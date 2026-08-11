import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/services/claude_session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_dialog_shell.dart';
import '../../../../core/widgets/suggestion_tile.dart';
import '../../domain/entities/project.dart';
import '../providers/claude_project_suggestions.dart';
import '../providers/projects_notifier.dart';

/// Folder picker that leads with the projects claude already has history for,
/// falling back to the OS browser for anything new.
class AddProjectDialog extends ConsumerStatefulWidget {
  const AddProjectDialog({super.key});

  static Future<String?> show(BuildContext context) => showDialog<String>(
    context: context,
    builder: (_) => const AddProjectDialog(),
  );

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggestionsAsync = ref.watch(claudeProjectSuggestionsProvider);
    final existing = {
      for (final project
          in ref.watch(projectsProvider).value ?? const <Project>[])
        project.path,
    };

    return AppDialogShell(
      title: l10n.addProject,
      footer: Padding(
        padding: const .fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _browse,
              icon: const Icon(
                Icons.folder_open,
                size: 14,
                color: AppColors.primary,
              ),
              label: Text(
                l10n.browseForFolder,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _search,
              autofocus: true,
              style: AppTypography.tab.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.searchFoldersHint,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Padding(
            padding: const .fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.fromClaudeHistory.toUpperCase(),
              style: AppTypography.label,
            ),
          ),
          Expanded(
            child: suggestionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (e, _) => _message('$e'),
              data: (suggestions) =>
                  _buildList(l10n, _visible(suggestions, existing), existing),
            ),
          ),
        ],
      ),
    );
  }

  /// Matches on name and path, and sinks already-added folders to the bottom so
  /// the actionable rows stay in reach.
  List<ClaudeProjectSummary> _visible(
    List<ClaudeProjectSummary> suggestions,
    Set<String> existing,
  ) {
    final query = _query.toLowerCase();
    final available = <ClaudeProjectSummary>[];
    final added = <ClaudeProjectSummary>[];
    for (final suggestion in suggestions) {
      if (query.isNotEmpty &&
          !suggestion.name.toLowerCase().contains(query) &&
          !suggestion.path.toLowerCase().contains(query)) {
        continue;
      }
      if (existing.contains(suggestion.path)) {
        added.add(suggestion);
      } else {
        available.add(suggestion);
      }
    }
    return [...available, ...added];
  }

  Widget _buildList(
    AppLocalizations l10n,
    List<ClaudeProjectSummary> suggestions,
    Set<String> existing,
  ) {
    if (suggestions.isEmpty) return _message(l10n.noProjectSuggestions);

    return ListView.builder(
      padding: .zero,
      itemCount: suggestions.length,
      itemBuilder: (_, i) {
        final suggestion = suggestions[i];
        final added = existing.contains(suggestion.path);
        return SuggestionTile(
          icon: Icons.folder_outlined,
          title: suggestion.name,
          subtitle: _displayPath(suggestion.path),
          meta:
              '${l10n.chatCount(suggestion.chatCount)} · '
              '${formatRelativeTime(l10n, suggestion.lastActiveAt)}',
          onTap: added
              ? null
              : () => Navigator.of(context).pop(suggestion.path),
          trailing: added
              ? Row(
                  mainAxisSize: .min,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.accentGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(l10n.projectAlreadyAdded, style: AppTypography.label),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _message(String text) => Padding(
    padding: const .all(16),
    child: Text(text, style: AppTypography.label),
  );

  Future<void> _browse() async {
    final path = await getDirectoryPath();
    if (path == null || !mounted) return;
    Navigator.of(context).pop(path);
  }

  String _displayPath(String path) {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty && path.startsWith(home)) {
      return '~${path.substring(home.length)}';
    }
    return path;
  }
}
