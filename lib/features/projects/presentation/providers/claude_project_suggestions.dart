import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/claude_session_service.dart';

part 'claude_project_suggestions.g.dart';

/// Folders the user has already run claude in, offered when adding a project.
@riverpod
Future<List<ClaudeProjectSummary>> claudeProjectSuggestions(Ref ref) =>
    ref.read(claudeSessionServiceProvider).discoverProjects();
