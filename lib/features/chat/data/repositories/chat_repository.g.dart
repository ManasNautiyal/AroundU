// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'6b50a68d8a99fbecd1ca3f51b9f0ca5c0a0b21cf';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = AutoDisposeProvider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = AutoDisposeProviderRef<ChatRepository>;
String _$messagesStreamHash() => r'9d450d2b6ac1da53cc3b463357009391c4ceba91';

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

/// See also [messagesStream].
@ProviderFor(messagesStream)
const messagesStreamProvider = MessagesStreamFamily();

/// See also [messagesStream].
class MessagesStreamFamily extends Family<AsyncValue<List<MessageModel>>> {
  /// See also [messagesStream].
  const MessagesStreamFamily();

  /// See also [messagesStream].
  MessagesStreamProvider call({required String matchId}) {
    return MessagesStreamProvider(matchId: matchId);
  }

  @override
  MessagesStreamProvider getProviderOverride(
    covariant MessagesStreamProvider provider,
  ) {
    return call(matchId: provider.matchId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'messagesStreamProvider';
}

/// See also [messagesStream].
class MessagesStreamProvider
    extends AutoDisposeStreamProvider<List<MessageModel>> {
  /// See also [messagesStream].
  MessagesStreamProvider({required String matchId})
    : this._internal(
        (ref) => messagesStream(ref as MessagesStreamRef, matchId: matchId),
        from: messagesStreamProvider,
        name: r'messagesStreamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$messagesStreamHash,
        dependencies: MessagesStreamFamily._dependencies,
        allTransitiveDependencies:
            MessagesStreamFamily._allTransitiveDependencies,
        matchId: matchId,
      );

  MessagesStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.matchId,
  }) : super.internal();

  final String matchId;

  @override
  Override overrideWith(
    Stream<List<MessageModel>> Function(MessagesStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MessagesStreamProvider._internal(
        (ref) => create(ref as MessagesStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        matchId: matchId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MessageModel>> createElement() {
    return _MessagesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesStreamProvider && other.matchId == matchId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, matchId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MessagesStreamRef on AutoDisposeStreamProviderRef<List<MessageModel>> {
  /// The parameter `matchId` of this provider.
  String get matchId;
}

class _MessagesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageModel>>
    with MessagesStreamRef {
  _MessagesStreamProviderElement(super.provider);

  @override
  String get matchId => (origin as MessagesStreamProvider).matchId;
}

String _$proximityStatusHash() => r'530d36aa8442e10e6595b92bb7a0cf819eecc130';

abstract class _$ProximityStatus extends BuildlessAutoDisposeNotifier<bool> {
  late final String userId;

  bool build(String userId);
}

/// See also [ProximityStatus].
@ProviderFor(ProximityStatus)
const proximityStatusProvider = ProximityStatusFamily();

/// See also [ProximityStatus].
class ProximityStatusFamily extends Family<bool> {
  /// See also [ProximityStatus].
  const ProximityStatusFamily();

  /// See also [ProximityStatus].
  ProximityStatusProvider call(String userId) {
    return ProximityStatusProvider(userId);
  }

  @override
  ProximityStatusProvider getProviderOverride(
    covariant ProximityStatusProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'proximityStatusProvider';
}

/// See also [ProximityStatus].
class ProximityStatusProvider
    extends AutoDisposeNotifierProviderImpl<ProximityStatus, bool> {
  /// See also [ProximityStatus].
  ProximityStatusProvider(String userId)
    : this._internal(
        () => ProximityStatus()..userId = userId,
        from: proximityStatusProvider,
        name: r'proximityStatusProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$proximityStatusHash,
        dependencies: ProximityStatusFamily._dependencies,
        allTransitiveDependencies:
            ProximityStatusFamily._allTransitiveDependencies,
        userId: userId,
      );

  ProximityStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  bool runNotifierBuild(covariant ProximityStatus notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(ProximityStatus Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProximityStatusProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ProximityStatus, bool> createElement() {
    return _ProximityStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProximityStatusProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProximityStatusRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProximityStatusProviderElement
    extends AutoDisposeNotifierProviderElement<ProximityStatus, bool>
    with ProximityStatusRef {
  _ProximityStatusProviderElement(super.provider);

  @override
  String get userId => (origin as ProximityStatusProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
