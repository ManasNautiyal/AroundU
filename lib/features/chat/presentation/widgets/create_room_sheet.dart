import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';

class CreateRoomSheet extends ConsumerStatefulWidget {
  const CreateRoomSheet({super.key});

  @override
  ConsumerState<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends ConsumerState<CreateRoomSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _radius = 100.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid ?? 'me';
      final positionAsync = ref.read(userPositionProvider);
      
      final position = positionAsync.valueOrNull;
      if (position == null) {
        throw Exception('Location not available. Please wait for GPS lock.');
      }

      await ref.read(chatRepositoryProvider).createProximityRoom(
        name: _nameController.text.trim(),
        creatorId: currentUserId,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInMeters: _radius,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_nameController.text.trim()}" chat zone created!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.2,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Proximity Chat Zone',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Anyone within range will automatically see and join this chat room.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Zone Name',
                hintText: 'e.g., Library Study Desk, Table 5',
                prefixIcon: const Icon(Icons.store_rounded),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a name for the chat zone';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Radius',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_radius.toInt()} meters',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: theme.colorScheme.primary,
                inactiveTrackColor: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                thumbColor: theme.colorScheme.primary,
                overlayColor: theme.colorScheme.primary.withAlpha(20),
                valueIndicatorTextStyle: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: _radius,
                min: 20.0,
                max: 300.0,
                divisions: 14,
                label: '${_radius.toInt()}m',
                onChanged: (val) {
                  setState(() {
                    _radius = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    )
                  : const Text(
                      'Create Zone',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
