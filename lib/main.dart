import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/onboarding/presentation/screens/location_permission_screen.dart';
import 'features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'features/connections/presentation/screens/main_layout.dart';
import 'features/onboarding/presentation/controllers/onboarding_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/discovery/data/repositories/user_repository.dart';
import 'features/discovery/presentation/controllers/discovery_providers.dart';
import 'features/chat/presentation/controllers/proximity_rooms_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_observers.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLight = prefs.getBool('is_light_mode') ?? false;
      state = isLight ? ThemeMode.light : ThemeMode.dark;
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state == ThemeMode.dark) {
        state = ThemeMode.light;
        await prefs.setBool('is_light_mode', true);
      } else {
        state = ThemeMode.dark;
        await prefs.setBool('is_light_mode', false);
      }
    } catch (_) {}
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed or unsupported on this platform: $e');
  }
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final baseLight = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black87,
        onSecondary: Colors.white,
        surface: Color(0xFFF3F5F2),
        onSurface: Colors.black,
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
      ),
    );

    return MaterialApp(
      title: 'AroundU',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: baseLight.copyWith(
        scaffoldBackgroundColor: const Color(0xFFFBFDFA),
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
          color: const Color(0xFFF3F5F2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E5E2), width: 1.2),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFBFDFA),
          elevation: 8,
          indicatorColor: const Color(0xFFE2E5E2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
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
          fillColor: const Color(0xFFF3F5F2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFE2E5E2), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFE2E5E2), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.black26, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: const TextStyle(color: Colors.black38),
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
          labelTextStyle: WidgetStateProperty.all(
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
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      if (next is AsyncData<User?>) {
        final user = next.value;
        if (user == null) {
          ref.invalidate(onboardingStepProvider);
          ref.invalidate(onboardingControllerProvider);
          ref.invalidate(currentUserModelProvider);
          ref.invalidate(ghostModeControllerProvider);
          ref.invalidate(mockDiscoveryUsersControllerProvider);
          ref.invalidate(selectedVibeFilterProvider);
          ref.invalidate(proximityRoomsProvider);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.requestPermissions();
          });
        }
      }
    });

    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // Start tracking and observing if logged in
        ref.watch(locationTrackerProvider);
        ref.watch(interactionObserverProvider(user.uid));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.requestPermissions();
        });

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

class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060606) : const Color(0xFFFBFDFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isDark ? 'assets/logo/app_logo.png' : 'assets/logo/app_logo_light.png',
              width: 140,
              height: 140,
              errorBuilder: (context, error, stackTrace) => Text(
                'AroundU',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
