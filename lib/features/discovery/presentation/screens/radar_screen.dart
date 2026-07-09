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



  Widget _buildHeader(ThemeData theme) {
    final cardBg = theme.colorScheme.surface;
    final borderBg = theme.colorScheme.outline;
    final textColor = theme.colorScheme.onSurface;
    final hintColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        // App Logo + Title Row
        Row(
          children: [
            Image.asset(
              isDark ? 'assets/logo/app_logo.png' : 'assets/logo/app_logo_light.png',
              height: 24,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search Bar
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
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(NearbyUser nearbyUser) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.colorScheme.surface;
    final borderBg = theme.colorScheme.outline;

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
              _buildHeader(theme),
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
                      return nameMatch || bioMatch;
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
                              _searchQuery.isNotEmpty
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

    final cardBg = theme.colorScheme.surface;
    final borderBg = theme.colorScheme.outline;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.colorScheme.onSurfaceVariant;

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
