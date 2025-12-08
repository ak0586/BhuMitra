import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// Boundary Points State
class BoundaryPoint {
  final double latitude;
  final double longitude;
  final int id;

  BoundaryPoint({
    required this.latitude,
    required this.longitude,
    required this.id,
  });
}

// Provider for boundary points
final boundaryPointsProvider =
    StateNotifierProvider<BoundaryPointsNotifier, List<BoundaryPoint>>((ref) {
      return BoundaryPointsNotifier();
    });

class BoundaryPointsNotifier extends StateNotifier<List<BoundaryPoint>> {
  BoundaryPointsNotifier() : super([]);

  void addPoint(double lat, double lng) {
    state = [
      ...state,
      BoundaryPoint(
        latitude: lat,
        longitude: lng,
        id: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
  }

  void removeLastPoint() {
    if (state.isNotEmpty) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void clearPoints() {
    state = [];
  }

  List<LatLng> toLatLngList() {
    return state.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }
}

// Area Result State
class AreaResult {
  final double squareFeet;
  final double squareMeters;
  final double squareYards;
  final double acre;
  final double hectare;
  final List<List<double>> coordinates;

  AreaResult({
    required this.squareFeet,
    required this.squareMeters,
    required this.squareYards,
    required this.acre,
    required this.hectare,
    required this.coordinates,
  });

  AreaResult.fromSquareMeters(double sqm, this.coordinates)
    : squareMeters = sqm,
      squareFeet = sqm * 10.764,
      squareYards = sqm * 1.196,
      acre = sqm * 0.000247105,
      hectare = sqm * 0.0001;
}

final areaResultProvider = StateProvider<AreaResult?>((ref) => null);

// Custom Local Unit State
class CustomLocalUnit {
  final String unitName;
  final double conversionFactor;
  final String baseUnit; // sqft, sqm, sqyd, acre, hectare

  CustomLocalUnit({
    required this.unitName,
    required this.conversionFactor,
    required this.baseUnit,
  });

  double calculateArea(AreaResult areaResult) {
    double baseValue;
    switch (baseUnit) {
      case 'sqft':
        baseValue = areaResult.squareFeet;
        break;
      case 'sqm':
        baseValue = areaResult.squareMeters;
        break;
      case 'sqyd':
        baseValue = areaResult.squareYards;
        break;
      case 'acre':
        baseValue = areaResult.acre;
        break;
      case 'hectare':
        baseValue = areaResult.hectare;
        break;
      default:
        baseValue = areaResult.squareFeet;
    }
    return baseValue / conversionFactor;
  }
}

final customLocalUnitProvider = StateProvider<CustomLocalUnit?>((ref) => null);
