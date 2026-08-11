import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Chrome for clio's list-style dialogs: a titled panel with a scrollable body
/// and an optional footer. Deliberately not `AlertDialog.adaptive` — on macOS
/// that renders a narrow `CupertinoAlertDialog`, which can't host a search
/// field above a scrolling list.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.width = 520,
    this.maxHeight = 460,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final footer = this.footer;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: const .fromLTRB(16, 12, 12, 12),
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(title.toUpperCase(), style: AppTypography.label),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    color: AppColors.textSecondary,
                    padding: .zero,
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    splashRadius: 12,
                    visualDensity: .compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.5),
            Flexible(child: child),
            if (footer != null) ...[const Divider(height: 0.5), footer],
          ],
        ),
      ),
    );
  }
}
