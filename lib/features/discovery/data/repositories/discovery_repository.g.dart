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
String _$rawNearbyUsersHash() => r'1b07a3af86edb1f76cfb38c51034272ae068af12';

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

/// Stable raw geo-stream that only depends on the user's position.
/// This avoids tearing down and re-subscribing the Firestore listener
/// every time a client-side filter (range, ghost mode, blocked) changes.
///
/// Copied from [rawNearbyUsers].
@ProviderFor(rawNearbyUsers)
const rawNearbyUsersProvider = RawNearbyUsersFamily();

/// Stable raw geo-stream that only depends on the user's position.
/// This avoids tearing down and re-subscribing the Firestore listener
/// every time a client-side filter (range, ghost mode, blocked) changes.
///
/// Copied from [rawNearbyUsers].
class RawNearbyUsersFamily extends Family<AsyncValue<List<NearbyUser>>> {
  /// Stable raw geo-stream that only depends on the user's position.
  /// This avoids tearing down and re-subscribing the Firestore listener
  /// every time a client-side filter (range, ghost mode, blocked) changes.
  ///
  /// Copied from [rawNearbyUsers].
  const RawNearbyUsersFamily();

  /// Stable raw geo-stream that only depends on the user's position.
  /// This avoids tearing down and re-subscribing the Firestore listener
  /// every time a client-side filter (range, ghost mode, blocked) changes.
  ///
  /// Copied from [rawNearbyUsers].
  RawNearbyUsersProvider call({required String currentUserId}) {
    return RawNearbyUsersProvider(currentUserId: currentUserId);
  }

  @override
  RawNearbyUsersProvider getProviderOverride(
    covariant RawNearbyUsersProvider provider,
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
  String? get name => r'rawNearbyUsersProvider';
}

/// Stable raw geo-stream that only depends on the user's position.
/// This avoids tearing down and re-subscribing the Firestore listener
/// every time a client-side filter (range, ghost mode, blocked) changes.
///
/// Copied from [rawNearbyUsers].
class RawNearbyUsersProvider
    extends AutoDisposeStreamProvider<List<NearbyUser>> {
  /// Stable raw geo-stream that only depends on the user's position.
  /// This avoids tearing down and re-subscribing the Firestore listener
  /// every time a client-side filter (range, ghost mode, blocked) changes.
  ///
  /// Copied from [rawNearbyUsers].
  RawNearbyUsersProvider({required String currentUserId})
    : this._internal(
        (ref) => rawNearbyUsers(
          ref as RawNearbyUsersRef,
          currentUserId: currentUserId,
        ),
        from: rawNearbyUsersProvider,
        name: r'rawNearbyUsersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$rawNearbyUsersHash,
        dependencies: RawNearbyUsersFamily._dependencies,
        allTransitiveDependencies:
            RawNearbyUsersFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  RawNearbyUsersProvider._internal(
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
    Stream<List<NearbyUser>> Function(RawNearbyUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RawNearbyUsersProvider._internal(
        (ref) => create(ref as RawNearbyUsersRef),
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
    return _RawNearbyUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RawNearbyUsersProvider &&
        other.currentUserId == currentUserId;
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
mixin RawNearbyUsersRef on AutoDisposeStreamProviderRef<List<NearbyUser>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _RawNearbyUsersProviderElement
    extends AutoDisposeStreamProviderElement<List<NearbyUser>>
    with RawNearbyUsersRef {
  _RawNearbyUsersProviderElement(super.provider);

  @override
  String get currentUserId => (origin as RawNearbyUsersProvider).currentUserId;
}

String _$nearbyUsersHash() => r'4459e9e9f5a998911f6f2a6db11d1a1f51e9a381';

/// Filtered provider that applies range, ghost mode, and blocked user filters
/// on top of the stable raw geo-stream. Changing these filters does NOT
/// re-subscribe to Firestore — only the client-side list is re-filtered.
///
/// Copied from [nearbyUsers].
@ProviderFor(nearbyUsers)
const nearbyUsersProvider = NearbyUsersFamily();

/// Filtered provider that applies range, ghost mode, and blocked user filters
/// on top of the stable raw geo-stream. Changing these filters does NOT
/// re-subscribe to Firestore — only the client-side list is re-filtered.
///
/// Copied from [nearbyUsers].
class NearbyUsersFamily extends Family<AsyncValue<List<NearbyUser>>> {
  /// Filtered provider that applies range, ghost mode, and blocked user filters
  /// on top of the stable raw geo-stream. Changing these filters does NOT
  /// re-subscribe to Firestore — only the client-side list is re-filtered.
  ///
  /// Copied from [nearbyUsers].
  const NearbyUsersFamily();

  /// Filtered provider that applies range, ghost mode, and blocked user filters
  /// on top of the stable raw geo-stream. Changing these filters does NOT
  /// re-subscribe to Firestore — only the client-side list is re-filtered.
  ///
  /// Copied from [nearbyUsers].
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

/// Filtered provider that applies range, ghost mode, and blocked user filters
/// on top of the stable raw geo-stream. Changing these filters does NOT
/// re-subscribe to Firestore — only the client-side list is re-filtered.
///
/// Copied from [nearbyUsers].
class NearbyUsersProvider
    extends AutoDisposeProvider<AsyncValue<List<NearbyUser>>> {
  /// Filtered provider that applies range, ghost mode, and blocked user filters
  /// on top of the stable raw geo-stream. Changing these filters does NOT
  /// re-subscribe to Firestore — only the client-side list is re-filtered.
  ///
  /// Copied from [nearbyUsers].
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
    AsyncValue<List<NearbyUser>> Function(NearbyUsersRef provider) create,
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
  AutoDisposeProviderElement<AsyncValue<List<NearbyUser>>> createElement() {
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
mixin NearbyUsersRef on AutoDisposeProviderRef<AsyncValue<List<NearbyUser>>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _NearbyUsersProviderElement
    extends AutoDisposeProviderElement<AsyncValue<List<NearbyUser>>>
    with NearbyUsersRef {
  _NearbyUsersProviderElement(super.provider);

  @override
  String get currentUserId => (origin as NearbyUsersProvider).currentUserId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
