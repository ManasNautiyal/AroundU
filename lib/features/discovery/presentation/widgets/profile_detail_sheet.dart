import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../data/models/nearby_user.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../connections/presentation/widgets/match_overlay.dart';
import '../../../connections/data/models/message_request_model.dart';

// ─────────────────────────────────────────────
// Profile Detail Sheet — Hinge-inspired
// ─────────────────────────────────────────────
class ProfileDetailSheet extends ConsumerStatefulWidget {
  final UserModel userModel;

  const ProfileDetailSheet({
    super.key,
    required this.userModel,
  });

  @override
  ConsumerState<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends ConsumerState<ProfileDetailSheet> {

  void _openPhotoViewer(List<String> images, int index) {
    showFullScreenPhotoViewer(context, images, initialIndex: index);
  }



  void _showConnectDialog() {
    final textController = TextEditingController();
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final user = widget.userModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              decoration: AppDecorations.bottomSheet(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDecorations.dragHandle(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.darkGray,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Text ${user.name}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              'Send a friendly intro!',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Intro Message',
                      hintText: 'e.g. Hey! I noticed you nearby...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final message = textController.text.trim();
                      if (message.isEmpty) {
                        ScaffoldMessenger.of(modalContext).showSnackBar(
                          const SnackBar(content: Text('Please type a message to connect.')),
                        );
                        return;
                      }
                      Navigator.pop(modalContext);
                      final repo = ref.read(interactionRepositoryProvider);
                      await repo.sendConnectionRequest(
                        currentUserId: currentUserId,
                        targetUserId: user.uid,
                        introMessage: message,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Text request sent to ${user.name}!')),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Send Request'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userModel;

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final sentLikesAsync = ref.watch(sentLikesStreamProvider(currentUserId: currentUserId));
    final hasLiked = sentLikesAsync.valueOrNull?.any((like) => like.receiverId == user.uid) ?? false;

    final matchesAsync = ref.watch(matchesStreamProvider(currentUserId: currentUserId));
    final matches = matchesAsync.valueOrNull ?? [];
    final isMatched = matches.any((m) => m.user1Id == user.uid || m.user2Id == user.uid);

    final requestsAsync = ref.watch(connectionRequestsStreamProvider(currentUserId: currentUserId));
    final pendingRequests = requestsAsync.valueOrNull ?? [];
    final pendingRequest = pendingRequests.cast<MessageRequestModel?>().firstWhere(
      (r) => (r?.senderId == user.uid && r?.receiverId == currentUserId) ||
             (r?.senderId == currentUserId && r?.receiverId == user.uid),
      orElse: () => null,
    );

    final images = user.profilePictures.where((p) => p.isNotEmpty).toList();
    if (images.isEmpty) {
      images.add('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500');
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: AppDecorations.bottomSheet(),
          child: Stack(
            children: [
              // ── Scrollable body ──
              ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  AppDecorations.dragHandle(),

                  // First large photo with overlay
                  if (images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 5,
                              child: GestureDetector(
                                onTap: () => _openPhotoViewer(images, 0),
                                child: getUserImageWidget(images[0], fit: BoxFit.cover),
                              ),
                            ),
                            // Overlay gradient
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 32, color: Colors.white, height: 1.1),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        _StatChip(label: 'Photos', value: images.length.toString()),
                                        const SizedBox(width: 8),
                                        _StatChip(label: 'Likes', value: user.likesCount.toString()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Bio ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppDecorations.card(borderRadius: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About me', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Text(user.bio, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, height: 1.5)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Remaining photos ──
                  for (int i = 1; i < images.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: GestureDetector(
                            onTap: () => _openPhotoViewer(images, i),
                            child: getUserImageWidget(images[i], fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Sticky action buttons ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.offBlack.withValues(alpha: 0.0),
                        AppTheme.offBlack.withValues(alpha: 0.9),
                        AppTheme.offBlack,
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Like / Unlike
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(interactionRepositoryProvider);
                            if (hasLiked) {
                              await repo.unlikeUser(
                                currentUserId: currentUserId,
                                targetUserId: user.uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unliked ${user.name}')),
                                );
                              }
                            } else {
                              final mutual = await repo.sendLike(
                                currentUserId: currentUserId,
                                targetUserId: user.uid,
                              );
                              if (context.mounted) {
                                if (mutual) {
                                  MatchOverlay.show(
                                    context: context,
                                    matchedUser: user,
                                    onSendMessage: () {
                                      final matchId = currentUserId.compareTo(user.uid) < 0
                                          ? '${currentUserId}_${user.uid}'
                                          : '${user.uid}_$currentUserId';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            matchId: matchId,
                                            targetUser: user,
                                          ),
                                        ),
                                      );
                                    },
                                    onKeepLooking: () {},
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Liked ${user.name}! ❤️')),
                                  );
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: hasLiked ? const Color(0xFFFF6B6B) : Colors.white,
                            side: BorderSide(
                              color: hasLiked ? const Color(0xFFFF6B6B) : AppTheme.borderGray,
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(
                            hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: hasLiked ? const Color(0xFFFF6B6B) : Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            hasLiked ? 'Liked' : 'Like',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Connect / Chat Button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (isMatched) {
                              final matchId = currentUserId.compareTo(user.uid) < 0
                                  ? '${currentUserId}_${user.uid}'
                                  : '${user.uid}_$currentUserId';
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    matchId: matchId,
                                    targetUser: user,
                                  ),
                                ),
                              );
                            } else if (pendingRequest != null) {
                              if (pendingRequest.senderId == currentUserId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Text request sent to ${user.name}. Waiting for response.')),
                                );
                              } else {
                                _showConnectDialog();
                              }
                            } else {
                              _showConnectDialog();
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: Icon(
                            isMatched
                                ? Icons.chat_rounded
                                : (pendingRequest != null && pendingRequest.senderId == currentUserId
                                    ? Icons.mark_chat_read_rounded
                                    : Icons.send_rounded),
                            size: 20,
                          ),
                          label: Text(
                            isMatched
                                ? 'Chat'
                                : (pendingRequest != null && pendingRequest.senderId == currentUserId
                                    ? 'Pending'
                                    : 'Text'),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Stat chip widget
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderGray, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
