import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_repository.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class BeaconSheet extends ConsumerStatefulWidget {
  const BeaconSheet({super.key});

  @override
  ConsumerState<BeaconSheet> createState() => _BeaconSheetState();
}

class _BeaconSheetState extends ConsumerState<BeaconSheet> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedEmoji = '☕';

  // Premium, harmonious emoji presets
  final List<Map<String, String>> _presets = [
    {'emoji': '☕', 'label': 'Working'},
    {'emoji': '🏓', 'label': 'Playing'},
    {'emoji': '🍔', 'label': 'Eating'},
    {'emoji': '🎵', 'label': 'Jamming'},
    {'emoji': '📚', 'label': 'Studying'},
    {'emoji': '🏃', 'label': 'Running'},
    {'emoji': '💬', 'label': 'Chilling'},
  ];

  @override
  void initState() {
    super.initState();
    // Load existing beacon if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserModelProvider).valueOrNull;
      if (currentUser != null && currentUser.beaconEmoji != null) {
        setState(() {
          _selectedEmoji = currentUser.beaconEmoji!;
          _textController.text = currentUser.beaconMessage ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserModelProvider).valueOrNull;
    final hasActiveBeacon = currentUser != null && currentUser.beaconEmoji != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasActiveBeacon ? 'Edit Your Beacon' : 'Drop a Beacon',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (hasActiveBeacon)
                  TextButton.icon(
                    onPressed: () async {
                      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
                      if (uid != null) {
                        await ref.read(userRepositoryProvider).updateBeacon(uid, null, null);
                        ref.invalidate(currentUserModelProvider);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Beacon cleared! You are now offline.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Beacons let nearby users know what you\'re up to. They will appear just above your avatar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Emoji Selection Label
            Text(
              'Select status emoji',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Preset chips row (horizontal scrolling)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  final emoji = preset['emoji']!;
                  final isSelected = _selectedEmoji == emoji;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        '$emoji ${preset['label']}',
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primaryContainer,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedEmoji = emoji;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Message Field Label
            Text(
              'What\'s happening?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // TextField with remaining character counter
            TextFormField(
              controller: _textController,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'e.g., Grabbing a flat white, come join!',
                prefixIcon: Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                counterText: '', // Hide default counter to make custom clean UI
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a status message';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Custom elegant character counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_textController.text.length}/40',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _textController.text.length >= 40
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
                      if (uid != null) {
                        await ref.read(userRepositoryProvider).updateBeacon(
                              uid,
                              _selectedEmoji,
                              _textController.text.trim(),
                            );
                        ref.invalidate(currentUserModelProvider);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Text(_selectedEmoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                const Text('Beacon successfully dropped!'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    hasActiveBeacon ? 'Update Beacon' : 'Drop Beacon',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
