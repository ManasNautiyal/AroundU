import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../widgets/message_reaction_bar.dart';
import '../widgets/quoted_message_preview.dart';
import '../widgets/voice_note_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;
  final UserModel targetUser;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.targetUser,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  ReplyToModel? _replyTo;
  Timer? _typingTimer;
  bool _isLocalTyping = false;

  @override
  void initState() {
    super.initState();
    // Mark incoming messages as read when chat opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _onStopTyping();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _markAsRead() {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      ref.read(chatRepositoryProvider).markMessagesAsRead(
            matchId: widget.matchId,
            currentUserId: currentUserId,
          );
    }
  }

  void _onTextChanged(String val) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    if (val.trim().isNotEmpty && !_isLocalTyping) {
      _isLocalTyping = true;
      ref.read(chatRepositoryProvider).setTypingStatus(
            matchId: widget.matchId,
            userId: currentUserId,
            isTyping: true,
          );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), _onStopTyping);
  }

  void _onStopTyping() {
    if (!_isLocalTyping) return;
    _isLocalTyping = false;
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      ref.read(chatRepositoryProvider).setTypingStatus(
            matchId: widget.matchId,
            userId: currentUserId,
            isTyping: false,
          );
    }
  }

  void _sendMessage({
    MessageType type = MessageType.text,
    String? mediaUrl,
    int? durationSeconds,
  }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && type == MessageType.text && mediaUrl == null) return;

    _onStopTyping();
    _messageController.clear();
    final replyPayload = _replyTo;
    setState(() {
      _replyTo = null;
    });

    try {
      final repo = ref.read(chatRepositoryProvider);
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? 'me';
      await repo.sendMessage(
        matchId: widget.matchId,
        senderId: currentUserId,
        text: type == MessageType.text ? text : (type == MessageType.image ? '📷 Photo' : '🎤 Voice Note'),
        type: type,
        mediaUrl: mediaUrl,
        durationSeconds: durationSeconds,
        replyTo: replyPayload,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e')),
        );
      }
    }
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final messagesAsync = ref.watch(messagesStreamProvider(matchId: widget.matchId));

    final avatarUrl = widget.targetUser.profilePictures.isNotEmpty
        ? widget.targetUser.profilePictures[0]
        : '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderGray, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: getUserImageProvider(avatarUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetUser.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                  Text(
                    'Active now',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // Messages List Stream
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  _markAsRead();

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Start the conversation! 👋',
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
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _buildMessageItem(message, isMe, theme);
                    },
                  );
                },
                error: (err, stack) => Center(child: Text('Error loading messages: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),

            // Reply Preview Banner
            if (_replyTo != null)
              QuotedMessageInputPreview(
                replyTo: _replyTo!,
                onCancel: () {
                  setState(() {
                    _replyTo = null;
                  });
                },
              ),

            // Text Input field
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message, bool isMe, ThemeData theme) {
    return Dismissible(
      key: Key('reply_${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        setState(() {
          _replyTo = ReplyToModel(
            messageId: message.id,
            senderName: isMe ? 'You' : widget.targetUser.name,
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
                    matchId: widget.matchId,
                    messageId: message.id,
                    userId: currentUserId,
                    emoji: emoji,
                  );
            },
            onReply: () {
              setState(() {
                _replyTo = ReplyToModel(
                  messageId: message.id,
                  senderName: isMe ? 'You' : widget.targetUser.name,
                  text: message.text,
                );
              });
            },
            onDelete: () {
              ref.read(chatRepositoryProvider).deleteMessage(
                    matchId: widget.matchId,
                    messageId: message.id,
                  );
            },
          );
        },
        child: _buildMessageBubble(message, isMe, theme),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, ThemeData theme) {
    final bubbleColor = isMe
        ? Colors.white
        : AppTheme.darkGray;
    final textColor = isMe
        ? Colors.black
        : Colors.white;

    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMe
        ? const EdgeInsets.only(left: 64, top: 3, bottom: 3)
        : const EdgeInsets.only(right: 64, top: 3, bottom: 3);

    final formattedTime = DateFormat('h:mm a').format(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: align,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isDeleted
                        ? AppTheme.subtleGray
                        : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    border: isMe ? null : Border.all(color: AppTheme.borderGray, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quoted reply card inside message
                      if (message.replyTo != null)
                        QuotedMessageBubbleCard(replyTo: message.replyTo!, isMe: isMe),

                      // Deleted message notice
                      if (message.isDeleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, size: 14, color: textColor.withValues(alpha: 0.6)),
                            const SizedBox(width: 6),
                            Text(
                              'This message was deleted',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      // Photo Message
                      else if (message.type == MessageType.image && message.mediaUrl != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => showFullScreenPhotoViewer(context, [message.mediaUrl!]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Image(
                                    image: getUserImageProvider(message.mediaUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            if (message.text.isNotEmpty && message.text != '📷 Photo') ...[
                              const SizedBox(height: 6),
                              Text(
                                message.text,
                                style: TextStyle(color: textColor, fontSize: 15.5),
                              ),
                            ],
                          ],
                        )
                      // Voice Note Message
                      else if (message.type == MessageType.voiceNote)
                        VoiceNoteBubblePlayer(
                          audioUrl: message.mediaUrl,
                          durationSeconds: message.durationSeconds ?? 5,
                          isMe: isMe,
                        )
                      // Normal Text Message
                      else
                        Text(
                          message.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15.5,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),

                // Timestamp & Blue Read Ticks Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 15,
                          color: message.isRead ? Colors.blue : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Emoji Reaction Overlay Badge
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderGray,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.borderGray,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    // Camera / Gallery Image Attachment
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _pickImage(ImageSource.camera),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_outlined, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 2),

                    // Text Input field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: GoogleFonts.inter(color: AppTheme.textTertiary, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: false,
                        ),
                      ),
                    ),

                    // Send Button
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _sendMessage(),
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 18),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                        padding: const EdgeInsets.all(6),
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
