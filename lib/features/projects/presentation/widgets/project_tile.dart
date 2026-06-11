import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/project.dart';
import '../providers/projects_notifier.dart';

class ProjectTile extends ConsumerStatefulWidget {
  const ProjectTile({super.key, required this.project, required this.selected});

  final Project project;
  final bool selected;

  @override
  ConsumerState<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends ConsumerState<ProjectTile> {
  bool _hovered = false;

  Project get _project => widget.project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            _showContextMenu(details.globalPosition, l10n),
        child: Material(
          color: widget.selected || _hovered
              ? AppColors.background
              : Colors.transparent,
          child: InkWell(
            onTap: () => ref
                .read(selectedProjectIdProvider.notifier)
                .select(_project.id),
            hoverColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(
                    color: widget.selected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const .symmetric(horizontal: 12, vertical: 10),
                    child: Opacity(
                      opacity: _project.hidden ? 0.55 : 1,
                      child: Row(
                        children: [
                          Icon(
                            _project.hidden
                                ? Icons.folder_off_outlined
                                : Icons.folder_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                Text(
                                  _project.name,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                  style: AppTypography.tab.copyWith(
                                    color: widget.selected
                                        ? AppColors.textPrimary
                                        : AppColors.textSubtle,
                                  ),
                                ),
                                Text(
                                  _project.path,
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
                        ],
                      ),
                    ),
                  ),
                  if (_hovered)
                    PositionedDirectional(
                      top: 0,
                      bottom: 0,
                      end: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            colors: [
                              AppColors.background.withValues(alpha: 0),
                              AppColors.background,
                              AppColors.background,
                            ],
                            stops: const [0, 0.35, 1],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 20,
                            end: 6,
                          ),
                          child: Row(
                            mainAxisSize: .min,
                            children: [
                              _ActionIcon(
                                icon: _project.hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                tooltip: _project.hidden
                                    ? l10n.unhideProject
                                    : l10n.hideProject,
                                onPressed: () => _setHidden(!_project.hidden),
                              ),
                              _ActionIcon(
                                icon: Icons.close,
                                tooltip: l10n.removeProject,
                                onPressed: () => _confirmRemove(l10n),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setHidden(bool hidden) {
    if (hidden && ref.read(selectedProjectIdProvider) == _project.id) {
      ref.read(hiddenSectionExpandedProvider.notifier).set(true);
    }
    ref.read(projectsProvider.notifier).setProjectHidden(_project.id, hidden);
  }

  Future<void> _showContextMenu(Offset position, AppLocalizations l10n) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_TileAction>(
      context: context,
      color: AppColors.surface,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _TileAction.toggleHidden,
          height: 36,
          child: Text(
            _project.hidden ? l10n.unhideProject : l10n.hideProject,
            style: AppTypography.tab.copyWith(color: AppColors.textSubtle),
          ),
        ),
        PopupMenuItem(
          value: _TileAction.remove,
          height: 36,
          child: Text(
            l10n.removeProject,
            style: AppTypography.tab.copyWith(color: AppColors.accentOrange),
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _TileAction.toggleHidden:
        _setHidden(!_project.hidden);
      case _TileAction.remove:
        await _confirmRemove(l10n);
      case null:
        break;
    }
  }

  Future<void> _confirmRemove(AppLocalizations l10n) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        backgroundColor: AppColors.surface,
        content: Text(l10n.removeProjectConfirm(_project.name)),
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
    if (ref.read(selectedProjectIdProvider) == _project.id) {
      selectedNotifier.select(null);
    }
    await ref.read(projectsProvider.notifier).removeProject(_project.id);
  }
}

enum _TileAction { toggleHidden, remove }

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: IconButton(
        padding: .zero,
        icon: Icon(icon, size: 13),
        color: AppColors.textMuted,
        splashRadius: 12,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
