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
import '../../../chat/data/models/proximity_room_model.dart';
import 'package:intl/intl.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/data/models/message_model.dart';
import '../../../chat/presentation/controllers/proximity_rooms_controller.dart';
import '../../../chat/presentation/widgets/create_room_sheet.dart';
import '../widgets/match_overlay.dart';

class InboxScreen extends ConsumerStatefulWidget {
  final int? selectedTabOverride;
  
  const InboxScreen({super.key, this.selectedTabOverride});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _showReceivedLikes = true;
  int _chatsSubTab = 0; // 0: Primary (1-on-1), 1: Chatrooms, 2: Requests

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
        final requests = pendingRequestsAsync.valueOrNull ?? [];
        final connections = activeConnectionsAsync.valueOrNull ?? [];
        final proximityRoomsAsync = ref.watch(proximityRoomsProvider);
        final List<ProximityRoomModel> proximityRooms = proximityRoomsAsync.valueOrNull ?? [];
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Chats',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Create Chat Room',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CreateRoomSheet(),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
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
                              'Primary (${connections.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _chatsSubTab == 0 ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          selected: _chatsSubTab == 0,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
                          checkmarkColor: theme.colorScheme.onPrimary,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _chatsSubTab = 0;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.forum_rounded,
                            size: 16,
                            color: _chatsSubTab == 1 ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                          ),
                          label: Center(
                            child: Text(
                              'Chatrooms (${proximityRooms.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _chatsSubTab == 1 ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          selected: _chatsSubTab == 1,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
                          checkmarkColor: theme.colorScheme.onPrimary,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _chatsSubTab = 1;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Requests (${requests.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _chatsSubTab == 2 ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          selected: _chatsSubTab == 2,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
                          checkmarkColor: theme.colorScheme.onPrimary,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _chatsSubTab = 2;
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
                  child: _chatsSubTab == 0
                      ? activeConnectionsAsync.when(
                          data: (connectionsList) => _buildPrimaryMessagesList(connectionsList, currentUserId, theme),
                          error: (err, _) => Center(child: Text('Error loading messages: $err')),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        )
                      : _chatsSubTab == 1
                          ? proximityRoomsAsync.when(
                              data: (roomsList) => _buildProximityRoomsList(roomsList, theme),
                              error: (err, _) => Center(child: Text('Error loading chatrooms: $err')),
                              loading: () => const Center(child: CircularProgressIndicator()),
                            )
                          : pendingRequestsAsync.when(
                              data: (requestsList) => _buildRequestsList(requestsList, theme),
                              error: (err, _) => Center(child: Text('Error loading requests: $err')),
                              loading: () => const Center(child: CircularProgressIndicator()),
                            ),
                ),
              ],
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
                              'Likes (${receivedLikesAsync.valueOrNull?.length ?? 0})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _showReceivedLikes ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          selected: _showReceivedLikes,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
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
                              'Liked (${sentLikesAsync.valueOrNull?.length ?? 0})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_showReceivedLikes ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          selected: !_showReceivedLikes,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
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

  Widget _buildPrimaryMessagesList(
    List<MatchModel> connections,
    String currentUserId,
    ThemeData theme,
  ) {
    if (connections.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Primary Chats',
        body: 'Your 1-on-1 matched connections and accepted text requests will appear here. Explore the Map tab to discover people around you!',
      );
    }

    final borderBg = theme.colorScheme.outline;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: connections.length,
      separatorBuilder: (context, index) => Divider(
        color: borderBg,
        height: 1,
        thickness: 1.0,
      ),
      itemBuilder: (context, index) {
        return MatchTile(
          connection: connections[index],
          currentUserId: currentUserId,
          theme: theme,
        );
      },
    );
  }

  Widget _buildProximityRoomsList(List<ProximityRoomModel> proximityRooms, ThemeData theme) {
    if (proximityRooms.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.forum_rounded,
        title: 'No Chat Rooms in Range',
        body: 'There are no active proximity chat rooms within your range. Tap below to create a room!',
        actionButtonText: 'Create Room',
        onActionButtonPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateRoomSheet(),
          );
        },
      );
    }

    final borderBg = theme.colorScheme.outline;
    final subTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: proximityRooms.length,
      separatorBuilder: (context, index) => Divider(
        color: borderBg,
        height: 1,
        thickness: 1.0,
      ),
      itemBuilder: (context, index) {
        final room = proximityRooms[index];
        return _buildProximityRoomTile(room, theme, borderBg, subTextColor);
      },
    );
  }

  Widget _buildMessagesList(List<MatchModel> connections, String currentUserId, ThemeData theme) {
    final borderBg = theme.colorScheme.outline;
    final subTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final proximityRoomsAsync = ref.watch(proximityRoomsProvider);
    final List<ProximityRoomModel> proximityRooms = proximityRoomsAsync.valueOrNull ?? [];

    if (connections.isEmpty && proximityRooms.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Chats Yet',
        body: 'Your matched connections and nearby proximity rooms will appear here. Explore the Map tab to discover people around you!',
      );
    }

    final int totalCount = connections.length + proximityRooms.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < proximityRooms.length) {
          final room = proximityRooms[index];
          return Column(
            children: [
              _buildProximityRoomTile(room, theme, borderBg, subTextColor),
              if (index < proximityRooms.length - 1 || connections.isNotEmpty)
                Divider(
                  color: borderBg,
                  height: 1,
                  thickness: 1.0,
                ),
            ],
          );
        }
        
        final int connectionIndex = index - proximityRooms.length;
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

  Widget _buildProximityRoomTile(ProximityRoomModel room, ThemeData theme, Color borderBg, Color subTextColor) {
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocalRoomScreen(room: room),
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
                      '📍 ${room.name}',
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
              if (room.creatorId == currentUserId) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                  tooltip: 'Delete Room',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Proximity Room?'),
                        content: Text('Are you sure you want to delete "${room.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(chatRepositoryProvider).deleteProximityRoom(room.id);
                      ref.invalidate(proximityRoomsProvider);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<MessageRequestModel> requests, ThemeData theme) {
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
        color: theme.colorScheme.outline,
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
    String? actionButtonText,
    VoidCallback? onActionButtonPressed,
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
            if (actionButtonText != null && onActionButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionButtonPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionButtonText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedLikesList(List<InteractionModel> likes, String currentUserId, ThemeData theme) {
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
        color: theme.colorScheme.outline,
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
        color: theme.colorScheme.outline,
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

    final targetUserId = connection.user1Id == currentUserId ? connection.user2Id : connection.user1Id;
    final userAsync = ref.watch(userProfileProvider(targetUserId));
    final messagesAsync = ref.watch(messagesStreamProvider(matchId: connection.id));

    final messages = messagesAsync.valueOrNull ?? [];
    final lastMessage = messages.isNotEmpty ? messages.first : null;
    final unreadCount = messages.where((m) => m.senderId != currentUserId && !m.isRead).length;

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }
        final avatarUrl = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';
        final isOutgoing = lastMessage != null && lastMessage.senderId == currentUserId;
        final formattedTime = lastMessage != null ? DateFormat('h:mm a').format(lastMessage.timestamp) : '';

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (formattedTime.isNotEmpty)
                              Text(
                                formattedTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: unreadCount > 0
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isOutgoing) ...[
                              Icon(
                                Icons.done_all_rounded,
                                size: 16,
                                color: lastMessage.isRead ? Colors.blue : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                lastMessage != null
                                    ? (lastMessage.isDeleted
                                        ? 'This message was deleted'
                                        : (lastMessage.type == MessageType.image
                                            ? '📷 Photo'
                                            : (lastMessage.type == MessageType.voiceNote
                                                ? '🎤 Voice Note'
                                                : lastMessage.text)))
                                    : 'Start chatting...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: unreadCount > 0
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
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
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
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
    final cardBg = theme.colorScheme.surface;
    final borderBg = theme.colorScheme.outline;
    final subTextColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final isOutgoing = request.senderId == currentUserId;
    final otherUserId = isOutgoing ? request.receiverId : request.senderId;

    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }
        final avatarUrl = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';
        return Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Details Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onShowProfile(context, user),
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
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isOutgoing ? 'Sent text request (Pending response)' : 'Sent you a message request',
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
                    if (isOutgoing) ...[
                      // Cancel Sent Request Button
                      SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(interactionRepositoryProvider);
                            try {
                              await repo.declineConnectionRequest(request.id);
                              ref.invalidate(connectionRequestsStreamProvider(currentUserId: currentUserId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cancelled request to ${user.name}.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error cancelling request: $e'),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: subTextColor,
                            side: BorderSide(color: borderBg),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Cancel Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // Decline Button
                      SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(interactionRepositoryProvider);
                            try {
                              await repo.declineConnectionRequest(request.id);
                              ref.invalidate(connectionRequestsStreamProvider(currentUserId: currentUserId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Declined request from ${user.name}.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error declining request: $e'),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
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
                            try {
                              await repo.acceptConnectionRequest(request);
                              ref.invalidate(connectionRequestsStreamProvider(currentUserId: currentUserId));
                              ref.invalidate(matchesStreamProvider(currentUserId: currentUserId));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Accepted request! Chat with ${user.name} is now open.'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error accepting request: $e'),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 4),
                                  ),
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
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
                      ),
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
                color: theme.colorScheme.onSurface.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
                ),
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
    final subTextColor = theme.colorScheme.onSurfaceVariant;

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
    final subTextColor = theme.colorScheme.onSurfaceVariant;

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
