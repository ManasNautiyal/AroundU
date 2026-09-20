// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ghostModeControllerHash() =>
    r'172f5ba7a1e6edde72b11fb775c2c87ed7f3e756';

/// See also [GhostModeController].
@ProviderFor(GhostModeController)
final ghostModeControllerProvider =
    AutoDisposeNotifierProvider<GhostModeController, bool>.internal(
      GhostModeController.new,
      name: r'ghostModeControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ghostModeControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$GhostModeController = AutoDisposeNotifier<bool>;

String _$discoveryRangeFilterHash() =>
    r'e20f55c6f74f79a38f9a9c66805cd91e4a6cc33e';

/// Holds the user's chosen discovery range in meters (50 – 500 m).
/// Defaults to 500 m so all nearby users are visible initially.
///
/// Copied from [DiscoveryRangeFilter].
@ProviderFor(DiscoveryRangeFilter)
final discoveryRangeFilterProvider =
    AutoDisposeNotifierProvider<DiscoveryRangeFilter, double>.internal(
      DiscoveryRangeFilter.new,
      name: r'discoveryRangeFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$discoveryRangeFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DiscoveryRangeFilter = AutoDisposeNotifier<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
