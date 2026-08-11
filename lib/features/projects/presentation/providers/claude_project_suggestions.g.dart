// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_project_suggestions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Folders the user has already run claude in, offered when adding a project.

@ProviderFor(claudeProjectSuggestions)
final claudeProjectSuggestionsProvider = ClaudeProjectSuggestionsProvider._();

/// Folders the user has already run claude in, offered when adding a project.

final class ClaudeProjectSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClaudeProjectSummary>>,
          List<ClaudeProjectSummary>,
          FutureOr<List<ClaudeProjectSummary>>
        >
    with
        $FutureModifier<List<ClaudeProjectSummary>>,
        $FutureProvider<List<ClaudeProjectSummary>> {
  /// Folders the user has already run claude in, offered when adding a project.
  ClaudeProjectSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeProjectSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeProjectSuggestionsHash();

  @$internal
  @override
  $FutureProviderElement<List<ClaudeProjectSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClaudeProjectSummary>> create(Ref ref) {
    return claudeProjectSuggestions(ref);
  }
}

String _$claudeProjectSuggestionsHash() =>
    r'fa65da3485021853885b6b9bfd44084e6daa71b6';
