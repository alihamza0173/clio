// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
///
/// The `claude` process is spawned lazily on the first layout-driven resize so
/// the pty starts at the terminal's real column/row count — spawning at a
/// default size first causes the TUI to reflow and duplicate its output.
///
/// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
/// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
/// previous frame's line count and repainting. xterm's reflow rewraps the
/// on-screen frame without moving the cursor with it, so claude's clear misses
/// the old frame (duplicate banner); debouncing the pty resize lets xterm's
/// buffer width drift from the pty width, so claude paints against a stale width
/// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
/// with the pty mirrors how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.

@ProviderFor(TerminalController)
final terminalControllerProvider = TerminalControllerFamily._();

/// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
///
/// The `claude` process is spawned lazily on the first layout-driven resize so
/// the pty starts at the terminal's real column/row count — spawning at a
/// default size first causes the TUI to reflow and duplicate its output.
///
/// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
/// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
/// previous frame's line count and repainting. xterm's reflow rewraps the
/// on-screen frame without moving the cursor with it, so claude's clear misses
/// the old frame (duplicate banner); debouncing the pty resize lets xterm's
/// buffer width drift from the pty width, so claude paints against a stale width
/// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
/// with the pty mirrors how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.
final class TerminalControllerProvider
    extends $NotifierProvider<TerminalController, Terminal> {
  /// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
  ///
  /// The `claude` process is spawned lazily on the first layout-driven resize so
  /// the pty starts at the terminal's real column/row count — spawning at a
  /// default size first causes the TUI to reflow and duplicate its output.
  ///
  /// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
  /// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
  /// previous frame's line count and repainting. xterm's reflow rewraps the
  /// on-screen frame without moving the cursor with it, so claude's clear misses
  /// the old frame (duplicate banner); debouncing the pty resize lets xterm's
  /// buffer width drift from the pty width, so claude paints against a stale width
  /// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
  /// with the pty mirrors how `claude` behaves in a real terminal.
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
  Override overrideWithValue(Terminal value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Terminal>(value),
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
    r'f844d71447f31086dba640d2d2d3e37e25e621c6';

/// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
///
/// The `claude` process is spawned lazily on the first layout-driven resize so
/// the pty starts at the terminal's real column/row count — spawning at a
/// default size first causes the TUI to reflow and duplicate its output.
///
/// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
/// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
/// previous frame's line count and repainting. xterm's reflow rewraps the
/// on-screen frame without moving the cursor with it, so claude's clear misses
/// the old frame (duplicate banner); debouncing the pty resize lets xterm's
/// buffer width drift from the pty width, so claude paints against a stale width
/// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
/// with the pty mirrors how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.

final class TerminalControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TerminalController,
          Terminal,
          Terminal,
          Terminal,
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

  /// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
  ///
  /// The `claude` process is spawned lazily on the first layout-driven resize so
  /// the pty starts at the terminal's real column/row count — spawning at a
  /// default size first causes the TUI to reflow and duplicate its output.
  ///
  /// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
  /// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
  /// previous frame's line count and repainting. xterm's reflow rewraps the
  /// on-screen frame without moving the cursor with it, so claude's clear misses
  /// the old frame (duplicate banner); debouncing the pty resize lets xterm's
  /// buffer width drift from the pty width, so claude paints against a stale width
  /// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
  /// with the pty mirrors how `claude` behaves in a real terminal.
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

/// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
///
/// The `claude` process is spawned lazily on the first layout-driven resize so
/// the pty starts at the terminal's real column/row count — spawning at a
/// default size first causes the TUI to reflow and duplicate its output.
///
/// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
/// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
/// previous frame's line count and repainting. xterm's reflow rewraps the
/// on-screen frame without moving the cursor with it, so claude's clear misses
/// the old frame (duplicate banner); debouncing the pty resize lets xterm's
/// buffer width drift from the pty width, so claude paints against a stale width
/// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
/// with the pty mirrors how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.

abstract class _$TerminalController extends $Notifier<Terminal> {
  late final _$args = ref.$arg as (String, String);
  String get projectId => _$args.$1;
  String get sessionId => _$args.$2;

  Terminal build(String projectId, String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Terminal, Terminal>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Terminal, Terminal>,
              Terminal,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
