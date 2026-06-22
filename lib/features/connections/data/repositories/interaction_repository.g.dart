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

String _$connectionRequestsStreamHash() =>
    r'58c3127c9ef57a7e7ea6741cbf423f6a42b12e72';

/// See also [connectionRequestsStream].
@ProviderFor(connectionRequestsStream)
const connectionRequestsStreamProvider = ConnectionRequestsStreamFamily();

/// See also [connectionRequestsStream].
class ConnectionRequestsStreamFamily
    extends Family<AsyncValue<List<MessageRequestModel>>> {
  /// See also [connectionRequestsStream].
  const ConnectionRequestsStreamFamily();

  /// See also [connectionRequestsStream].
  ConnectionRequestsStreamProvider call({required String currentUserId}) {
    return ConnectionRequestsStreamProvider(currentUserId: currentUserId);
  }

  @override
  ConnectionRequestsStreamProvider getProviderOverride(
    covariant ConnectionRequestsStreamProvider provider,
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
  String? get name => r'connectionRequestsStreamProvider';
}

/// See also [connectionRequestsStream].
class ConnectionRequestsStreamProvider
    extends AutoDisposeStreamProvider<List<MessageRequestModel>> {
  /// See also [connectionRequestsStream].
  ConnectionRequestsStreamProvider({required String currentUserId})
    : this._internal(
        (ref) => connectionRequestsStream(
          ref as ConnectionRequestsStreamRef,
          currentUserId: currentUserId,
        ),
        from: connectionRequestsStreamProvider,
        name: r'connectionRequestsStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$connectionRequestsStreamHash,
        dependencies: ConnectionRequestsStreamFamily._dependencies,
        allTransitiveDependencies:
            ConnectionRequestsStreamFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  ConnectionRequestsStreamProvider._internal(
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
    Stream<List<MessageRequestModel>> Function(
      ConnectionRequestsStreamRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConnectionRequestsStreamProvider._internal(
        (ref) => create(ref as ConnectionRequestsStreamRef),
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
  AutoDisposeStreamProviderElement<List<MessageRequestModel>> createElement() {
    return _ConnectionRequestsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionRequestsStreamProvider &&
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
mixin ConnectionRequestsStreamRef
    on AutoDisposeStreamProviderRef<List<MessageRequestModel>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _ConnectionRequestsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageRequestModel>>
    with ConnectionRequestsStreamRef {
  _ConnectionRequestsStreamProviderElement(super.provider);

  @override
  String get currentUserId =>
      (origin as ConnectionRequestsStreamProvider).currentUserId;
}

String _$receivedLikesStreamHash() =>
    r'71dc8a1301c3efa6bae203dd21dbca4b463bb702';

/// See also [receivedLikesStream].
@ProviderFor(receivedLikesStream)
const receivedLikesStreamProvider = ReceivedLikesStreamFamily();

/// See also [receivedLikesStream].
class ReceivedLikesStreamFamily
    extends Family<AsyncValue<List<InteractionModel>>> {
  /// See also [receivedLikesStream].
  const ReceivedLikesStreamFamily();

  /// See also [receivedLikesStream].
  ReceivedLikesStreamProvider call({required String currentUserId}) {
    return ReceivedLikesStreamProvider(currentUserId: currentUserId);
  }

  @override
  ReceivedLikesStreamProvider getProviderOverride(
    covariant ReceivedLikesStreamProvider provider,
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
  String? get name => r'receivedLikesStreamProvider';
}

/// See also [receivedLikesStream].
class ReceivedLikesStreamProvider
    extends AutoDisposeStreamProvider<List<InteractionModel>> {
  /// See also [receivedLikesStream].
  ReceivedLikesStreamProvider({required String currentUserId})
    : this._internal(
        (ref) => receivedLikesStream(
          ref as ReceivedLikesStreamRef,
          currentUserId: currentUserId,
        ),
        from: receivedLikesStreamProvider,
        name: r'receivedLikesStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$receivedLikesStreamHash,
        dependencies: ReceivedLikesStreamFamily._dependencies,
        allTransitiveDependencies:
            ReceivedLikesStreamFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  ReceivedLikesStreamProvider._internal(
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
    Stream<List<InteractionModel>> Function(ReceivedLikesStreamRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReceivedLikesStreamProvider._internal(
        (ref) => create(ref as ReceivedLikesStreamRef),
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
    return _ReceivedLikesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceivedLikesStreamProvider &&
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
mixin ReceivedLikesStreamRef
    on AutoDisposeStreamProviderRef<List<InteractionModel>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _ReceivedLikesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<InteractionModel>>
    with ReceivedLikesStreamRef {
  _ReceivedLikesStreamProviderElement(super.provider);

  @override
  String get currentUserId =>
      (origin as ReceivedLikesStreamProvider).currentUserId;
}

String _$sentLikesStreamHash() => r'6d25521ffe6e284e903b8145497f9ca17ccd097b';

/// See also [sentLikesStream].
@ProviderFor(sentLikesStream)
const sentLikesStreamProvider = SentLikesStreamFamily();

/// See also [sentLikesStream].
class SentLikesStreamFamily extends Family<AsyncValue<List<InteractionModel>>> {
  /// See also [sentLikesStream].
  const SentLikesStreamFamily();

  /// See also [sentLikesStream].
  SentLikesStreamProvider call({required String currentUserId}) {
    return SentLikesStreamProvider(currentUserId: currentUserId);
  }

  @override
  SentLikesStreamProvider getProviderOverride(
    covariant SentLikesStreamProvider provider,
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
  String? get name => r'sentLikesStreamProvider';
}

/// See also [sentLikesStream].
class SentLikesStreamProvider
    extends AutoDisposeStreamProvider<List<InteractionModel>> {
  /// See also [sentLikesStream].
  SentLikesStreamProvider({required String currentUserId})
    : this._internal(
        (ref) => sentLikesStream(
          ref as SentLikesStreamRef,
          currentUserId: currentUserId,
        ),
        from: sentLikesStreamProvider,
        name: r'sentLikesStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sentLikesStreamHash,
        dependencies: SentLikesStreamFamily._dependencies,
        allTransitiveDependencies:
            SentLikesStreamFamily._allTransitiveDependencies,
        currentUserId: currentUserId,
      );

  SentLikesStreamProvider._internal(
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
    Stream<List<InteractionModel>> Function(SentLikesStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SentLikesStreamProvider._internal(
        (ref) => create(ref as SentLikesStreamRef),
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
    return _SentLikesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SentLikesStreamProvider &&
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
mixin SentLikesStreamRef
    on AutoDisposeStreamProviderRef<List<InteractionModel>> {
  /// The parameter `currentUserId` of this provider.
  String get currentUserId;
}

class _SentLikesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<InteractionModel>>
    with SentLikesStreamRef {
  _SentLikesStreamProviderElement(super.provider);

  @override
  String get currentUserId => (origin as SentLikesStreamProvider).currentUserId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
