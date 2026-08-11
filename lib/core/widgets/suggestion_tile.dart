import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Two-line row used by the suggestion dialogs, styled after the project rail
/// tiles so picking a folder or a chat feels like the list it lands in.
class SuggestionTile extends StatefulWidget {
  const SuggestionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final trailing = widget.trailing;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: _hovered && enabled
              ? AppColors.background
              : Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const .symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: AppTypography.tab.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
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
                  const SizedBox(width: 12),
                  if (trailing != null)
                    trailing
                  else
                    Text(widget.meta, style: AppTypography.label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
