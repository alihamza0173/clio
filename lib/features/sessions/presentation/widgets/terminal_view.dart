import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/terminal_controller.dart';

class SessionTerminalView extends ConsumerWidget {
  const SessionTerminalView({
    super.key,
    required this.projectId,
    required this.sessionId,
  });

  final String projectId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminal = ref.watch(
      terminalControllerProvider(projectId, sessionId),
    );
    return ColoredBox(
      color: AppColors.background,
      child: Directionality(
        textDirection: .ltr,
        child: TerminalView(
          terminal,
          autofocus: true,
          padding: const EdgeInsets.all(8),
          theme: TerminalThemes.defaultTheme,
          textStyle: const TerminalStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
