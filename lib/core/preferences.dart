import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dark Mode Provider
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false);

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('dark_mode') ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('dark_mode', state);
  }
}

// Offline Mode Provider
final offlineModeProvider = StateNotifierProvider<OfflineModeNotifier, bool>((
  ref,
) {
  return OfflineModeNotifier();
});

class OfflineModeNotifier extends StateNotifier<bool> {
  OfflineModeNotifier() : super(false);

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('offline_mode') ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('offline_mode', state);
  }
}

// Onboarding Completed Provider
final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
      return OnboardingCompletedNotifier();
    });

class OnboardingCompletedNotifier extends StateNotifier<bool> {
  OnboardingCompletedNotifier() : super(false);

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('onboarding_completed') ?? false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    state = true;
    await prefs.setBool('onboarding_completed', true);
  }
}

// Map Type Provider
final mapTypeProvider = StateNotifierProvider<MapTypeNotifier, String>((ref) {
  return MapTypeNotifier();
});

class MapTypeNotifier extends StateNotifier<String> {
  MapTypeNotifier() : super('Normal');

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('map_type') ?? 'Normal';
  }

  Future<void> setMapType(String mapType) async {
    final prefs = await SharedPreferences.getInstance();
    state = mapType;
    await prefs.setString('map_type', mapType);
  }
}

// Default Unit Provider
final defaultUnitProvider = StateNotifierProvider<DefaultUnitNotifier, String>((
  ref,
) {
  return DefaultUnitNotifier();
});

class DefaultUnitNotifier extends StateNotifier<String> {
  DefaultUnitNotifier() : super('Square Feet');

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('default_unit') ?? 'Square Feet';
  }

  Future<void> setDefaultUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    state = unit;
    await prefs.setString('default_unit', unit);
  }
}
