// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
///
/// `claude` is spawned lazily on the first ready handshake so the pty starts at
/// the renderer's real column/row count — spawning at a default size first makes
/// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
/// synchronously (no debounce) so the pty width never drifts from what xterm.js
/// is painting, mirroring how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.

@ProviderFor(TerminalController)
final terminalControllerProvider = TerminalControllerFamily._();

/// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
///
/// `claude` is spawned lazily on the first ready handshake so the pty starts at
/// the renderer's real column/row count — spawning at a default size first makes
/// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
/// synchronously (no debounce) so the pty width never drifts from what xterm.js
/// is painting, mirroring how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.
final class TerminalControllerProvider
    extends $NotifierProvider<TerminalController, TerminalBridge> {
  /// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
  ///
  /// `claude` is spawned lazily on the first ready handshake so the pty starts at
  /// the renderer's real column/row count — spawning at a default size first makes
  /// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
  /// synchronously (no debounce) so the pty width never drifts from what xterm.js
  /// is painting, mirroring how `claude` behaves in a real terminal.
  ///
  /// Kept alive so switching between session tabs does not kill the running
  /// `claude` process; disposed (and the pty killed) only when the session is
  /// removed via [ref.invalidate] or the app shuts down.
  TerminalControllerProvider._({
    required TerminalControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'terminalControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$terminalControllerHash();

  @override
  String toString() {
    return r'terminalControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TerminalController create() => TerminalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalBridge>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$terminalControllerHash() =>
    r'18f4bbd2c4d662a3e0900ba029c5649611c10460';

/// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
///
/// `claude` is spawned lazily on the first ready handshake so the pty starts at
/// the renderer's real column/row count — spawning at a default size first makes
/// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
/// synchronously (no debounce) so the pty width never drifts from what xterm.js
/// is painting, mirroring how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.

final class TerminalControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TerminalController,
          TerminalBridge,
          TerminalBridge,
          TerminalBridge,
          (String, String)
        > {
  TerminalControllerFamily._()
    : super(
        retry: null,
        name: r'terminalControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
  ///
  /// `claude` is spawned lazily on the first ready handshake so the pty starts at
  /// the renderer's real column/row count — spawning at a default size first makes
  /// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
  /// synchronously (no debounce) so the pty width never drifts from what xterm.js
  /// is painting, mirroring how `claude` behaves in a real terminal.
  ///
  /// Kept alive so switching between session tabs does not kill the running
  /// `claude` process; disposed (and the pty killed) only when the session is
  /// removed via [ref.invalidate] or the app shuts down.

  TerminalControllerProvider call(String projectId, String sessionId) =>
      TerminalControllerProvider._(
        argument: (projectId, sessionId),
        from: this,
      );

  @override
  String toString() => r'terminalControllerProvider';
}

/// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
///
/// `claude` is spawned lazily on the first ready handshake so the pty starts at
/// the renderer's real column/row count — spawning at a default size first makes
/// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
/// synchronously (no debounce) so the pty width never drifts from what xterm.js
/// is painting, mirroring how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.

abstract class _$TerminalController extends $Notifier<TerminalBridge> {
  late final _$args = ref.$arg as (String, String);
  String get projectId => _$args.$1;
  String get sessionId => _$args.$2;

  TerminalBridge build(String projectId, String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TerminalBridge, TerminalBridge>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TerminalBridge, TerminalBridge>,
              TerminalBridge,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
