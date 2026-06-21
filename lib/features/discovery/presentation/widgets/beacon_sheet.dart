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

    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F0);
    final borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final unselectedBg = isDark ? const Color(0xFF262626) : const Color(0xFFE2E5E2);
    final unselectedText = isDark ? Colors.white70 : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: borderColor, width: 1.5),
        ),
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
                      foregroundColor: isDark ? Colors.white70 : Colors.black54,
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
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  final emoji = preset['emoji']!;
                  final label = preset['label']!;
                  final isSelected = _selectedEmoji == emoji;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : unselectedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : unselectedBg,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$emoji $label',
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : unselectedText,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
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
              height: 50,
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
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  hasActiveBeacon ? 'Update Beacon' : 'Drop Beacon',
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
}
