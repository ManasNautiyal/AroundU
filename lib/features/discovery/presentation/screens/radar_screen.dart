import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/nearby_user.dart';
import '../../data/repositories/discovery_repository.dart';
import '../controllers/discovery_providers.dart';
import '../widgets/beacon_sheet.dart';
import '../widgets/profile_detail_sheet.dart';
import '../../../chat/presentation/widgets/create_room_sheet.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleConnect(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(userModel: user),
    );
  }

  void _showVibeFilterSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? Colors.black : Colors.white;
    final borderBg = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7);

    final presetVibes = [
      '☕ Coffee',
      '🎵 Music',
      '🏋️ Gym',
      '📚 Study',
      '💬 Chatting',
      '🎮 Gaming',
      '🍕 Food',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSelected = ref.watch(selectedVibeFilterProvider);
            return Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: borderBg, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Filter by Vibe',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ...presetVibes.map((vibe) {
                        final isSelected = currentSelected == vibe;
                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedVibeFilterProvider.notifier).selectFilter(isSelected ? null : vibe);
                            setModalState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : borderBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : borderBg,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              vibe,
                              style: TextStyle(
                                color: isSelected ? theme.colorScheme.onPrimary : subTextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  if (currentSelected != null) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        ref.read(selectedVibeFilterProvider.notifier).selectFilter(null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, String? selectedVibe) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? Colors.black : Colors.white;
    final borderBg = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7);
    final hintColor = isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderBg, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: hintColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search people...',
                          hintStyle: TextStyle(color: hintColor, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: Icon(Icons.close_rounded, color: hintColor, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: selectedVibe != null ? theme.colorScheme.primary : cardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedVibe != null ? theme.colorScheme.primary : borderBg,
                  width: 1.2,
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: selectedVibe != null ? theme.colorScheme.onPrimary : subTextColor,
                  size: 20,
                ),
                onPressed: _showVibeFilterSheet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(NearbyUser nearbyUser) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? Colors.black : Colors.white;
    final borderBg = isDark ? Colors.white : Colors.black;

    final user = nearbyUser.user;
    final primaryPhoto = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';

    return GestureDetector(
      onTap: () => _handleConnect(user),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderBg, width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              getUserImageWidget(
                primaryPhoto,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: isDark ? Colors.black : Colors.white,
                  child: Icon(Icons.person, size: 40, color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                ),
                placeholder: Container(
                  color: isDark ? Colors.black : Colors.white,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3))),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.55, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),
              if (user.beaconEmoji != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white : Colors.black, width: 1.0),
                    ),
                    child: Text(
                      user.beaconEmoji!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nearbyUser.fuzzedDistance,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final selectedVibe = ref.watch(selectedVibeFilterProvider);
    final isGhostMode = ref.watch(ghostModeControllerProvider);
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider(currentUserId: currentUserId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme, selectedVibe),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGhostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: subTextColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGhostMode ? 'Ghost Mode (Hidden)' : 'Visible (Scanning)',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: isGhostMode,
                      activeThumbColor: isDark ? Colors.white : Colors.black,
                      activeTrackColor: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.38),
                      inactiveThumbColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      onChanged: (val) {
                        ref.read(ghostModeControllerProvider.notifier).toggle();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: nearbyUsersAsync.when(
                  data: (nearbyUsers) {
                    final filteredUsers = nearbyUsers.where((nearby) {
                      final user = nearby.user;
                      final nameMatch = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      final bioMatch = user.bio.toLowerCase().contains(_searchQuery.toLowerCase());
                      if (!nameMatch && !bioMatch) return false;

                      if (selectedVibe != null) {
                        final vibeText = selectedVibe.split(' ').last.toLowerCase();
                        final vibeInTags = user.vibeTags.any((t) => t.toLowerCase().contains(vibeText));
                        final vibeInBio = user.bio.toLowerCase().contains(vibeText);
                        final vibeInBeacon = user.beaconMessage?.toLowerCase().contains(vibeText) ?? false;
                        final emojiMatch = user.beaconEmoji != null && selectedVibe.contains(user.beaconEmoji!);
                        return vibeInTags || vibeInBio || vibeInBeacon || emojiMatch;
                      }
                      return true;
                    }).toList();

                    // Sort filtered users by likesCount in descending order
                    filteredUsers.sort((a, b) => b.user.likesCount.compareTo(a.user.likesCount));

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 48, color: isDark ? Colors.white30 : Colors.black26),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty || selectedVibe != null
                                  ? 'No matching profiles found nearby.'
                                  : 'No one is nearby right now.\nTap recenter to scan your area.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: subTextColor, fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final nearbyUser = filteredUsers[index];
                        return _buildProfileCard(nearbyUser);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, stack) => _buildLocationErrorWidget(err, theme, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'drop_beacon_fab',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const BeaconSheet(),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.add_location_alt_rounded),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'create_room_fab',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const CreateRoomSheet(),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.store_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorWidget(dynamic err, ThemeData theme, bool isDark) {
    final errStr = err.toString();
    final isPermissionDenied = errStr.contains('permission') || errStr.contains('Permission');
    final isServiceDisabled = errStr.contains('disabled') || errStr.contains('Disabled');

    IconData iconData = Icons.location_off_rounded;
    String title = 'Location Error';
    String description = 'Failed to load nearby profiles. Please ensure location is enabled and permissions are granted.';
    String primaryBtnLabel = 'Retry';
    VoidCallback primaryBtnAction = () {
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
      ref.invalidate(nearbyUsersProvider(currentUserId: currentUserId));
    };
    Widget? secondaryBtn;

    if (isPermissionDenied) {
      iconData = Icons.security_rounded;
      title = 'Location Access Required';
      description = 'AroundU uses precise location permissions to discover people and chat zones in your area.';
      primaryBtnLabel = 'Grant Permission';
      primaryBtnAction = () async {
        try {
          final locService = ref.read(locationServiceProvider);
          final permission = await locService.requestPermission();
          if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
            await Geolocator.openAppSettings();
          } else {
            final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';
            ref.invalidate(nearbyUsersProvider(currentUserId: currentUserId));
          }
        } catch (_) {
          await Geolocator.openAppSettings();
        }
      };
      secondaryBtn = TextButton(
        onPressed: () async {
          await Geolocator.openAppSettings();
        },
        child: const Text('Open App Settings'),
      );
    } else if (isServiceDisabled) {
      iconData = Icons.gps_off_rounded;
      title = 'Location Services Disabled';
      description = 'Your device\'s GPS or location services are turned off. Please enable them to start scanning your area.';
      primaryBtnLabel = 'Open Location Settings';
      primaryBtnAction = () async {
        await Geolocator.openLocationSettings();
      };
    }

    final cardBg = isDark ? Colors.black : Colors.white;
    final borderBg = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderBg, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              iconData,
              size: 56,
              color: textColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: primaryBtnAction,
              style: FilledButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: cardBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: Text(
                primaryBtnLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (secondaryBtn != null) ...[
              const SizedBox(height: 8),
              secondaryBtn,
            ],
          ],
        ),
      ),
    );
  }
}
