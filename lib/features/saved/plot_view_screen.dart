import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/saved_plots_provider.dart';

class PlotViewScreen extends StatefulWidget {
  final SavedPlot plot;

  const PlotViewScreen({super.key, required this.plot});

  @override
  State<PlotViewScreen> createState() => _PlotViewScreenState();
}

class _PlotViewScreenState extends State<PlotViewScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Center map on the plot after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && widget.plot.coordinates.isNotEmpty) {
        _centerMapOnPlot();
      }
    });
  }

  void _centerMapOnPlot() {
    if (widget.plot.coordinates.isEmpty) return;

    // Calculate center point
    double sumLat = 0;
    double sumLng = 0;
    for (var coord in widget.plot.coordinates) {
      sumLat += coord[0];
      sumLng += coord[1];
    }
    final centerLat = sumLat / widget.plot.coordinates.length;
    final centerLng = sumLng / widget.plot.coordinates.length;

    _mapController.move(LatLng(centerLat, centerLng), 16.0);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latLngPoints = widget.plot.coordinates
        .map((coord) => LatLng(coord[0], coord[1]))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: latLngPoints.isNotEmpty
                  ? latLngPoints[0]
                  : const LatLng(26.8467, 80.9462),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bhumitra.app',
                retinaMode: false,
              ),

              // Polygon overlay
              if (latLngPoints.length > 2)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: latLngPoints,
                      color: const Color(0xFF66BB6A).withOpacity(0.3),
                      borderColor: const Color(0xFF2E7D32),
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),

              // Markers for points
              MarkerLayer(
                markers: latLngPoints.map((point) {
                  return Marker(
                    point: point,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2E7D32),
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.plot.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Plot Details Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.landscape,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.plot.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.square_foot,
                      'Area',
                      widget.plot.area,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      widget.plot.location,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date',
                      widget.plot.date,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recenter Button
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              heroTag: 'recenter',
              onPressed: _centerMapOnPlot,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
