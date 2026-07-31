import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/message_model.dart';

class MessageReactionBar extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Function(String emoji) onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback? onStar;

  const MessageReactionBar({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReactionSelected,
    required this.onReply,
    required this.onDelete,
    this.onStar,
  });

  static const List<String> defaultEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  static void show({
    required BuildContext context,
    required MessageModel message,
    required bool isMe,
    required Function(String emoji) onReactionSelected,
    required VoidCallback onReply,
    required VoidCallback onDelete,
    VoidCallback? onStar,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageReactionBar(
        message: message,
        isMe: isMe,
        onReactionSelected: onReactionSelected,
        onReply: onReply,
        onDelete: onDelete,
        onStar: onStar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardBg = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji Reaction Bar Floating Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: defaultEmojis.map((emoji) {
                  final isSelected = message.reactions.containsValue(emoji);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onReactionSelected(emoji);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Actions Container
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.reply_rounded),
                    title: const Text('Reply'),
                    onTap: () {
                      Navigator.pop(context);
                      onReply();
                    },
                  ),
                  if (!message.isDeleted)
                    ListTile(
                      leading: const Icon(Icons.copy_rounded),
                      title: const Text('Copy Text'),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Message copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  if (onStar != null)
                    ListTile(
                      leading: Icon(
                        message.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: message.isStarred ? Colors.amber : null,
                      ),
                      title: Text(message.isStarred ? 'Unstar Message' : 'Star Message'),
                      onTap: () {
                        Navigator.pop(context);
                        onStar!();
                      },
                    ),
                  if (isMe && !message.isDeleted)
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageReactionDisplay extends StatelessWidget {
  final Map<String, String> reactions;

  const MessageReactionDisplay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Aggregate unique emojis and count
    final uniqueEmojis = reactions.values.toSet().toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263238) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            uniqueEmojis.join(' '),
            style: const TextStyle(fontSize: 12),
          ),
          if (reactions.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              '${reactions.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
