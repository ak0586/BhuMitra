import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Helper class for managing location permissions and services
class LocationHelper {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permissions and return status
  static Future<LocationPermissionStatus> requestLocationPermission() async {
    // First check if service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    final status = await requestLocationPermission();
    if (status != LocationPermissionStatus.granted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }

  /// Get position stream for continuous tracking (Walk mode)
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update every 2 meters
      ),
    );
  }

  /// Get position stream for walking mode (high frequency)
  static Stream<Position> getWalkingModePositionStream() {
    // Android specific settings for interval
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // Update even if not moved much
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
        ),
      );
    }

    // iOS/Other settings
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Update even if not moved much
      ),
    );
  }

  /// Calculate distance between two positions in meters
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Get address from coordinates
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Return locality (City) and administrative area (State)
        // e.g., "Lucknow, Uttar Pradesh"
        String locality = place.locality ?? '';
        String adminArea = place.administrativeArea ?? '';

        if (locality.isNotEmpty && adminArea.isNotEmpty) {
          return '$locality, $adminArea';
        } else if (locality.isNotEmpty) {
          return locality;
        } else if (adminArea.isNotEmpty) {
          return adminArea;
        }
        return 'Unknown Location';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Location Unavailable';
    }
  }
}
