import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discovery/data/models/nearby_user.dart';
import '../../../discovery/presentation/controllers/discovery_providers.dart';
import '../../../discovery/presentation/widgets/profile_detail_sheet.dart';
import '../../data/models/interaction_model.dart';
import '../../data/repositories/interaction_repository.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          bio: 'Gym enthusiast & fitness trainer. Let\'s crush a workout together!',
          profilePictures: const [
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
          ],
          vibeTags: const ['🏋️ Gym', '🍕 Foodie'],
          isGhostMode: false,
          lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
        );
      }
      return UserModel(
        uid: 'mock_3',
        name: 'Aria',
        bio: 'Art director & film nerd. Let\'s talk about cinema!',
        profilePictures: const [
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
        ],
        vibeTags: const ['🎨 Art', '🎬 Movies'],
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
    final currentUserId = 'me'; // Mock current user

    final matchesAsync = ref.watch(matchesStreamProvider(currentUserId: currentUserId));
    final wavesAsync = ref.watch(incomingWavesStreamProvider(currentUserId: currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connections',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Matches ⚡'),
            Tab(text: 'Waves 👋'),
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
          controller: _tabController,
          children: [
            // Matches Tab List
            matchesAsync.when(
              data: (matches) => _buildMatchesList(matches, currentUserId, theme),
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),

            // Waves Tab List
            wavesAsync.when(
              data: (waves) => _buildWavesList(waves, theme),
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(List<MatchModel> matches, String currentUserId, ThemeData theme) {
    if (matches.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.favorite_border_rounded,
        title: 'No Matches Yet',
        body: 'Keep looking around! Mutual likes will appear here, opening up chats.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: matches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = matches[index];
        final targetUserId = match.user1Id == currentUserId ? match.user2Id : match.user1Id;
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
            onTap: () => _showProfileDetail(context, user),
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
                  // Trailing Location Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
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

  Widget _buildWavesList(List<InteractionModel> waves, ThemeData theme) {
    if (waves.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: Icons.back_hand_outlined,
        title: 'No Waves Yet',
        body: 'When someone nearby waves at you, they will show up here so you can wave back.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: waves.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final wave = waves[index];
        final sender = _resolveUser(wave.senderId);

        final avatarUrl = sender.profilePictures.isNotEmpty ? sender.profilePictures[0] : '';

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
            onTap: () => _showProfileDetail(context, sender),
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
                          '${sender.name} waved at you!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wave back to match instantly.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Wave gesture button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      ref.read(interactionRepositoryProvider).sendLike(
                            currentUserId: 'me',
                            targetUserId: sender.uid,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Matched with ${sender.name}! ⚡')),
                      );
                    },
                    icon: const Icon(Icons.back_hand),
                  ),
                ],
              ),
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
                size: 64,
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
