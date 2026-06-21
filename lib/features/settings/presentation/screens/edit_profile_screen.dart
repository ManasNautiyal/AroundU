import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../discovery/data/repositories/user_repository.dart';
import '../../../../core/widgets/image_helper.dart';
import '../../../discovery/data/models/nearby_user.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final List<String?> _profilePictures = [null, null, null];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserModelProvider).valueOrNull;
    if (user != null) {
      _nameController.text = user.name;
      _bioController.text = user.bio;
      for (int i = 0; i < user.profilePictures.length && i < 3; i++) {
        _profilePictures[i] = user.profilePictures[i];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _profilePictures[index] = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access gallery: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profilePictures[0] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least a primary profile picture.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = ref.read(currentUserModelProvider).valueOrNull;
      if (user == null) throw Exception('No authenticated profile found');

      final List<String> uploadedUrls = [];
      for (int i = 0; i < _profilePictures.length; i++) {
        final path = _profilePictures[i];
        if (path != null) {
          if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('base64:')) {
            uploadedUrls.add(path);
          } else {
            final base64String = await compressAndEncodeImage(path);
            uploadedUrls.add(base64String);
          }
        }
      }

      await userRepo.updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        profilePictures: uploadedUrls,
      );

      ref.invalidate(currentUserModelProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Pictures Selection Layout (1 large + 2 small slots)
                Text(
                  'Profile Pictures',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth;
                    final double gap = 12.0;
                    final double leftWidth = (totalWidth - gap) * 0.6;
                    final double itemHeight = (leftWidth * 1.25);

                    return SizedBox(
                      height: itemHeight,
                      child: Row(
                        children: [
                          // Primary Photo
                          GestureDetector(
                            onTap: () => _pickImage(0),
                            child: Container(
                              width: leftWidth,
                              height: itemHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xFF121212),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _profilePictures[0] != null
                                      ? theme.colorScheme.primary
                                      : const Color(0xFF262626),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: _profilePictures[0] != null
                                    ? _buildImageWidget(_profilePictures[0]!)
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 32),
                                            SizedBox(height: 8),
                                            Text(
                                              'Primary Photo',
                                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: gap),

                          // Right Column containing two smaller secondary photos
                          Expanded(
                            child: Column(
                              children: [
                                // Photo 2
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickImage(1),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF121212),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF262626), width: 1.2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: _profilePictures[1] != null
                                            ? _buildImageWidget(_profilePictures[1]!)
                                            : const Center(
                                                child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white30, size: 24),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: gap),

                                // Photo 3
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickImage(2),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF121212),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF262626), width: 1.2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: _profilePictures[2] != null
                                            ? _buildImageWidget(_profilePictures[2]!)
                                            : const Center(
                                                child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white30, size: 24),
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
                const SizedBox(height: 32),

                // 2. Profile Details Fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Short Bio',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please write a short bio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),

                // 3. Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover);
    } else if (path.startsWith('base64:')) {
      return getUserImageWidget(path, fit: BoxFit.cover);
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }
}
