// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interaction_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$interactionRepositoryHash() =>
    r'db53743d427876eb504e376a52687a99c8b767e3';

/// See also [interactionRepository].
@ProviderFor(interactionRepository)
final interactionRepositoryProvider =
    AutoDisposeProvider<InteractionRepository>.internal(
      interactionRepository,
      name: r'interactionRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$interactionRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InteractionRepositoryRef =
    AutoDisposeProviderRef<InteractionRepository>;
String _$matchesStreamHash() => r'9e38bd43aaffcca10dbb7e0d8b580a3f27643919';

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

/// See also [matchesStream].
@ProviderFor(matchesStream)
const matchesStreamProvider = MatchesStreamFamily();

/// See also [matchesStream].
class MatchesStreamFamily extends Family<AsyncValue<List<MatchModel>>> {
  /// See also [matchesStream].
  const MatchesStreamFamily();

  /// See also [matchesStream].
  MatchesStreamProvider call({required String currentUserId}) {
    return MatchesStreamProvider(currentUserId: currentUserId);
  }

  @override
  MatchesStreamProvider getProviderOverride(
    covariant MatchesStreamProvider provider,
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
  String? get name => r'matchesStreamProvider';
}

/// See also [matchesStream].
class MatchesStreamProvider
    extends AutoDisposeStreamProvider<List<MatchModel>> {
  /// See also [matchesStream].
  MatchesStreamProvider({required String currentUserId})
    : this._internal(
        (ref) => matchesStream(
          ref as MatchesStreamRef,
          currentUserId: currentUserId,
        ),
        from: matchesStreamProvider,
        name: r'matchesStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$matchesStreamHash,
        dependencies: MatchesStreamFamily._dependencies,
        allTransitiveDependencies:
            MatchesStreamFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  MatchesStreamProvider._internal(
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
    Stream<List<MatchModel>> Function(MatchesStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MatchesStreamProvider._internal(
        (ref) => create(ref as MatchesStreamRef),
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
  AutoDisposeStreamProviderElement<List<MatchModel>> createElement() {
    return _MatchesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchesStreamProvider &&
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
mixin MatchesStreamRef on AutoDisposeStreamProviderRef<List<MatchModel>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _MatchesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MatchModel>>
    with MatchesStreamRef {
  _MatchesStreamProviderElement(super.provider);

  @override
  String get currentUserId => (origin as MatchesStreamProvider).currentUserId;
}

String _$incomingWavesStreamHash() =>
    r'275dc6bcde04f0586e62721b1762217330b083ff';

/// See also [incomingWavesStream].
@ProviderFor(incomingWavesStream)
const incomingWavesStreamProvider = IncomingWavesStreamFamily();

/// See also [incomingWavesStream].
class IncomingWavesStreamFamily
    extends Family<AsyncValue<List<InteractionModel>>> {
  /// See also [incomingWavesStream].
  const IncomingWavesStreamFamily();

  /// See also [incomingWavesStream].
  IncomingWavesStreamProvider call({required String currentUserId}) {
    return IncomingWavesStreamProvider(currentUserId: currentUserId);
  }

  @override
  IncomingWavesStreamProvider getProviderOverride(
    covariant IncomingWavesStreamProvider provider,
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
  String? get name => r'incomingWavesStreamProvider';
}

/// See also [incomingWavesStream].
class IncomingWavesStreamProvider
    extends AutoDisposeStreamProvider<List<InteractionModel>> {
  /// See also [incomingWavesStream].
  IncomingWavesStreamProvider({required String currentUserId})
    : this._internal(
        (ref) => incomingWavesStream(
          ref as IncomingWavesStreamRef,
          currentUserId: currentUserId,
        ),
        from: incomingWavesStreamProvider,
        name: r'incomingWavesStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$incomingWavesStreamHash,
        dependencies: IncomingWavesStreamFamily._dependencies,
        allTransitiveDependencies:
            IncomingWavesStreamFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  IncomingWavesStreamProvider._internal(
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
    Stream<List<InteractionModel>> Function(IncomingWavesStreamRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IncomingWavesStreamProvider._internal(
        (ref) => create(ref as IncomingWavesStreamRef),
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
  AutoDisposeStreamProviderElement<List<InteractionModel>> createElement() {
    return _IncomingWavesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IncomingWavesStreamProvider &&
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
mixin IncomingWavesStreamRef
    on AutoDisposeStreamProviderRef<List<InteractionModel>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _IncomingWavesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<InteractionModel>>
    with IncomingWavesStreamRef {
  _IncomingWavesStreamProviderElement(super.provider);

  @override
  String get currentUserId =>
      (origin as IncomingWavesStreamProvider).currentUserId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
