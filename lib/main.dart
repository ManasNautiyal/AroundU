import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/onboarding/presentation/screens/location_permission_screen.dart';
import 'features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'features/connections/presentation/screens/main_layout.dart';
import 'features/onboarding/presentation/controllers/onboarding_providers.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/discovery/data/repositories/user_repository.dart';
import 'features/discovery/presentation/controllers/discovery_providers.dart';
import 'features/chat/presentation/controllers/local_room_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AroundU',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Support light & dark modes reactively
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const OnboardingRouter(),
    );
  }
}

class OnboardingRouter extends ConsumerWidget {
  const OnboardingRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen for authentication changes to reset/invalidate all local Riverpod states upon logout.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      if (next is AsyncData<User?> && next.value == null) {
        // User logged out: Reset all local/mock providers to clear state.
        ref.invalidate(onboardingStepProvider);
        ref.invalidate(onboardingControllerProvider);
        ref.invalidate(currentUserModelProvider);
        ref.invalidate(ghostModeControllerProvider);
        ref.invalidate(mockDiscoveryUsersControllerProvider);
        ref.invalidate(selectedVibeFilterProvider);
        ref.invalidate(inLocalRoomProvider);
        ref.invalidate(localRoomMessagesProvider);
      }
    });

    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // 2. If authenticated, fetch and check their Firestore user profile status.
        final userModelAsync = ref.watch(currentUserModelProvider);

        return userModelAsync.when(
          data: (userModel) {
            if (userModel != null) {
              // Profile already exists: navigate directly to main application (Step 3)
              return const MainLayout();
            } else {
              // Profile doesn't exist yet: run the onboarding steps.
              final step = ref.watch(onboardingStepProvider);
              switch (step) {
                case 1:
                  return const LocationPermissionScreen();
                case 2:
                  return const ProfileSetupScreen();
                case 3:
                  return const MainLayout();
                case 0:
                default:
                  // For a logged-in user starting onboarding, route to location permission (Step 1)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ref.read(onboardingStepProvider) == 0) {
                      ref.read(onboardingStepProvider.notifier).setStep(1);
                    }
                  });
                  return const LocationPermissionScreen();
              }
            }
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Failed to load profile: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(currentUserModelProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Authentication error: $error'),
        ),
      ),
    );
  }
}
