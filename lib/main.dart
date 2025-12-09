import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/boundary/boundary_marking_screen.dart';
import 'features/result/area_result_screen.dart';
import 'features/saved/saved_plots_screen.dart';
import 'features/saved/plot_view_screen.dart';
import 'core/saved_plots_provider.dart';
import 'features/converter/unit_converter_screen.dart';
import 'features/home/help_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/home/about_screen.dart';
import 'features/home/user_guide_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'core/theme.dart';
import 'core/localization.dart';
import 'core/preferences.dart';
import 'core/connectivity_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter errors globally
  FlutterError.onError = (FlutterErrorDetails details) {
    // For other errors, use default handling
    FlutterError.presentError(details);
  };

  // Initialize Firebase first
  await Firebase.initializeApp();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Enable debug mode for App Check (only for development)
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  }

  // Bypass reCAPTCHA/App Check for testing
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  // Create a temporary ProviderContainer to load settings
  final container = ProviderContainer();
  await container.read(darkModeProvider.notifier).loadState();
  await container.read(offlineModeProvider.notifier).loadState();
  await container.read(onboardingCompletedProvider.notifier).loadState();
  await container.read(mapTypeProvider.notifier).loadState();
  await container.read(defaultUnitProvider.notifier).loadState();
  container.dispose();

  runApp(const ProviderScope(child: BhuMitraApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/boundary',
      builder: (context, state) => const BoundaryMarkingScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const AreaResultScreen(),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedPlotsScreen(),
    ),
    GoRoute(
      path: '/plot-view',
      builder: (context, state) {
        final plot = state.extra as SavedPlot;
        return PlotViewScreen(plot: plot);
      },
    ),
    GoRoute(
      path: '/converter',
      builder: (context, state) => const UnitConverterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),
    GoRoute(
      path: '/user-guide',
      builder: (context, state) => const UserGuideScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
  ],
);

class BhuMitraApp extends ConsumerStatefulWidget {
  const BhuMitraApp({super.key});

  @override
  ConsumerState<BhuMitraApp> createState() => _BhuMitraAppState();
}

class _BhuMitraAppState extends ConsumerState<BhuMitraApp> {
  @override
  void initState() {
    super.initState();
    // Load persisted settings
    ref.read(localeProvider.notifier).loadLocale();
    ref.read(darkModeProvider.notifier).loadState();
    ref.read(offlineModeProvider.notifier).loadState();
    ref.read(onboardingCompletedProvider.notifier).loadState();
    ref.read(autoSaveProvider.notifier).loadState();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'BhuMitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      routerConfig: _router,
      builder: (context, child) {
        return ConnectivityWrapper(child: child!);
      },
    );
  }
}
