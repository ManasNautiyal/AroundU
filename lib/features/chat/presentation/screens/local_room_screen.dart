import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../data/models/proximity_room_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../controllers/proximity_room_chat_controller.dart';
import '../../../discovery/presentation/controllers/user_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../core/services/location_service.dart';

class LocalRoomScreen extends ConsumerStatefulWidget {
  final ProximityRoomModel room;
  const LocalRoomScreen({super.key, required this.room});

  @override
  ConsumerState<LocalRoomScreen> createState() => _LocalRoomScreenState();
}

class _LocalRoomScreenState extends ConsumerState<LocalRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool? _manualProximityOverride;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? 'me';
    ref.read(chatRepositoryProvider).sendProximityRoomMessage(
      roomId: widget.room.id,
      senderId: currentUserId,
      text: text,
    );

    // Scroll to bottom after new message is sent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final positionAsync = ref.watch(userPositionProvider);
    final isInRange = positionAsync.maybeWhen(
      data: (position) {
        final geopoint = widget.room.location['geopoint'] as GeoPoint?;
        if (geopoint == null) return false;
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          geopoint.latitude,
          geopoint.longitude,
        );
        return distance <= widget.room.radiusInMeters;
      },
      orElse: () => true, // default to true if location is loading
    );

    final isInRoom = _manualProximityOverride ?? isInRange;
    final messagesAsync = ref.watch(proximityRoomMessagesProvider(roomId: widget.room.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 ${widget.room.name}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Proximity Chat Room',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Proximity Simulator Switch in Header
          Row(
            children: [
              Icon(
                isInRoom ? Icons.location_on : Icons.location_off,
                color: isInRoom
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white30 : Colors.black26),
                size: 18,
              ),
              const SizedBox(width: 4),
              Switch(
                value: isInRoom,
                onChanged: (val) {
                  setState(() {
                    _manualProximityOverride = val;
                  });
                },
                activeThumbColor: theme.colorScheme.onPrimary,
                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                inactiveThumbColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                inactiveTrackColor: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // Proximity Warning Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: isInRoom ? 0 : 70,
              curve: Curves.easeInOut,
              color: theme.colorScheme.surfaceContainerHighest,
              child: isInRoom
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You left the ${widget.room.name} zone.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Messages View
            Expanded(
              child: !isInRoom
                  ? _buildLeftZoneState(theme)
                  : messagesAsync.when(
                      data: (roomMessages) {
                        if (roomMessages.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages yet. Say hi! 👋',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: roomMessages.length,
                          itemBuilder: (context, index) {
                            final message = roomMessages[index];
                            final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
                            final isMe = message.senderId == currentUserId;
                            return _buildGroupMessageBubble(message, isMe, message.senderId, theme);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading messages: $err')),
                    ),
            ),

            // Input Area
            if (isInRoom) _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftZoneState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Out of Range',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This room is only active within 100 meters. Toggle Proximity back on in the upper-right corner to re-enter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMessageBubble(dynamic message, bool isMe, String senderId, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final senderAsync = ref.watch(userProfileProvider(senderId));
        final sender = senderAsync.valueOrNull;

        final isDark = theme.brightness == Brightness.dark;
        final bubbleColor = isMe
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest;
        final textColor = isMe
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant;

        final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
        final margin = isMe
            ? const EdgeInsets.only(left: 64, top: 4, bottom: 4)
            : const EdgeInsets.only(right: 64, top: 4, bottom: 4);

        final formattedTime = DateFormat('h:mm a').format(message.timestamp);

        final avatarUrl = (sender != null && sender.profilePictures.isNotEmpty)
            ? sender.profilePictures[0]
            : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: margin,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: getUserImageProvider(avatarUrl),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: align,
                    children: [
                      if (!isMe && sender != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                          child: Text(
                            sender.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          formattedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
      theme.colorScheme.surface,
    );
    final borderBg = theme.colorScheme.outlineVariant;
    final textColor = theme.colorScheme.onSurface;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: borderBg,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: borderBg,
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    // Text Input field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Share something with the zone...',
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: false,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Button
                    TextButton(
                      onPressed: _sendMessage,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
