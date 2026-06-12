// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectNeedsAttention)
final projectNeedsAttentionProvider = ProjectNeedsAttentionFamily._();

final class ProjectNeedsAttentionProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  ProjectNeedsAttentionProvider._({
    required ProjectNeedsAttentionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectNeedsAttentionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectNeedsAttentionHash();

  @override
  String toString() {
    return r'projectNeedsAttentionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return projectNeedsAttention(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectNeedsAttentionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectNeedsAttentionHash() =>
    r'ed1a241ef01aad4ee7aacf18f5802fcdebacfcda';

final class ProjectNeedsAttentionFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  ProjectNeedsAttentionFamily._()
    : super(
        retry: null,
        name: r'projectNeedsAttentionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProjectNeedsAttentionProvider call(String projectId) =>
      ProjectNeedsAttentionProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectNeedsAttentionProvider';
}

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative). `Stop` never fires when the user
/// interrupts, and the idle TUI keeps repainting (so output silence can't be
/// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
/// with the silence watchdog kept only as a backstop for dead sessions.

@ProviderFor(SessionStatusNotifier)
final sessionStatusProvider = SessionStatusNotifierFamily._();

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative). `Stop` never fires when the user
/// interrupts, and the idle TUI keeps repainting (so output silence can't be
/// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
/// with the silence watchdog kept only as a backstop for dead sessions.
final class SessionStatusNotifierProvider
    extends $NotifierProvider<SessionStatusNotifier, SessionStatus> {
  /// Live activity state for one session's `claude` turn, driven by injected
  /// Claude Code hooks (authoritative). `Stop` never fires when the user
  /// interrupts, and the idle TUI keeps repainting (so output silence can't be
  /// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
  /// with the silence watchdog kept only as a backstop for dead sessions.
  SessionStatusNotifierProvider._({
    required SessionStatusNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'sessionStatusProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionStatusNotifierHash();

  @override
  String toString() {
    return r'sessionStatusProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SessionStatusNotifier create() => SessionStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionStatusNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionStatusNotifierHash() =>
    r'35ed6e4b45edef3e12c9e6355155633d642dc9f5';

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative). `Stop` never fires when the user
/// interrupts, and the idle TUI keeps repainting (so output silence can't be
/// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
/// with the silence watchdog kept only as a backstop for dead sessions.

final class SessionStatusNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionStatusNotifier,
          SessionStatus,
          SessionStatus,
          SessionStatus,
          (String, String)
        > {
  SessionStatusNotifierFamily._()
    : super(
        retry: null,
        name: r'sessionStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Live activity state for one session's `claude` turn, driven by injected
  /// Claude Code hooks (authoritative). `Stop` never fires when the user
  /// interrupts, and the idle TUI keeps repainting (so output silence can't be
  /// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
  /// with the silence watchdog kept only as a backstop for dead sessions.

  SessionStatusNotifierProvider call(String projectId, String sessionId) =>
      SessionStatusNotifierProvider._(
        argument: (projectId, sessionId),
        from: this,
      );

  @override
  String toString() => r'sessionStatusProvider';
}

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative). `Stop` never fires when the user
/// interrupts, and the idle TUI keeps repainting (so output silence can't be
/// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
/// with the silence watchdog kept only as a backstop for dead sessions.

abstract class _$SessionStatusNotifier extends $Notifier<SessionStatus> {
  late final _$args = ref.$arg as (String, String);
  String get projectId => _$args.$1;
  String get sessionId => _$args.$2;

  SessionStatus build(String projectId, String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SessionStatus, SessionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionStatus, SessionStatus>,
              SessionStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
