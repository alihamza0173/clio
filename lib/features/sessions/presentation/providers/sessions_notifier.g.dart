// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRepository)
final sessionRepositoryProvider = SessionRepositoryProvider._();

final class SessionRepositoryProvider
    extends
        $FunctionalProvider<
          SessionRepository,
          SessionRepository,
          SessionRepository
        >
    with $Provider<SessionRepository> {
  SessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRepository create(Ref ref) {
    return sessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRepository>(value),
    );
  }
}

String _$sessionRepositoryHash() => r'ca9025b6d9073134470cbdb831150d56b2901806';

@ProviderFor(SessionsNotifier)
final sessionsProvider = SessionsNotifierFamily._();

final class SessionsNotifierProvider
    extends $AsyncNotifierProvider<SessionsNotifier, List<Session>> {
  SessionsNotifierProvider._({
    required SessionsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionsNotifierHash();

  @override
  String toString() {
    return r'sessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionsNotifier create() => SessionsNotifier();

  @override
  bool operator ==(Object other) {
    return other is SessionsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionsNotifierHash() => r'c39758facb1aad91d5ae80fe6f1b8b3b13f222c7';

final class SessionsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionsNotifier,
          AsyncValue<List<Session>>,
          List<Session>,
          FutureOr<List<Session>>,
          String
        > {
  SessionsNotifierFamily._()
    : super(
        retry: null,
        name: r'sessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionsNotifierProvider call(String projectId) =>
      SessionsNotifierProvider._(argument: projectId, from: this);

  @override
  String toString() => r'sessionsProvider';
}

abstract class _$SessionsNotifier extends $AsyncNotifier<List<Session>> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  FutureOr<List<Session>> build(String projectId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Session>>, List<Session>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Session>>, List<Session>>,
              AsyncValue<List<Session>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ActiveSessionId)
final activeSessionIdProvider = ActiveSessionIdFamily._();

final class ActiveSessionIdProvider
    extends $NotifierProvider<ActiveSessionId, String?> {
  ActiveSessionIdProvider._({
    required ActiveSessionIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activeSessionIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeSessionIdHash();

  @override
  String toString() {
    return r'activeSessionIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveSessionId create() => ActiveSessionId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveSessionIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeSessionIdHash() => r'3e5bc160ab5eb0aa00e5a1c7fded2dbc3a170e9b';

final class ActiveSessionIdFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveSessionId,
          String?,
          String?,
          String?,
          String
        > {
  ActiveSessionIdFamily._()
    : super(
        retry: null,
        name: r'activeSessionIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveSessionIdProvider call(String projectId) =>
      ActiveSessionIdProvider._(argument: projectId, from: this);

  @override
  String toString() => r'activeSessionIdProvider';
}

abstract class _$ActiveSessionId extends $Notifier<String?> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  String? build(String projectId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
