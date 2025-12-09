import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedPlot {
  final String id;
  final String name;
  final String area;
  final String date;
  final String location;
  final List<List<double>> coordinates;
  final String? customUnitName;
  final double? customUnitValue;
  final String? customUnitBase;

  SavedPlot({
    required this.id,
    required this.name,
    required this.area,
    required this.date,
    required this.location,
    required this.coordinates,
    this.customUnitName,
    this.customUnitValue,
    this.customUnitBase,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'date': date,
      'location': location,
      'coordinates': coordinates,
      'customUnitName': customUnitName,
      'customUnitValue': customUnitValue,
      'customUnitBase': customUnitBase,
    };
  }

  factory SavedPlot.fromJson(Map<String, dynamic> json) {
    return SavedPlot(
      id: json['id'],
      name: json['name'],
      area: json['area'],
      date: json['date'],
      location: json['location'],
      coordinates: (json['coordinates'] as List)
          .map((e) => (e as List).map((c) => c as double).toList())
          .toList(),
      customUnitName: json['customUnitName'] as String?,
      customUnitValue: json['customUnitValue'] as double?,
      customUnitBase: json['customUnitBase'] as String?,
    );
  }
}

class SavedPlotsNotifier extends StateNotifier<List<SavedPlot>> {
  SavedPlotsNotifier() : super([]);

  Future<void> loadPlots() async {
    final prefs = await SharedPreferences.getInstance();
    final plotsJson = prefs.getStringList('saved_plots') ?? [];
    state = plotsJson.map((e) => SavedPlot.fromJson(jsonDecode(e))).toList();
    print('Loaded ${state.length} saved plots');
  }

  Future<void> addPlot(SavedPlot plot) async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure we have the latest data from disk
    final plotsJson = prefs.getStringList('saved_plots') ?? [];
    final currentPlots = plotsJson
        .map((e) => SavedPlot.fromJson(jsonDecode(e)))
        .toList();

    final newState = [plot, ...currentPlots];
    state = newState;

    final newPlotsJson = newState.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('saved_plots', newPlotsJson);
    print('Added plot. Total saved: ${newState.length}');
  }

  Future<void> deletePlot(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final newState = state.where((p) => p.id != id).toList();
    state = newState;
    final plotsJson = newState.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('saved_plots', plotsJson);
  }
}

final savedPlotsProvider =
    StateNotifierProvider<SavedPlotsNotifier, List<SavedPlot>>((ref) {
      return SavedPlotsNotifier();
    });
