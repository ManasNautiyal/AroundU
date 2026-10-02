import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/nearby_user.dart';
import '../../data/repositories/discovery_repository.dart';
import '../controllers/discovery_providers.dart';
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

  String _formatRange(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toInt()} m';
  }

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
    return Column(
      children: [
        // App Logo
        Row(
          children: [
            Image.asset(
              'assets/logo/app_icon.png',
              height: 26,
              fit: BoxFit.contain,
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Search Bar — premium glassmorphic style
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.darkGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGray, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppTheme.textTertiary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search people nearby...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textTertiary, fontSize: 14),
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
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.subtleGray,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSlider(ThemeData theme, double rangeInMeters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.radar_rounded, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Slider(
              value: rangeInMeters,
              min: 50,
              max: 300,
              divisions: 5,
              onChanged: (val) {
                ref.read(discoveryRangeFilterProvider.notifier).setRange(val);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.darkGray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderGray, width: 0.5),
            ),
            child: Text(
              _formatRange(rangeInMeters),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(NearbyUser nearbyUser) {
    final user = nearbyUser.user;
    final primaryPhoto = user.profilePictures.isNotEmpty ? user.profilePictures[0] : '';

    return GestureDetector(
      onTap: () => _handleConnect(user),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderGray, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              getUserImageWidget(
                primaryPhoto,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppTheme.darkGray,
                  child: const Icon(Icons.person_rounded, size: 40, color: AppTheme.subtleGray),
                ),
                placeholder: Container(
                  color: AppTheme.darkGray,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.subtleGray),
                    ),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 0.75, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
              // Info overlay
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Distance chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 10, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _formatRange(nearbyUser.distanceInMeters),
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.uid ?? '';
    final isGhostMode = ref.watch(ghostModeControllerProvider);
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider(currentUserId: currentUserId));
    final rangeInMeters = ref.watch(discoveryRangeFilterProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 12),
              // Ghost mode toggle row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderGray, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      isGhostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: isGhostMode ? AppTheme.textSecondary : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGhostMode ? 'Ghost Mode' : 'Visible',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: Switch(
                        value: isGhostMode,
                        onChanged: (val) {
                          ref.read(ghostModeControllerProvider.notifier).toggle();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _buildRangeSlider(theme, rangeInMeters),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: AppTheme.darkGray,
                  onRefresh: () async {
                    ref.invalidate(nearbyUsersProvider(currentUserId: currentUserId));
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: nearbyUsersAsync.when(
                    data: (nearbyUsers) {
                      final filteredUsers = nearbyUsers.where((nearby) {
                        final user = nearby.user;
                        final nameMatch = user.name.toLowerCase().contains(_searchQuery.toLowerCase());
                        final bioMatch = user.bio.toLowerCase().contains(_searchQuery.toLowerCase());
                        final withinRange = nearby.distanceInMeters <= rangeInMeters;
                        return (nameMatch || bioMatch) && withinRange;
                      }).toList();

                      // Sort filtered users by likesCount in descending order
                      filteredUsers.sort((a, b) => b.user.likesCount.compareTo(a.user.likesCount));

                      if (filteredUsers.isEmpty) {
                        final allWithinRange = nearbyUsers
                            .where((u) => u.distanceInMeters <= rangeInMeters)
                            .toList();
                        final rangeIsTheCause =
                            nearbyUsers.isNotEmpty && allWithinRange.isEmpty;
                        final searchIsTheCause =
                            _searchQuery.isNotEmpty && nearbyUsers.isNotEmpty;

                        final emptyMsg = rangeIsTheCause
                            ? 'No one within ${_formatRange(rangeInMeters)} right now.\nTry widening your range.'
                            : searchIsTheCause
                                ? 'No matching profiles found nearby.'
                                : 'No one is nearby right now.';

                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkGray,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.textTertiary),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      emptyMsg,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
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
                    error: (err, stack) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildLocationErrorWidget(err, theme),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'create_room_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateRoomSheet(),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 22),
      ),
    );
  }

  Widget _buildLocationErrorWidget(dynamic err, ThemeData theme) {
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
      description = 'AroundU uses precise location to discover people and chat zones in your area.';
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
        child: Text(
          'Open App Settings',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      );
    } else if (isServiceDisabled) {
      iconData = Icons.gps_off_rounded;
      title = 'Location Services Disabled';
      description = 'Your device\'s GPS or location services are turned off. Please enable them to start scanning.';
      primaryBtnLabel = 'Open Location Settings';
      primaryBtnAction = () async {
        await Geolocator.openLocationSettings();
      };
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(28),
        decoration: AppDecorations.card(borderRadius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.subtleGray,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: primaryBtnAction,
              child: Text(primaryBtnLabel),
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
