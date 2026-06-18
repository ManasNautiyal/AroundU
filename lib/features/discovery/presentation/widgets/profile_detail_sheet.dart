import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/nearby_user.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../../connections/presentation/widgets/match_overlay.dart';

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
  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isWaved = false;

  void _handleLike() async {
    setState(() {
      _isLiked = !_isLiked;
    });
    
    ScaffoldMessenger.of(context).clearSnackBars();
    
    if (_isLiked) {
      final repo = ref.read(interactionRepositoryProvider);
      final isMutualMatch = await repo.sendLike(
        currentUserId: 'me', // Mock current user
        targetUserId: widget.userModel.uid,
      );

      if (isMutualMatch && mounted) {
        // Dismiss the Profile Detail Bottom Sheet
        Navigator.pop(context);

        // Celebrate the match!
        MatchOverlay.show(
          context: context,
          matchedUser: widget.userModel,
          onSendMessage: () {
            // Placeholder: chat screen navigation in Phase 4
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening chat screen...')),
            );
          },
          onKeepLooking: () {},
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Liked ${widget.userModel.name}!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed like for ${widget.userModel.name}.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleWave() async {
    if (_isWaved) return;

    try {
      final repo = ref.read(interactionRepositoryProvider);
      await repo.sendWave(
        currentUserId: 'me',
        targetUserId: widget.userModel.uid,
      );

      setState(() {
        _isWaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wave sent to ${widget.userModel.name}! 👋'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on DailyWaveLimitExceededException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Out of waves for today! (Limit: 3/day)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final user = widget.userModel;

    // Filter out empty picture paths
    final images = user.profilePictures.where((pic) => pic.isNotEmpty).toList();
    if (images.isEmpty) {
      images.add('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500');
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Scrollable Profile Info Content
              ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // 1. Image Carousel (PageView)
                  SizedBox(
                    height: size.height * 0.42,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              width: size.width,
                            );
                          },
                        ),

                        // Carousel Top Handle / Indicator overlay
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              height: 5,
                              width: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(150),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        // Dot indicators
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (index) {
                                final isActive = index == _currentImageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  height: 6,
                                  width: isActive ? 16 : 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : Colors.white.withAlpha(180),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 2. Profile Details Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 110), // Bottom padding leaves space for actions
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Nearby Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(50),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Nearby',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Active Time status
                        Row(
                          children: [
                            Container(
                              height: 8,
                              width: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active now',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Bio Title
                        Text(
                          'Bio',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Bio Text
                        Text(
                          user.bio,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Vibe Tags
                        Text(
                          'Vibes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: user.vibeTags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant.withAlpha(50),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. Action Buttons Overlay (Sticky at Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.surface.withAlpha(0),
                        theme.colorScheme.surface.withAlpha(240),
                        theme.colorScheme.surface,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Direct Wave Button (Outlined/Secondary)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleWave,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: _isWaved
                                  ? theme.colorScheme.outlineVariant
                                  : theme.colorScheme.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            Icons.back_hand_rounded,
                            color: _isWaved
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                          label: Text(
                            _isWaved ? 'Waved' : 'Wave',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isWaved
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Heart/Like Button (Filled/Primary)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _handleLike,
                          style: FilledButton.styleFrom(
                            backgroundColor: _isLiked
                                ? Colors.redAccent
                                : theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isLiked ? 'Liked' : 'Like',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
