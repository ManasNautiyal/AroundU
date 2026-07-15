import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../data/models/nearby_user.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../../safety/data/repositories/block_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../connections/presentation/widgets/match_overlay.dart';

// ─────────────────────────────────────────────
// Full-screen photo viewer (pushed as a route)
// ─────────────────────────────────────────────
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: getUserImageWidget(
                    widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          // Dot indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _currentIndex ? 18 : 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white.withAlpha(100),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          // Photo counter top-right
          Positioned(
            top: 0,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile Detail Sheet
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(
          images: images,
          initialIndex: index,
        ),
      ),
    );
  }

  void _showReportBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final reasons = ['Spam', 'Harassment', 'Inappropriate Content'];
    final sheetColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outline;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor, width: 1.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report ${widget.userModel.name}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a reason for reporting this profile. This user will also be blocked automatically.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reporting ${widget.userModel.name}...'), duration: const Duration(seconds: 1)),
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
                        backgroundColor: Colors.black,
                      ),
                    );
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showConnectDialog() {
    final theme = Theme.of(context);
    final textController = TextEditingController();
    final sheetColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outline;
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
    final user = widget.userModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderColor, width: 1.5)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Connect with ${user.name}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add a friendly note to introduce yourself!',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
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
                        SnackBar(
                          content: Text('Connection request sent to ${user.name}!'),
                          backgroundColor: Colors.black,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = widget.userModel;

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final sentLikesAsync = ref.watch(sentLikesStreamProvider(currentUserId: currentUserId));
    final hasLiked = sentLikesAsync.valueOrNull?.any((like) => like.receiverId == user.uid) ?? false;
    final connectsAsync = ref.watch(userConnectsCountProvider(userId: user.uid));

    final sheetColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.outline;

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
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor, width: 1.5)),
          ),
          child: Stack(
            children: [
              // ── Scrollable body ──
              ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 110),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      height: 5,
                      width: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // ── Instagram-style header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Circular avatar (tappable → viewer index 0)
                        GestureDetector(
                          onTap: () => _openPhotoViewer(images, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              child: ClipOval(
                                child: getUserImageWidget(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: Icon(Icons.person, size: 40, color: theme.colorScheme.onSurfaceVariant),
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
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // ··· report overflow
                                  IconButton(
                                    icon: Icon(
                                      Icons.more_horiz_rounded,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    tooltip: 'Report / Block',
                                    onPressed: () => _showReportBottomSheet(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Stats row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _StatItem(
                                    label: 'Photos',
                                    value: images.length.toString(),
                                    theme: theme,
                                  ),
                                  const SizedBox(width: 24),
                                  _StatItem(
                                    label: 'Likes',
                                    value: user.likesCount.toString(),
                                    theme: theme,
                                  ),
                                  const SizedBox(width: 24),
                                  _StatItem(
                                    label: 'Connects',
                                    value: connectsAsync.valueOrNull?.toString() ?? '–',
                                    theme: theme,
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
                    child: Text(
                      user.bio,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Photo grid (remaining photos after avatar) ──
                  if (images.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Photos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: gridPhotos.length,
                        itemBuilder: (ctx, i) {
                          // i+1 because avatar is index 0 in the full images list
                          return GestureDetector(
                            onTap: () => _openPhotoViewer(images, i + 1),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: getUserImageWidget(
                                gridPhotos[i],
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: isDark
                                      ? Colors.white.withAlpha(10)
                                      : Colors.black.withAlpha(8),
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.broken_image_outlined,
                                      color: theme.colorScheme.onSurfaceVariant),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        sheetColor.withValues(alpha: 0.0),
                        sheetColor.withValues(alpha: 0.9),
                        sheetColor,
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
                                  SnackBar(
                                    content: Text('Unliked ${user.name}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
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
                                    SnackBar(
                                      content: Text('Liked ${user.name}! ❤️'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: hasLiked ? Colors.redAccent : theme.colorScheme.primary,
                            side: BorderSide(
                              color: hasLiked ? Colors.redAccent : theme.colorScheme.primary,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(
                            hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: hasLiked ? Colors.redAccent : theme.colorScheme.primary,
                          ),
                          label: Text(
                            hasLiked ? 'Liked' : 'Like',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Connect
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showConnectDialog,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.send_rounded),
                          label: const Text(
                            'Connect',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
// Stat item widget
// ─────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
