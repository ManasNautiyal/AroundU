import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../../../discovery/presentation/widgets/profile_detail_sheet.dart';
import '../../data/models/interaction_model.dart';
import '../../data/models/message_request_model.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/screens/local_room_screen.dart';
import '../../data/repositories/interaction_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../discovery/presentation/controllers/user_providers.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';
import '../widgets/match_overlay.dart';

class InboxScreen extends ConsumerStatefulWidget {
  final int? selectedTabOverride;
  
  const InboxScreen({super.key, this.selectedTabOverride});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _showReceivedLikes = true;

  void _showProfileDetail(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(userModel: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final activeConnectionsAsync = ref.watch(matchesStreamProvider(currentUserId: currentUserId));
    final pendingRequestsAsync = ref.watch(connectionRequestsStreamProvider(currentUserId: currentUserId));

    final decoration = BoxDecoration(
      color: theme.scaffoldBackgroundColor,
    );

    // If split navigation overrides the view, render only the specific tab list
    if (widget.selectedTabOverride != null) {
      if (widget.selectedTabOverride == 0) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Chats',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Container(
            decoration: decoration,
            child: activeConnectionsAsync.when(
              data: (connections) => _buildMessagesList(connections, currentUserId, theme),
              error: (err, _) => Center(child: Text('Error loading messages: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      } else {
        final receivedLikesAsync = ref.watch(receivedLikesStreamProvider(currentUserId: currentUserId));
        final sentLikesAsync = ref.watch(sentLikesStreamProvider(currentUserId: currentUserId));
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'People',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Container(
            decoration: decoration,
            child: Column(
              children: [
                // Choice Chips filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Liked Me (${receivedLikesAsync.valueOrNull?.length ?? 0})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _showReceivedLikes ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          selected: _showReceivedLikes,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
                          checkmarkColor: theme.colorScheme.onPrimary,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _showReceivedLikes = true;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Liked by Me (${sentLikesAsync.valueOrNull?.length ?? 0})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_showReceivedLikes ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          selected: !_showReceivedLikes,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
                          checkmarkColor: theme.colorScheme.onPrimary,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _showReceivedLikes = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: _showReceivedLikes
                      ? receivedLikesAsync.when(
                          data: (likes) => _buildReceivedLikesList(likes, currentUserId, theme),
                          error: (err, _) => Center(child: Text('Error loading likes: $err')),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        )
                      : sentLikesAsync.when(
                          data: (likes) => _buildSentLikesList(likes, currentUserId, theme),
                          error: (err, _) => Center(child: Text('Error loading sent likes: $err')),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Inbox',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            indicatorColor: theme.colorScheme.primary,
            tabs: [
              Tab(
                text: activeConnectionsAsync.when(
                  data: (list) => 'Messages (${list.length})',
                  error: (err, stack) => 'Messages (0)',
                  loading: () => 'Messages (...)',
                ),
              ),
              Tab(
                text: pendingRequestsAsync.when(
                  data: (list) => 'Requests (${list.length})',
                  error: (err, stack) => 'Requests (0)',
                  loading: () => 'Requests (...)',
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: decoration,
          child: TabBarView(
            children: [
              // Messages Tab: List of active connections
              activeConnectionsAsync.when(
                data: (connections) => _buildMessagesList(connections, currentUserId, theme),
                error: (err, _) => Center(child: Text('Error loading messages: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),

              // Requests Tab: List of pending message requests
              pendingRequestsAsync.when(
                data: (requests) => _buildRequestsList(requests, theme),
                error: (err, _) => Center(child: Text('Error loading requests: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MatchModel> connections, String currentUserId, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final isInRoom = ref.watch(inLocalRoomProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: connections.length + (isInRoom ? 1 : 0),
      itemBuilder: (context, index) {
        if (isInRoom && index == 0) {
          return Column(
            children: [
              _buildLocalRoomTile(theme, borderBg, subTextColor),
              if (connections.isNotEmpty)
                Divider(
                  color: borderBg,
                  height: 1,
                  thickness: 1.0,
                ),
            ],
          );
        }
        
        final connectionIndex = isInRoom ? index - 1 : index;
        return Column(
          children: [
            MatchTile(
              connection: connections[connectionIndex],
              currentUserId: currentUserId,
              theme: theme,
            ),
            if (connectionIndex < connections.length - 1)
              Divider(
                color: borderBg,
                height: 1,
                thickness: 1.0,
              ),
          ],
        );
      },
    );
  }

  Widget _buildLocalRoomTile(ThemeData theme, Color borderBg, Color subTextColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LocalRoomScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withAlpha(20),
                child: Icon(
                  Icons.store_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 Downtown Coffee Shop',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          height: 6,
                          width: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Proximity Chat Room',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing Proximity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderBg, width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nearby',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<MessageRequestModel> requests, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (requests.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.mark_chat_unread_outlined,
        title: 'No Pending Requests',
        body: 'You are all caught up! New intro message requests from nearby users will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: requests.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
        height: 1,
        thickness: 1.0,
      ),
      itemBuilder: (context, index) {
        return MessageRequestTile(
          request: requests[index],
          theme: theme,
          onShowProfile: _showProfileDetail,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedLikesList(List<InteractionModel> likes, String currentUserId, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (likes.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.favorite_border_rounded,
        title: 'No Likes Yet',
        body: 'Check out the radar and scan for nearby profiles. People who like you will appear here!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: likes.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
        height: 1,
        thickness: 1.0,
      ),
      itemBuilder: (context, index) {
        final like = likes[index];
        return ReceivedLikeTile(
          like: like,
          currentUserId: currentUserId,
          theme: theme,
          onShowProfile: (ctx, user) => _showProfileDetail(ctx, user),
        );
      },
    );
  }

  Widget _buildSentLikesList(List<InteractionModel> likes, String currentUserId, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (likes.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.favorite_outline_rounded,
        title: 'No Sent Likes',
        body: 'Likes you send to nearby people will be listed here. You can unlike them at any time.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: likes.length,
      separatorBuilder: (context, index) => Divider(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
        height: 1,
        thickness: 1.0,
      ),
      itemBuilder: (context, index) {
        final like = likes[index];
        return SentLikeTile(
          like: like,
          currentUserId: currentUserId,
          theme: theme,
          onShowProfile: (ctx, user) => _showProfileDetail(ctx, user),
        );
      },
    );
  }
}

class MatchTile extends ConsumerWidget {
  final MatchModel connection;
  final String currentUserId;
  final ThemeData theme;

  const MatchTile({
    super.key,
    required this.connection,
    required this.currentUserId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final targetUserId = connection.user1Id == currentUserId ? connection.user2Id : connection.user1Id;
    final userAsync = ref.watch(userProfileProvider(targetUserId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }
        final avatarUrl = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    matchId: connection.id,
                    targetUser: user,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: getUserImageProvider(avatarUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              height: 6,
                              width: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active now',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Trailing Proximity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderBg, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nearby',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFE2E5E2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFE2E5E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFE2E5E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      error: (err, _) => const SizedBox.shrink(),
    );
  }
}

class MessageRequestTile extends ConsumerWidget {
  final MessageRequestModel request;
  final ThemeData theme;
  final Function(BuildContext, UserModel) onShowProfile;

  const MessageRequestTile({
    super.key,
    required this.request,
    required this.theme,
    required this.onShowProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F2);
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final senderAsync = ref.watch(userProfileProvider(request.senderId));

    return senderAsync.when(
      data: (sender) {
        if (sender == null) {
          return const SizedBox.shrink();
        }
        final avatarUrl = sender.profilePictures.isNotEmpty ? sender.profilePictures[0] : '';
        return Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Details Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onShowProfile(context, sender),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: getUserImageProvider(avatarUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Sent a message request',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Intro Message Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderBg, width: 1.0),
                  ),
                  child: Text(
                    request.introMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: subTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Decline Button
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final repo = ref.read(interactionRepositoryProvider);
                          await repo.declineConnectionRequest(request.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Declined request from ${sender.name}.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: subTextColor,
                          side: BorderSide(color: borderBg),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept Button
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final repo = ref.read(interactionRepositoryProvider);
                          await repo.acceptConnectionRequest(request);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Accepted request! Chat with ${sender.name} is now open.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.black,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFE2E5E2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFE2E5E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : const Color(0xFFE2E5E2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
      error: (err, _) => const SizedBox.shrink(),
    );
  }
}

class ReceivedLikeTile extends ConsumerWidget {
  final InteractionModel like;
  final String currentUserId;
  final ThemeData theme;
  final Function(BuildContext, UserModel) onShowProfile;

  const ReceivedLikeTile({
    super.key,
    required this.like,
    required this.currentUserId,
    required this.theme,
    required this.onShowProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final senderAsync = ref.watch(userProfileProvider(like.senderId));
    final sentLikesAsync = ref.watch(sentLikesStreamProvider(currentUserId: currentUserId));
    final hasLikedBack = sentLikesAsync.valueOrNull?.any((l) => l.receiverId == like.senderId) ?? false;

    return senderAsync.when(
      data: (sender) {
        if (sender == null) return const SizedBox.shrink();
        final avatarUrl = sender.profilePictures.isNotEmpty ? sender.profilePictures[0] : '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onShowProfile(context, sender),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: getUserImageProvider(avatarUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Liked your profile',
                      style: theme.textTheme.bodySmall?.copyWith(color: subTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!hasLikedBack)
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final repo = ref.read(interactionRepositoryProvider);
                      final mutual = await repo.sendLike(
                        currentUserId: currentUserId,
                        targetUserId: sender.uid,
                      );
                      if (context.mounted) {
                        if (mutual) {
                          MatchOverlay.show(
                            context: context,
                            matchedUser: sender,
                            onSendMessage: () {
                              final matchId = currentUserId.compareTo(sender.uid) < 0
                                  ? '${currentUserId}_${sender.uid}'
                                  : '${sender.uid}_$currentUserId';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    matchId: matchId,
                                    targetUser: sender,
                                  ),
                                ),
                              );
                            },
                            onKeepLooking: () {},
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Liked ${sender.name} back!')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.favorite_rounded, size: 14),
                    label: const Text('Like Back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
                  ),
                  child: Text(
                    'Connected',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 56),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class SentLikeTile extends ConsumerWidget {
  final InteractionModel like;
  final String currentUserId;
  final ThemeData theme;
  final Function(BuildContext, UserModel) onShowProfile;

  const SentLikeTile({
    super.key,
    required this.like,
    required this.currentUserId,
    required this.theme,
    required this.onShowProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final receiverAsync = ref.watch(userProfileProvider(like.receiverId));

    return receiverAsync.when(
      data: (receiver) {
        if (receiver == null) return const SizedBox.shrink();
        final avatarUrl = receiver.profilePictures.isNotEmpty ? receiver.profilePictures[0] : '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onShowProfile(context, receiver),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: getUserImageProvider(avatarUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiver.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'You liked their profile',
                      style: theme.textTheme.bodySmall?.copyWith(color: subTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final repo = ref.read(interactionRepositoryProvider);
                    await repo.unlikeUser(
                      currentUserId: currentUserId,
                      targetUserId: receiver.uid,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unliked ${receiver.name}.')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.0),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('Unlike', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 56),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
