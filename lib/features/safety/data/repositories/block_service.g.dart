// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$blockServiceHash() => r'2f4b2f266356907432d79ed19470dccd35a1029a';

/// See also [blockService].
@ProviderFor(blockService)
final blockServiceProvider = AutoDisposeProvider<BlockService>.internal(
  blockService,
  name: r'blockServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$blockServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BlockServiceRef = AutoDisposeProviderRef<BlockService>;
String _$blockedUsersStreamHash() =>
    r'a39b1f99021a58e1f78ddac947fd5dec5f754c77';

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

/// See also [blockedUsersStream].
@ProviderFor(blockedUsersStream)
const blockedUsersStreamProvider = BlockedUsersStreamFamily();

/// See also [blockedUsersStream].
class BlockedUsersStreamFamily extends Family<AsyncValue<List<String>>> {
  /// See also [blockedUsersStream].
  const BlockedUsersStreamFamily();

  /// See also [blockedUsersStream].
  BlockedUsersStreamProvider call({required String currentUserId}) {
    return BlockedUsersStreamProvider(currentUserId: currentUserId);
  }

  @override
  BlockedUsersStreamProvider getProviderOverride(
    covariant BlockedUsersStreamProvider provider,
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
  String? get name => r'blockedUsersStreamProvider';
}

/// See also [blockedUsersStream].
class BlockedUsersStreamProvider
    extends AutoDisposeStreamProvider<List<String>> {
  /// See also [blockedUsersStream].
  BlockedUsersStreamProvider({required String currentUserId})
    : this._internal(
        (ref) => blockedUsersStream(
          ref as BlockedUsersStreamRef,
          currentUserId: currentUserId,
        ),
        from: blockedUsersStreamProvider,
        name: r'blockedUsersStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$blockedUsersStreamHash,
        dependencies: BlockedUsersStreamFamily._dependencies,
        allTransitiveDependencies:
            BlockedUsersStreamFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  BlockedUsersStreamProvider._internal(
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
    Stream<List<String>> Function(BlockedUsersStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlockedUsersStreamProvider._internal(
        (ref) => create(ref as BlockedUsersStreamRef),
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
  AutoDisposeStreamProviderElement<List<String>> createElement() {
    return _BlockedUsersStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlockedUsersStreamProvider &&
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
mixin BlockedUsersStreamRef on AutoDisposeStreamProviderRef<List<String>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _BlockedUsersStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<String>>
    with BlockedUsersStreamRef {
  _BlockedUsersStreamProviderElement(super.provider);

  @override
  String get currentUserId =>
      (origin as BlockedUsersStreamProvider).currentUserId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
