// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$discoveryRepositoryHash() =>
    r'0572d651b3648ab50299f65c3e5fb6ed14cb7620';

/// See also [discoveryRepository].
@ProviderFor(discoveryRepository)
final discoveryRepositoryProvider =
    AutoDisposeProvider<DiscoveryRepository>.internal(
      discoveryRepository,
      name: r'discoveryRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$discoveryRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiscoveryRepositoryRef = AutoDisposeProviderRef<DiscoveryRepository>;
String _$nearbyUsersHash() => r'b27d296bb2a5b43ac1c8928d76168fcd748a8917';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [nearbyUsers].
@ProviderFor(nearbyUsers)
const nearbyUsersProvider = NearbyUsersFamily();

/// See also [nearbyUsers].
class NearbyUsersFamily extends Family<AsyncValue<List<NearbyUser>>> {
  /// See also [nearbyUsers].
  const NearbyUsersFamily();

  /// See also [nearbyUsers].
  NearbyUsersProvider call({required String currentUserId}) {
    return NearbyUsersProvider(currentUserId: currentUserId);
  }

  @override
  NearbyUsersProvider getProviderOverride(
    covariant NearbyUsersProvider provider,
  ) {
    return call(currentUserId: provider.currentUserId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'nearbyUsersProvider';
}

/// See also [nearbyUsers].
class NearbyUsersProvider extends AutoDisposeStreamProvider<List<NearbyUser>> {
  /// See also [nearbyUsers].
  NearbyUsersProvider({required String currentUserId})
    : this._internal(
        (ref) =>
            nearbyUsers(ref as NearbyUsersRef, currentUserId: currentUserId),
        from: nearbyUsersProvider,
        name: r'nearbyUsersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$nearbyUsersHash,
        dependencies: NearbyUsersFamily._dependencies,
        allTransitiveDependencies: NearbyUsersFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  NearbyUsersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.currentUserId,
  }) : super.internal();

  final String currentUserId;

  @override
  Override overrideWith(
    Stream<List<NearbyUser>> Function(NearbyUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NearbyUsersProvider._internal(
        (ref) => create(ref as NearbyUsersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<NearbyUser>> createElement() {
    return _NearbyUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyUsersProvider && other.currentUserId == currentUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, currentUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NearbyUsersRef on AutoDisposeStreamProviderRef<List<NearbyUser>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _NearbyUsersProviderElement
    extends AutoDisposeStreamProviderElement<List<NearbyUser>>
    with NearbyUsersRef {
  _NearbyUsersProviderElement(super.provider);

  @override
  String get currentUserId => (origin as NearbyUsersProvider).currentUserId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
