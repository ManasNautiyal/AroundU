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

class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
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
    final isNearby = ref.watch(proximityStatusProvider(widget.targetUser.uid));
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
                  const SizedBox(height: 2),
                  // Proximity Status Indicator
                  Row(
                    children: [
                      if (isNearby) ...[
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(
                                  (150 + (100 * _pulseController.value)).toInt(),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withAlpha(80),
                                    blurRadius: 6 * _pulseController.value,
                                    spreadRadius: 1 * _pulseController.value,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Nearby (Within 100m)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Away',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF060606),
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
        : const Color(0xFF262626);
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : Colors.white;

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
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF060606),
        border: Border(
          top: BorderSide(
            color: Color(0xFF262626),
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
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF262626),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Image attachment icon
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 22),
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
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
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
