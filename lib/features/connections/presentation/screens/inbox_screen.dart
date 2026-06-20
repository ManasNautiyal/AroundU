import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';
import '../../../discovery/presentation/widgets/profile_detail_sheet.dart';
import '../../data/models/interaction_model.dart';
import '../../data/models/message_request_model.dart';
import '../controllers/social_mock_providers.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  /// Resolves the user profile model from our mock discovery users list or standard seeding fallbacks.
  UserModel _resolveUser(String uid) {
    if (uid == 'me') {
      return UserModel(
        uid: 'me',
        name: 'My Profile',
        bio: 'Self bio',
        profilePictures: const ['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'],
        vibeTags: const [],
        isGhostMode: false,
        lastActive: DateTime.now(),
      );
    }

    final nearbyList = ref.read(mockDiscoveryUsersControllerProvider);
    try {
      return nearbyList.firstWhere((u) => u.user.uid == uid).user;
    } catch (_) {
      // Seeding fallback profiles
      if (uid == 'mock_2') {
        return UserModel(
          uid: 'mock_2',
          name: 'Marcus',
          bio: '🏋️ Gym enthusiast & fitness trainer. Love hiking, rock climbing, and good food.',
          profilePictures: const [
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
          ],
          vibeTags: const ['🏋️ Gym', '⚽ Sports', '🍕 Foodie'],
          isGhostMode: false,
          lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
        );
      }
      return UserModel(
        uid: 'mock_3',
        name: 'Aria',
        bio: '🎨 Art director & film nerd. Let\'s talk about cinema!',
        profilePictures: const [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
        ],
        vibeTags: const ['🎨 Art', '🎬 Movies', '🎵 Music'],
        isGhostMode: false,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      );
    }
  }

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
    final activeConnections = ref.watch(mockActiveConnectionsProvider);
    final pendingRequests = ref.watch(mockMessageRequestsProvider);

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
              Tab(text: 'Messages (${activeConnections.length})'),
              Tab(text: 'Requests (${pendingRequests.length})'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.primaryContainer.withAlpha(20),
              ],
            ),
          ),
          child: TabBarView(
            children: [
              // Messages Tab: List of active connections
              _buildMessagesList(activeConnections, theme),

              // Requests Tab: List of pending message requests
              _buildRequestsList(pendingRequests, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<MatchModel> connections, ThemeData theme) {
    if (connections.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Chats Yet',
        body: 'Connect with people nearby on your radar. Approved requests will appear here!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: connections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final connection = connections[index];
        final targetUserId = connection.user1Id == 'me' ? connection.user2Id : connection.user1Id;
        final user = _resolveUser(targetUserId);

        final avatarUrl = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(55),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(avatarUrl),
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
                                color: theme.colorScheme.onSurfaceVariant,
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
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        final sender = _resolveUser(request.senderId);

        final avatarUrl = sender.profilePictures.isNotEmpty ? sender.profilePictures[0] : '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Details Row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showProfileDetail(context, sender),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(avatarUrl),
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
                              color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.introMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Decline Button
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(mockMessageRequestsProvider.notifier).declineRequest(request.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Declined request from ${sender.name}.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                    ),
                    const SizedBox(width: 12),
                    // Accept Button
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(mockMessageRequestsProvider.notifier).acceptRequest(request.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Accepted request! Chat with ${sender.name} is now open.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
}
