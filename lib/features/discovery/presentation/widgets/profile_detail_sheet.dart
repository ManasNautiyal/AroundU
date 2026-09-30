import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../data/models/nearby_user.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../../safety/data/repositories/block_service.dart';
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

  void _showReportBottomSheet(BuildContext context) {
    final reasons = ['Spam', 'Harassment', 'Inappropriate Content'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: AppDecorations.bottomSheet(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDecorations.dragHandle(),
              Text(
                'Report ${widget.userModel.name}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a reason. This user will also be blocked automatically.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGray,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderGray, width: 0.5),
                  ),
                  child: ListTile(
                    title: Text(
                      reason,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () async {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reporting ${widget.userModel.name}...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      final blockService = ref.read(blockServiceProvider);
                      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
                      await blockService.reportUser(
                        reporterId: currentUserId,
                        targetUserId: widget.userModel.uid,
                        reason: reason,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.userModel.name} has been reported and blocked.'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
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
    final userSentLikesAsync = ref.watch(sentLikesStreamProvider(currentUserId: user.uid));

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

    final avatarUrl = images[0];
    final gridPhotos = images.length > 1 ? images.sublist(1) : <String>[];

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

                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () => _openPhotoViewer(images, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderGray, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: AppTheme.darkGray,
                              child: ClipOval(
                                child: getUserImageWidget(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(Icons.person, size: 40, color: AppTheme.textTertiary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Name + stats column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Report
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.darkGray,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.more_horiz_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      tooltip: 'Report / Block',
                                      onPressed: () => _showReportBottomSheet(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Stats row with stylized chips
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _StatChip(
                                    label: 'Photos',
                                    value: images.length.toString(),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatChip(
                                    label: 'Likes',
                                    value: user.likesCount.toString(),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatChip(
                                    label: 'Liked',
                                    value: userSentLikesAsync.valueOrNull?.length.toString() ?? '0',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Bio ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.card(borderRadius: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.bio,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Photo grid ──
                  if (images.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Photos',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                        itemCount: gridPhotos.length,
                        itemBuilder: (ctx, i) {
                          return GestureDetector(
                            onTap: () => _openPhotoViewer(images, i + 1),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderGray, width: 0.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: getUserImageWidget(
                                  gridPhotos[i],
                                  fit: BoxFit.cover,
                                  placeholder: Container(
                                    color: AppTheme.darkGray,
                                    child: const Center(
                                      child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: Container(
                                    color: AppTheme.darkGray,
                                    child: const Icon(Icons.broken_image_outlined, color: AppTheme.textTertiary),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
