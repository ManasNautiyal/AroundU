import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../data/models/nearby_user.dart';
import '../../../connections/data/repositories/interaction_repository.dart';
import '../../../safety/data/repositories/block_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';

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

  void _showReportBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final reasons = ['Spam', 'Harassment', 'Inappropriate Content'];

    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F0);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);

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
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report ${widget.userModel.name}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a reason for reporting this profile. This user will also be blocked automatically for your safety.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () async {
                    // Close the sheet
                    Navigator.pop(modalContext);
                    
                    // Show progress message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reporting ${widget.userModel.name}...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    
                    // Trigger block & report logic
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
                    // Close the Profile Detail sheet
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

    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F0);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: sheetColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.5),
                ),
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
                        'Connect with ${widget.userModel.name}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add a friendly note to introduce yourself! Tapping send will transmit this request to ${widget.userModel.name}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Intro Message',
                      hintText: 'e.g. Hey! I also love classic movies...',
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

                      // Close the dialog bottom sheet
                      Navigator.pop(modalContext);

                      // Call repository method
                      final repo = ref.read(interactionRepositoryProvider);
                      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
                      await repo.sendConnectionRequest(
                        currentUserId: currentUserId,
                        targetUserId: widget.userModel.uid,
                        introMessage: message,
                      );

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connection request sent to ${widget.userModel.name}!'),
                          backgroundColor: Colors.black,
                        ),
                      );
                      
                      // Close the parent ProfileDetailSheet
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Send Request',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
    final size = MediaQuery.of(context).size;
    final user = widget.userModel;

    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F0);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);

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
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: borderColor, width: 1.5),
            ),
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
                            return getUserImageWidget(
                              images[index],
                              fit: BoxFit.cover,
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
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.flag_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    tooltip: 'Report / Block User',
                                    onPressed: () => _showReportBottomSheet(context),
                                  ),
                                ],
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
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
                        sheetColor.withValues(alpha: 0.0),
                        sheetColor.withValues(alpha: 0.85),
                        sheetColor,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  child: FilledButton.icon(
                    onPressed: _showConnectDialog,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text(
                      'Connect & Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
