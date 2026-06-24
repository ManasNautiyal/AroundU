import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/onboarding_providers.dart';
import '../../../../core/widgets/image_helper.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late PageController _pageController;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();



  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(onboardingControllerProvider.notifier).setPage(index);
  }

  void _nextPage() {
    final state = ref.read(onboardingControllerProvider);
    if (state.currentPage == 0) {
      if (!state.isBasicInfoValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in your name and a short bio.')),
        );
        return;
      }
    } else if (state.currentPage == 1) {
      if (!state.isPicturesValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload at least a primary profile picture.')),
        );
        return;
      }
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        ref.read(onboardingControllerProvider.notifier).updatePicture(index, image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access gallery: $e')),
        );
      }
    }
  }

  Future<void> _submitProfile() async {
    try {
      await ref.read(onboardingControllerProvider.notifier).finishProfile();
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains(']')) {
          errorMsg = errorMsg.substring(errorMsg.indexOf(']') + 1).trim();
        } else if (errorMsg.startsWith('Exception:')) {
          errorMsg = errorMsg.replaceFirst('Exception:', '').trim();
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Profile Created!'),
          ],
        ),
        content: const Text(
          'Your AroundU profile is now set up. Prepare to discover nearby vibes within 100 meters!',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(onboardingStepProvider.notifier).setStep(3);
            },
            child: const Text('Let\'s Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Profile'),
        leading: state.currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Progress indicator
                  _buildProgressIndicator(state.currentPage, theme),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1BasicInfo(theme, state),
                        _buildStep2Pictures(theme, state),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: FilledButton(
                      onPressed: state.currentPage == 1
                          ? (state.isPicturesValid ? _submitProfile : null)
                          : _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        state.currentPage == 1 ? 'Finish Profile' : 'Next Step',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressIndicator(int currentPage, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentPage + 1} of 2',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                currentPage == 0
                    ? 'Basic Info'
                    : 'Profile Pictures',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(2, (index) {
              final active = index <= currentPage;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(
                    right: index < 1 ? 8.0 : 0.0,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1BasicInfo(ThemeData theme, OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell us about yourself',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is the first thing people within 100 meters will see when you cross paths.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              hintText: 'What should we call you?',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (val) =>
                ref.read(onboardingControllerProvider.notifier).updateName(val),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Short Bio',
              hintText: 'Share a little about yourself (e.g. coffee enthusiast, vinyl collector...)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (val) =>
                ref.read(onboardingControllerProvider.notifier).updateBio(val),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    if (path.startsWith('base64:') || path.startsWith('data:image/')) {
      return getUserImageWidget(path, fit: BoxFit.cover);
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    return getUserImageWidget(path, fit: BoxFit.cover);
  }

  Widget _buildStep2Pictures(ThemeData theme, OnboardingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add your best photos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload at least one primary photo. Clear faces help build real connections.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double gap = 16.0;
              final double leftWidth = (totalWidth - gap) * 0.6;
              final double itemHeight = (leftWidth * 1.25); // Aspect ratio for boxes

              return SizedBox(
                height: itemHeight,
                child: Row(
                  children: [
                    // Primary Large Photo Slot
                    GestureDetector(
                      onTap: () => _pickImage(0),
                      child: Container(
                        width: leftWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: state.profilePictures[0] != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: state.profilePictures[0] != null
                              ? _buildImageWidget(state.profilePictures[0]!)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 36,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Primary Photo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Required',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: gap),

                    // Right column containing 2 smaller slots
                    Expanded(
                      child: Column(
                        children: [
                          // Secondary Photo 1
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(1),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                    width: 1.2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: state.profilePictures[1] != null
                                      ? _buildImageWidget(state.profilePictures[1]!)
                                      : Center(
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 24,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gap),

                          // Secondary Photo 2
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickImage(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                    width: 1.2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: state.profilePictures[2] != null
                                      ? _buildImageWidget(state.profilePictures[2]!)
                                      : Center(
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 24,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


}

/// Custom painter to draw dashed borders for image uploads.
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    ));

    final Path dashPath = Path();
    double distance = 0.0;
    
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final double len = gap;
        if (distance + len > metric.length) {
          dashPath.addPath(
            metric.extractPath(distance, metric.length),
            Offset.zero,
          );
        } else {
          dashPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len * 2;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! DashedRectPainter ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
