// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proximity_room_chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$proximityRoomMessagesHash() =>
    r'd031187253975c713008e81e624268760cd4d5bf';

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

/// See also [proximityRoomMessages].
@ProviderFor(proximityRoomMessages)
const proximityRoomMessagesProvider = ProximityRoomMessagesFamily();

/// See also [proximityRoomMessages].
class ProximityRoomMessagesFamily
    extends Family<AsyncValue<List<MessageModel>>> {
  /// See also [proximityRoomMessages].
  const ProximityRoomMessagesFamily();

  /// See also [proximityRoomMessages].
  ProximityRoomMessagesProvider call({required String roomId}) {
    return ProximityRoomMessagesProvider(roomId: roomId);
  }

  @override
  ProximityRoomMessagesProvider getProviderOverride(
    covariant ProximityRoomMessagesProvider provider,
  ) {
    return call(roomId: provider.roomId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'proximityRoomMessagesProvider';
}

/// See also [proximityRoomMessages].
class ProximityRoomMessagesProvider
    extends AutoDisposeStreamProvider<List<MessageModel>> {
  /// See also [proximityRoomMessages].
  ProximityRoomMessagesProvider({required String roomId})
    : this._internal(
        (ref) => proximityRoomMessages(
          ref as ProximityRoomMessagesRef,
          roomId: roomId,
        ),
        from: proximityRoomMessagesProvider,
        name: r'proximityRoomMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$proximityRoomMessagesHash,
        dependencies: ProximityRoomMessagesFamily._dependencies,
        allTransitiveDependencies:
            ProximityRoomMessagesFamily._allTransitiveDependencies,
        roomId: roomId,
      );

  ProximityRoomMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.roomId,
  }) : super.internal();

  final String roomId;

  @override
  Override overrideWith(
    Stream<List<MessageModel>> Function(ProximityRoomMessagesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProximityRoomMessagesProvider._internal(
        (ref) => create(ref as ProximityRoomMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        roomId: roomId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MessageModel>> createElement() {
    return _ProximityRoomMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProximityRoomMessagesProvider && other.roomId == roomId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, roomId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProximityRoomMessagesRef
    on AutoDisposeStreamProviderRef<List<MessageModel>> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _ProximityRoomMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageModel>>
    with ProximityRoomMessagesRef {
  _ProximityRoomMessagesProviderElement(super.provider);

  @override
  String get roomId => (origin as ProximityRoomMessagesProvider).roomId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
