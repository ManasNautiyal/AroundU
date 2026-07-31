import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../data/models/message_model.dart';
import '../../data/models/proximity_room_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../controllers/proximity_room_chat_controller.dart';
import '../../../discovery/presentation/controllers/user_providers.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../core/services/location_service.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../widgets/message_reaction_bar.dart';
import '../widgets/quoted_message_preview.dart';
import '../widgets/voice_note_widget.dart';

class LocalRoomScreen extends ConsumerStatefulWidget {
  final ProximityRoomModel room;
  const LocalRoomScreen({super.key, required this.room});

  @override
  ConsumerState<LocalRoomScreen> createState() => _LocalRoomScreenState();
}

class _LocalRoomScreenState extends ConsumerState<LocalRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  bool? _manualProximityOverride;
  ReplyToModel? _replyTo;

  void _sendMessage({
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? durationSeconds,
  }) {
    final text = _messageController.text.trim();
    if (text.isEmpty && type == MessageType.text && mediaUrl == null) return;

    _messageController.clear();
    final replyPayload = _replyTo;
    setState(() {
      _replyTo = null;
    });

    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? 'me';
    ref.read(chatRepositoryProvider).sendProximityRoomMessage(
      roomId: widget.room.id,
      senderId: currentUserId,
      text: type == MessageType.text ? text : (type == MessageType.image ? '📷 Photo' : '🎤 Voice Note'),
      type: type,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
      replyTo: replyPayload,
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file != null) {
        _sendMessage(
          type: MessageType.image,
          mediaUrl: file.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
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
      orElse: () => true,
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
                inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: isInRoom ? 0 : 70,
              curve: Curves.easeInOut,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              child: isInRoom
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: theme.colorScheme.onSurfaceVariant),
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
                            return _buildGroupMessageItem(message, isMe, message.senderId, theme);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading messages: $err')),
                    ),
            ),

            if (_replyTo != null)
              QuotedMessageInputPreview(
                replyTo: _replyTo!,
                onCancel: () {
                  setState(() {
                    _replyTo = null;
                  });
                },
              ),

            if (isInRoom) _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftZoneState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
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

  Widget _buildGroupMessageItem(MessageModel message, bool isMe, String senderId, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final senderAsync = ref.watch(userProfileProvider(senderId));
        final sender = senderAsync.valueOrNull;
        final senderName = isMe ? 'You' : (sender?.name ?? 'Member');

        return Dismissible(
          key: Key('preply_${message.id}'),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (_) async {
            setState(() {
              _replyTo = ReplyToModel(
                messageId: message.id,
                senderName: senderName,
                text: message.text,
              );
            });
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: Icon(Icons.reply_rounded, color: theme.colorScheme.primary),
          ),
          child: GestureDetector(
            onLongPress: () {
              MessageReactionBar.show(
                context: context,
                message: message,
                isMe: isMe,
                onReactionSelected: (emoji) {
                  final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
                  ref.read(chatRepositoryProvider).toggleReaction(
                        matchId: widget.room.id,
                        messageId: message.id,
                        userId: currentUserId,
                        emoji: emoji,
                        isProximityRoom: true,
                      );
                },
                onReply: () {
                  setState(() {
                    _replyTo = ReplyToModel(
                      messageId: message.id,
                      senderName: senderName,
                      text: message.text,
                    );
                  });
                },
                onDelete: () {
                  ref.read(chatRepositoryProvider).deleteMessage(
                        matchId: widget.room.id,
                        messageId: message.id,
                        isProximityRoom: true,
                      );
                },
              );
            },
            child: _buildGroupMessageBubble(message, isMe, senderId, sender, theme),
          ),
        );
      },
    );
  }

  Widget _buildGroupMessageBubble(MessageModel message, bool isMe, String senderId, UserModel? sender, ThemeData theme) {
    final isDarkLocal = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : (isDarkLocal
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06));
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: message.isDeleted
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                              : bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.replyTo != null)
                              QuotedMessageBubbleCard(replyTo: message.replyTo!, isMe: isMe),

                            if (message.isDeleted)
                              Text(
                                'This message was deleted',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              )
                            else if (message.type == MessageType.image && message.mediaUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: getUserImageProvider(message.mediaUrl!),
                                  width: 200,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (message.type == MessageType.voiceNote)
                              VoiceNoteBubblePlayer(
                                audioUrl: message.mediaUrl,
                                durationSeconds: message.durationSeconds ?? 5,
                                isMe: isMe,
                              )
                            else
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          formattedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (message.reactions.isNotEmpty)
              Positioned(
                bottom: 14,
                right: isMe ? null : -8,
                left: isMe ? -8 : null,
                child: MessageReactionDisplay(reactions: message.reactions),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final cardBg = theme.colorScheme.surface;
    final borderBg = theme.colorScheme.outline;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final hintColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                constraints: const BoxConstraints(minHeight: 48),
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
                    IconButton(
                      icon: Icon(Icons.camera_alt_outlined, color: subTextColor, size: 22),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    IconButton(
                      icon: Icon(Icons.photo_outlined, color: subTextColor, size: 22),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(width: 2),

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

                    TextButton(
                      onPressed: () => _sendMessage(),
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
