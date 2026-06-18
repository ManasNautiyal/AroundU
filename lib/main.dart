import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/onboarding/presentation/screens/location_permission_screen.dart';
import 'features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'features/connections/presentation/screens/main_layout.dart';
import 'features/onboarding/presentation/controllers/onboarding_providers.dart';

void main() {
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
    final step = ref.watch(onboardingStepProvider);

    switch (step) {
      case 0:
        return const LoginScreen();
      case 1:
        return const LocationPermissionScreen();
      case 2:
        return const ProfileSetupScreen();
      case 3:
        return const MainLayout();
      default:
        return const LoginScreen();
    }
  }
}
