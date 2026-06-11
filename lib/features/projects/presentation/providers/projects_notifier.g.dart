// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projects_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(projectRepository)
final projectRepositoryProvider = ProjectRepositoryProvider._();

final class ProjectRepositoryProvider
    extends
        $FunctionalProvider<
          ProjectRepository,
          ProjectRepository,
          ProjectRepository
        >
    with $Provider<ProjectRepository> {
  ProjectRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProjectRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProjectRepository create(Ref ref) {
    return projectRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectRepository>(value),
    );
  }
}

String _$projectRepositoryHash() => r'9f026790f40764cc5377c0d24f6db45e631daacb';

@ProviderFor(ProjectsNotifier)
final projectsProvider = ProjectsNotifierProvider._();

final class ProjectsNotifierProvider
    extends $AsyncNotifierProvider<ProjectsNotifier, List<Project>> {
  ProjectsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectsNotifierHash();

  @$internal
  @override
  ProjectsNotifier create() => ProjectsNotifier();
}

String _$projectsNotifierHash() => r'e88084d862a16c5e55112a4f0c1058c264886dfb';

abstract class _$ProjectsNotifier extends $AsyncNotifier<List<Project>> {
  FutureOr<List<Project>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Project>>, List<Project>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Project>>, List<Project>>,
              AsyncValue<List<Project>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(HiddenSectionExpanded)
final hiddenSectionExpandedProvider = HiddenSectionExpandedProvider._();

final class HiddenSectionExpandedProvider
    extends $NotifierProvider<HiddenSectionExpanded, bool> {
  HiddenSectionExpandedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hiddenSectionExpandedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hiddenSectionExpandedHash();

  @$internal
  @override
  HiddenSectionExpanded create() => HiddenSectionExpanded();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hiddenSectionExpandedHash() =>
    r'2a0713d2b737405618785cd7ff861decbd46469b';

abstract class _$HiddenSectionExpanded extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedProjectId)
final selectedProjectIdProvider = SelectedProjectIdProvider._();

final class SelectedProjectIdProvider
    extends $NotifierProvider<SelectedProjectId, String?> {
  SelectedProjectIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedProjectIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedProjectIdHash();

  @$internal
  @override
  SelectedProjectId create() => SelectedProjectId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedProjectIdHash() => r'e8a93d6c7c4799d4084e1951403989a236cfd48d';

abstract class _$SelectedProjectId extends $Notifier<String?> {
  String? build();
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
    element.handleCreate(ref, build);
  }
}
