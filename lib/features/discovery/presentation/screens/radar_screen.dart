import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../chat/presentation/screens/local_room_screen.dart';
import '../../data/models/nearby_user.dart';
import '../../data/repositories/discovery_repository.dart';
import '../controllers/discovery_providers.dart';
import '../widgets/beacon_sheet.dart';
import '../widgets/profile_detail_sheet.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isUpdatingLocation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    if (_isUpdatingLocation) return;
    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      final locService = ref.read(locationServiceProvider);

      final enabled = await locService.isLocationServiceEnabled();
      if (!enabled) {
        throw const LocationServiceDisabledException();
      }

      var permission = await locService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await locService.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const LocationPermissionDeniedException();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationPermissionDeniedForeverException();
      }

      ref.invalidate(userPositionProvider);
      final position = await ref.read(userPositionProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location updated: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showLocationErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = false;
        });
      }
    }
  }

  void _showLocationErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: Colors.white70),
            const SizedBox(width: 8),
            const Text('Location Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F2);
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

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
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F2);
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final hintColor = isDark ? Colors.white38 : Colors.black38;

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
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F2);
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);

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
                  color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE2E5E2),
                  child: Icon(Icons.person, size: 40, color: isDark ? Colors.white24 : Colors.black26),
                ),
                placeholder: Container(
                  color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE2E5E2),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white38 : Colors.black26)),
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
                      border: Border.all(color: const Color(0xFF262626), width: 1.0),
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
    final cardBg = isDark ? const Color(0xFF121212) : const Color(0xFFF3F5F2);
    final borderBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final selectedVibe = ref.watch(selectedVibeFilterProvider);
    final isInLocalRoom = ref.watch(inLocalRoomProvider);
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
                      activeTrackColor: isDark ? Colors.white38 : Colors.black38,
                      inactiveThumbColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      inactiveTrackColor: isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2),
                      onChanged: (val) {
                        ref.read(ghostModeControllerProvider.notifier).toggle();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isInLocalRoom) ...[
                Material(
                  elevation: 0,
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: borderBg, width: 1.2),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocalRoomScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.pin_drop_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Downtown Coffee Shop Zone",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "📍 You are in the zone. Join Chat ➔",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                  error: (err, stack) => Center(
                    child: Text(
                      'Failed to load nearby profiles: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
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
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: borderBg, width: 1.2),
              ),
              child: _isUpdatingLocation
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.near_me_rounded, color: theme.colorScheme.primary, size: 20),
                      onPressed: _updateLocation,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
