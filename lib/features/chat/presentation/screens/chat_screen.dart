import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final repo = ref.read(chatRepositoryProvider);
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? 'me';
      await repo.sendMessage(
        matchId: widget.matchId,
        senderId: currentUserId,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $e')),
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
            CircleAvatar(
              radius: 20,
              backgroundImage: getUserImageProvider(avatarUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetUser.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    reverse: true, // Inverts scrolling index (starts at bottom)
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;
                      return _buildMessageBubble(message, isMe, theme);
                    },
                  );
                },
                error: (err, stack) => Center(child: Text('Error loading messages: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),

            // Text Input field
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, ThemeData theme) {
    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMe
        ? const EdgeInsets.only(left: 64, top: 4, bottom: 4)
        : const EdgeInsets.only(right: 64, top: 4, bottom: 4);

    final formattedTime = DateFormat('h:mm a').format(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: margin,
        child: Column(
          crossAxisAlignment: align,
          children: [
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
                border: isMe ? null : Border.all(color: theme.colorScheme.outline, width: 1.0),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Message Timestamp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                formattedTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

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
                    // Image attachment icon
                    IconButton(
                      icon: Icon(Icons.add_photo_alternate_outlined, color: subTextColor, size: 22),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image sharing coming in a future update!')),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Text Input field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: hintColor),
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
