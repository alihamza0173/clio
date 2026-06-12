// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_status.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative) with a pty-output silence watchdog that
/// only demotes a stale busy — `Stop` never fires when the user interrupts.

@ProviderFor(SessionStatusNotifier)
final sessionStatusProvider = SessionStatusNotifierFamily._();

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative) with a pty-output silence watchdog that
/// only demotes a stale busy — `Stop` never fires when the user interrupts.
final class SessionStatusNotifierProvider
    extends $NotifierProvider<SessionStatusNotifier, SessionStatus> {
  /// Live activity state for one session's `claude` turn, driven by injected
  /// Claude Code hooks (authoritative) with a pty-output silence watchdog that
  /// only demotes a stale busy — `Stop` never fires when the user interrupts.
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
    r'581dec1d14f83a9098ec518a45e8bedd8d4fd908';

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative) with a pty-output silence watchdog that
/// only demotes a stale busy — `Stop` never fires when the user interrupts.

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
  /// Claude Code hooks (authoritative) with a pty-output silence watchdog that
  /// only demotes a stale busy — `Stop` never fires when the user interrupts.

  SessionStatusNotifierProvider call(String projectId, String sessionId) =>
      SessionStatusNotifierProvider._(
        argument: (projectId, sessionId),
        from: this,
      );

  @override
  String toString() => r'sessionStatusProvider';
}

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative) with a pty-output silence watchdog that
/// only demotes a stale busy — `Stop` never fires when the user interrupts.

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
