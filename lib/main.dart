import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'core/ad_manager.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Enhanced global error handler to prevent crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, show detailed errors
      FlutterError.presentError(details);
    } else {
      // In release mode, log errors but don't crash
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };

  // Catch errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
    }
    return true; // Prevent crash
  };

  try {
    // Load environment variables with timeout
    await dotenv
        .load(fileName: ".env")
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              debugPrint('Warning: .env file loading timed out');
            }
          },
        );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error loading .env: $e');
    }
    // Continue execution - app can work with fallback values
  }

  // Initialize Firebase with error handling and timeout
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timed out');
      },
    );

    // Enable Firestore offline persistence
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error configuring Firestore: $e');
      }
      // Continue - Firestore will work without offline persistence
    }

    // Enable debug mode for App Check (only for development)
    if (kDebugMode) {
      try {
        await FirebaseAppCheck.instance
            .activate(androidProvider: AndroidProvider.debug)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Error activating App Check: $e');
      }
    }

    // Bypass reCAPTCHA/App Check for testing (ONLY in Debug mode)
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
        );
      } catch (e) {
        debugPrint('Error configuring Firebase Auth: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Critical: Firebase initialization failed: $e');
    }
    // App can still run in limited mode without Firebase
  }

  // Initialize Mobile Ads SDK in background (non-blocking) with error handling
  AdManager()
      .initialize()
      .timeout(const Duration(seconds: 10))
      .then((_) {
        // Preload interstitial ad after AdMob is ready
        AdManager().loadInterstitialAd();
      })
      .catchError((error) {
        if (kDebugMode) {
          debugPrint('AdMob initialization failed: $error');
        }
        // App continues without ads if initialization fails
      });

  // Load settings with error handling
  try {
    final container = ProviderContainer();
    await Future.wait([
      container.read(darkModeProvider.notifier).loadState(),
      container.read(offlineModeProvider.notifier).loadState(),
      container.read(onboardingCompletedProvider.notifier).loadState(),
      container.read(mapTypeProvider.notifier).loadState(),
      container.read(defaultUnitProvider.notifier).loadState(),
    ]).timeout(const Duration(seconds: 5));
    container.dispose();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error loading settings: $e');
    }
    // App will use default settings if loading fails
  }

  runApp(const ProviderScope(child: BhuMitraApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  // Add error handling for navigation failures
  errorBuilder: (context, state) {
    if (kDebugMode) {
      debugPrint('Navigation error: ${state.error}');
    }
    // Return to home screen on navigation error
    return const HomeScreen();
  },
  // Add redirect logic with error handling
  redirect: (context, state) {
    try {
      // Add any redirect logic here if needed
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Redirect error: $e');
      }
      return '/home';
    }
  },
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
        try {
          final plot = state.extra as SavedPlot;
          return PlotViewScreen(plot: plot);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error loading plot: $e');
          }
          // Return to saved plots screen on error
          return const SavedPlotsScreen();
        }
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
        // Add error boundary wrapper
        ErrorWidget.builder = (FlutterErrorDetails details) {
          if (kDebugMode) {
            // In debug mode, show detailed error
            return ErrorWidget(details.exception);
          } else {
            // In release mode, show a simple error message
            return Material(
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'Something went wrong. Please restart the app.',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            );
          }
        };
        return ConnectivityWrapper(child: child!);
      },
    );
  }
}
