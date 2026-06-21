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
    const primaryBlue = Color(0xFF0058C6);
    const darkBlue = Color(0xFF0F5A9E);
    const lightPill = Color(0xFFD3E3FD);

    final baseLight = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white70,
        onSecondary: Colors.black,
        surface: Color(0xFF060606),
        onSurface: Colors.white,
        background: Color(0xFF060606),
        onBackground: Colors.white,
      ),
    );

    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white70,
        onSecondary: Colors.black,
        surface: Color(0xFF060606),
        onSurface: Colors.white,
        background: Color(0xFF060606),
        onBackground: Colors.white,
      ),
    );

    return MaterialApp(
      title: 'AroundU',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Force true AMOLED black globally
      theme: baseLight.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          indicatorColor: lightPill,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),
      darkTheme: baseDark.copyWith(
        scaffoldBackgroundColor: const Color(0xFF060606),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF121212), // Deep premium dark grey surface
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Sleeker corner radius
            side: const BorderSide(color: Color(0xFF262626), width: 1.2), // Micro thin border
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF060606),
          elevation: 8,
          indicatorColor: const Color(0xFF262626), // Premium dark grey indicator
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121212),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // Pill style input fields
            borderSide: const BorderSide(color: Color(0xFF262626), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF262626), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white24, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
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
          loading: () => const LoadingScreen(),
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
      loading: () => const LoadingScreen(),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Authentication error: $error'),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/app_logo.png',
              width: 140,
              height: 140,
              errorBuilder: (context, error, stackTrace) => const Text(
                'AroundU',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
