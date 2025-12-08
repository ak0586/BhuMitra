import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Setup loading animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    // Call the login status check after a delay
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait for a moment to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if onboarding is completed
    final onboardingCompleted = ref.read(onboardingCompletedProvider);

    if (!onboardingCompleted) {
      if (mounted) {
        context.go('/onboarding');
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Check if we have a recent verification (< 24 hours)
        final prefs = await SharedPreferences.getInstance();
        final lastVerification =
            prefs.getInt('user_verification_last_check') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final verificationAge = now - lastVerification;
        final verificationValid = verificationAge < 86400000; // 24 hours

        if (!verificationValid) {
          // Reload user to check if account still exists / is enabled
          await user.reload();

          // Check if user exists in Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'User document does not exist',
            );
          }

          // Update verification timestamp
          await prefs.setInt('user_verification_last_check', now);
          print('User verification completed and cached');
        } else {
          print(
            'Using cached user verification (age: ${(verificationAge / 3600000).toStringAsFixed(1)} hours)',
          );
        }

        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        print('Error verifying user session: $e');
        // Don't sign out on network errors - allow offline access
        if (mounted) {
          context.go('/home');
        }
      }
    } else {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            ScaleTransition(
              scale: _progressAnimation,
              child: FadeTransition(
                opacity: _progressAnimation,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/BhuMitra_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'BhuMitra',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Measures Land Accurately',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 64),

            // Loading Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: SizedBox(
                height: 4,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
