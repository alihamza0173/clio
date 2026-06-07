import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/terminal_controller.dart';
import 'web_terminal_view.dart';

class SessionTerminalView extends ConsumerWidget {
  const SessionTerminalView({
    super.key,
    required this.projectId,
    required this.sessionId,
    required this.active,
  });

  final String projectId;
  final String sessionId;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridge = ref.watch(terminalControllerProvider(projectId, sessionId));
    return ColoredBox(
      color: AppColors.background,
      child: DropTarget(
        onDragDone: (detail) {
          final paths = <String>[];
          for (final file in detail.files) {
            final path = file.path;
            if (path.isEmpty) continue;
            paths.add(path.contains(RegExp(r'\s')) ? "'$path'" : path);
          }
          if (paths.isNotEmpty) {
            bridge.handleInput(utf8.encode('${paths.join(' ')} '));
          }
        },
        child: Directionality(
          textDirection: .ltr,
          child: WebTerminalView(bridge: bridge, active: active),
        ),
      ),
    );
  }
}
