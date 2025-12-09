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

// Precision Provider
final precisionProvider = StateNotifierProvider<PrecisionNotifier, int>((ref) {
  return PrecisionNotifier();
});

class PrecisionNotifier extends StateNotifier<int> {
  PrecisionNotifier() : super(2);

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('precision_level') ?? 2;
  }

  Future<void> setPrecision(int precision) async {
    final prefs = await SharedPreferences.getInstance();
    state = precision;
    await prefs.setInt('precision_level', precision);
  }
}

// Cached Location Provider
final cachedLocationProvider =
    StateNotifierProvider<CachedLocationNotifier, ({double lat, double lng})?>((
      ref,
    ) {
      return CachedLocationNotifier();
    });

class CachedLocationNotifier
    extends StateNotifier<({double lat, double lng})?> {
  CachedLocationNotifier() : super(null);

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('cached_lat');
    final lng = prefs.getDouble('cached_lng');
    if (lat != null && lng != null) {
      state = (lat: lat, lng: lng);
    }
  }

  Future<void> setLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    state = (lat: lat, lng: lng);
    await prefs.setDouble('cached_lat', lat);
    await prefs.setDouble('cached_lng', lng);
  }
}

// Auto Save Provider
final autoSaveProvider = StateNotifierProvider<AutoSaveNotifier, bool>((ref) {
  return AutoSaveNotifier();
});

class AutoSaveNotifier extends StateNotifier<bool> {
  AutoSaveNotifier() : super(true);

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('auto_save') ?? true;
  }

  Future<void> setAutoSave(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    state = value;
    await prefs.setBool('auto_save', value);
  }
}
