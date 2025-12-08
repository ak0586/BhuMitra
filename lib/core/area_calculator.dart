import 'package:latlong2/latlong.dart';
import 'package:turf/turf.dart';

/// Utility class for calculating land area from GPS coordinates
class AreaCalculator {
  /// Calculate area in square meters from a list of LatLng coordinates
  /// using the turf package
  static double calculateAreaInSquareMeters(List<LatLng> coordinates) {
    if (coordinates.length < 3) {
      return 0.0;
    }

    try {
      // Convert LatLng to turf Position format [longitude, latitude]
      List<Position> positions = coordinates
          .map((latLng) => Position.of([latLng.longitude, latLng.latitude]))
          .toList();

      // Close the polygon by adding the first point at the end
      if (positions.first != positions.last) {
        positions.add(positions.first);
      }

      // Create a turf polygon
      var polygon = Feature<Polygon>(
        geometry: Polygon(coordinates: [positions]),
      );

      // Calculate area in square meters
      num? areaNum = area(polygon);
      double areaInSqMeters = (areaNum ?? 0.0).toDouble();

      return areaInSqMeters;
    } catch (e) {
      print('Error calculating area: $e');
      return 0.0;
    }
  }

  /// Convert square meters to all standard units
  static Map<String, double> convertFromSquareMeters(double squareMeters) {
    return {
      'squareMeters': squareMeters,
      'squareFeet': squareMeters * 10.764,
      'squareYards': squareMeters * 1.196,
      'acre': squareMeters * 0.000247105,
      'hectare': squareMeters * 0.0001,
    };
  }

  /// Calculate area and return all units
  static Map<String, double> calculateAllUnits(List<LatLng> coordinates) {
    double sqm = calculateAreaInSquareMeters(coordinates);
    return convertFromSquareMeters(sqm);
  }

  /// Format area value based on magnitude
  static String formatArea(double value) {
    if (value < 1) {
      return value.toStringAsFixed(4);
    } else if (value < 100) {
      return value.toStringAsFixed(2);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Get display string for area with unit
  static String getAreaDisplay(double value, String unit) {
    String formatted = formatArea(value);
    return '$formatted $unit';
  }
}
