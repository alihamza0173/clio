// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_chat_suggestions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Past claude conversations for a project that aren't already open as tabs.
/// Two ptys resuming one transcript would fight over the same file, so anything
/// clio already holds is excluded rather than shown disabled.

@ProviderFor(claudeChatSuggestions)
final claudeChatSuggestionsProvider = ClaudeChatSuggestionsFamily._();

/// Past claude conversations for a project that aren't already open as tabs.
/// Two ptys resuming one transcript would fight over the same file, so anything
/// clio already holds is excluded rather than shown disabled.

final class ClaudeChatSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClaudeChatSummary>>,
          List<ClaudeChatSummary>,
          FutureOr<List<ClaudeChatSummary>>
        >
    with
        $FutureModifier<List<ClaudeChatSummary>>,
        $FutureProvider<List<ClaudeChatSummary>> {
  /// Past claude conversations for a project that aren't already open as tabs.
  /// Two ptys resuming one transcript would fight over the same file, so anything
  /// clio already holds is excluded rather than shown disabled.
  ClaudeChatSuggestionsProvider._({
    required ClaudeChatSuggestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'claudeChatSuggestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$claudeChatSuggestionsHash();

  @override
  String toString() {
    return r'claudeChatSuggestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClaudeChatSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClaudeChatSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return claudeChatSuggestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClaudeChatSuggestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$claudeChatSuggestionsHash() =>
    r'b331492f570ea73d6c427fcad78f08e1d02e803d';

/// Past claude conversations for a project that aren't already open as tabs.
/// Two ptys resuming one transcript would fight over the same file, so anything
/// clio already holds is excluded rather than shown disabled.

final class ClaudeChatSuggestionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ClaudeChatSummary>>, String> {
  ClaudeChatSuggestionsFamily._()
    : super(
        retry: null,
        name: r'claudeChatSuggestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Past claude conversations for a project that aren't already open as tabs.
  /// Two ptys resuming one transcript would fight over the same file, so anything
  /// clio already holds is excluded rather than shown disabled.

  ClaudeChatSuggestionsProvider call(String projectId) =>
      ClaudeChatSuggestionsProvider._(argument: projectId, from: this);

  @override
  String toString() => r'claudeChatSuggestionsProvider';
}
