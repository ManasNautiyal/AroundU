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
import 'core/services/notification_service.dart';
import 'core/services/app_observers.dart';
import 'core/services/location_service.dart';

final dynamicColorSchemeProvider = FutureProvider<ColorScheme>((ref) async {
  return const ColorScheme.dark(
    primary: Colors.white,
    onPrimary: Colors.black,
    secondary: Colors.white,
    onSecondary: Colors.black,
    surface: Colors.black,
    onSurface: Colors.white,
    outline: Colors.white,
    outlineVariant: Colors.white,
  );
});

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
    final darkSchemeAsync = ref.watch(dynamicColorSchemeProvider);

    final darkColorScheme = darkSchemeAsync.valueOrNull ?? const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      outline: Colors.white,
      outlineVariant: Colors.white,
    );

    const darkCardColor = Colors.black;
    const darkBorderColor = Colors.white;

    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
    );

    return MaterialApp(
      title: 'AroundU',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: baseDark.copyWith(
        scaffoldBackgroundColor: darkColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: darkColorScheme.onSurface),
          titleTextStyle: TextStyle(
            color: darkColorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkCardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: darkBorderColor, width: 1.2),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          elevation: 8,
          indicatorColor: Colors.white,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.black);
            }
            return IconThemeData(color: Colors.white.withValues(alpha: 0.5));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
            }
            return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.5));
          }),
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
          fillColor: darkCardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: darkBorderColor, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: darkBorderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: darkColorScheme.primary.withValues(alpha: 0.5), width: 1.5),
          ),
          labelStyle: TextStyle(color: darkColorScheme.onSurfaceVariant),
          hintStyle: TextStyle(color: darkColorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
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
        final locationStatusAsync = ref.watch(locationPermissionAndServiceStatusProvider);

        return userModelAsync.when(
          data: (userModel) {
            final step = ref.watch(onboardingStepProvider);
            final isEnteringMainApp = userModel != null || step == 3;

            if (isEnteringMainApp) {
              return locationStatusAsync.when(
                data: (locationOk) {
                  if (locationOk) {
                    return const MainLayout();
                  } else {
                    return const LocationPermissionScreen();
                  }
                },
                loading: () => const LoadingScreen(),
                error: (error, stack) => const LocationPermissionScreen(),
              );
            } else {
              // Profile doesn't exist yet: run the onboarding steps.
              switch (step) {
                case 1:
                  return const LocationPermissionScreen();
                case 2:
                  return const ProfileSetupScreen();
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo image — centered with clean bounds
            Image.asset(
              'assets/logo/app_logo.png',
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              "Discover who's nearby",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
