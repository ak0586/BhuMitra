import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/area_calculator.dart';
import '../../core/location_helper.dart';
import '../../core/preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/ad_manager.dart';

class BoundaryMarkingScreen extends ConsumerStatefulWidget {
  const BoundaryMarkingScreen({super.key});

  @override
  ConsumerState<BoundaryMarkingScreen> createState() =>
      _BoundaryMarkingScreenState();
}

class _BoundaryMarkingScreenState extends ConsumerState<BoundaryMarkingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GlobalKey _mapKey = GlobalKey();

  StreamSubscription<Position>? _userLocationSubscription;
  LatLng? _userLocation;
  bool _isZooming = false; // Prevent rapid zoom changes
  int? _draggingIndex; // Track which point is being dragged

  // Zoom constraints
  static const double _minZoom = 3.0;
  static const double _maxZoom = 25.0;

  // Selected unit for real-time display
  String _selectedUnit = 'Sq Feet';
  final List<String> _availableUnits = [
    'Sq Feet',
    'Sq Meter',
    'Sq Yard',
    'Sq Kilometer',
    'Acre',
    'Hectare',
  ];

  // Map tile URLs for different types
  final Map<String, String> _mapTileUrls = {
    'Normal': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'Satellite':
        'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', // Changed to Hybrid (y) for labels
  };

  LatLng? _initialCenter;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    AdManager().loadInterstitialAd();
  }

  Future<void> _initializeLocation() async {
    // Default fallback: Sector 10, Gurgaon
    var startLocation = const LatLng(28.4595, 77.0266);
    bool locationFound = false;

    // 1. Try to load from cache first for immediate display
    await ref.read(cachedLocationProvider.notifier).loadState();
    final cachedLoc = ref.read(cachedLocationProvider);
    if (cachedLoc != null) {
      startLocation = LatLng(cachedLoc.lat, cachedLoc.lng);
      locationFound = true;
    }

    if (mounted) {
      setState(() {
        _initialCenter = startLocation;
        _isLoadingLocation =
            false; // Show map immediately with cached or fallback
      });
    }

    // 2. Fetch fresh location in background
    try {
      final status = await LocationHelper.requestLocationPermission();
      if (status == LocationPermissionStatus.granted) {
        final position = await LocationHelper.getCurrentPosition();
        if (position != null) {
          final newLoc = LatLng(position.latitude, position.longitude);

          // Move map to actual location if it differs significantly or if we were using fallback
          if (!locationFound ||
              (cachedLoc != null &&
                  ((cachedLoc.lat - newLoc.latitude).abs() > 0.0001 ||
                      (cachedLoc.lng - newLoc.longitude).abs() > 0.0001))) {
            if (mounted) {
              _animatedMapMove(newLoc, 17.0);
            }
          }

          // Update cache
          ref
              .read(cachedLocationProvider.notifier)
              .setLocation(position.latitude, position.longitude);
        }
        // Start tracking user location for blue dot
        _startUserLocationTracking();
      }
    } catch (e) {
      debugPrint('Error getting fresh location: $e');
    }
  }

  void _startUserLocationTracking() {
    _userLocationSubscription = LocationHelper.getPositionStream().listen((
      position,
    ) {
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  void _handleMapTap(LatLng position) {
    // Pin mode only - add point on tap
    ref
        .read(boundaryPointsProvider.notifier)
        .addPoint(position.latitude, position.longitude);
  }

  void _calculateArea() {
    try {
      final points = ref.read(boundaryPointsProvider.notifier).toLatLngList();

      if (points.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need at least 3 points to calculate area'),
          ),
        );
        return;
      }

      // Show interstitial ad before calculating
      AdManager().showInterstitialAd(
        onAdDismissed: () {
          _performCalculation(points);
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _performCalculation(List<LatLng> points) {
    if (!mounted) return;
    try {
      // Calculate area using turf
      final areaInSqM = AreaCalculator.calculateAreaInSquareMeters(points);

      if (areaInSqM == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error calculating area. Please try again.'),
          ),
        );
        return;
      }

      // Create area result
      final coordinates = points.map((p) => [p.latitude, p.longitude]).toList();
      final areaResult = AreaResult.fromSquareMeters(areaInSqM, coordinates);

      // Save to provider
      ref.read(areaResultProvider.notifier).state = areaResult;

      // Navigate to result screen
      context.push('/result');
    } catch (e) {
      // Handle error if needed
      debugPrint('Calculation error: $e');
    }
  }

  bool _isLocating = false;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tween animations to move the map gracefully
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _recenterMap() async {
    setState(() {
      _isLocating = true;
    });

    final status = await LocationHelper.requestLocationPermission();
    if (status == LocationPermissionStatus.granted) {
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          _animatedMapMove(LatLng(position.latitude, position.longitude), 20.0);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get current location')),
          );
        }
      }
    } else {
      // Handle other statuses if needed, or let HomeScreen handle the initial request
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLocating = false;
      });
    }
  }

  void _handleZoom(bool zoomIn) async {
    if (_isZooming) return;

    setState(() {
      _isZooming = true;
    });

    try {
      final currentZoom = _mapController.camera.zoom;
      final newZoom = zoomIn ? currentZoom + 1 : currentZoom - 1;

      // Apply zoom constraints
      if (newZoom < _minZoom || newZoom > _maxZoom) {
        return;
      }

      // Animate zoom for smoother transition and better tile loading
      final controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );

      final Animation<double> animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );

      final zoomTween = Tween<double>(begin: currentZoom, end: newZoom);

      controller.addListener(() {
        _mapController.move(
          _mapController.camera.center,
          zoomTween.evaluate(animation),
        );
      });

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.dispose();
        }
      });

      await controller.forward();

      // Minimal delay for stability
      await Future.delayed(const Duration(milliseconds: 50));
    } finally {
      if (mounted) {
        setState(() {
          _isZooming = false;
        });
      }
    }
  }

  final TextEditingController _searchController = TextEditingController();

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        _animatedMapMove(LatLng(loc.latitude, loc.longitude), 16.0);
        // Clear focus
        FocusScope.of(context).unfocus();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Location not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error searching location')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _userLocationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(boundaryPointsProvider);
    final mapType = ref.watch(mapTypeProvider);
    final latLngPoints = points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Show loading while map initializes
    if (_isLoadingLocation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent map resize on keyboard
      body: Stack(
        children: [
          // Map
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter!, // Use user location
              initialZoom: 18.0,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onTap: (_, position) => _handleMapTap(position),
              // Configure interaction options for smoother pinch zoom
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                pinchZoomThreshold: 0.1, // More responsive pinches
                scrollWheelVelocity: 0.01, // Faster scroll wheel zoom
                pinchZoomWinGestures: MultiFingerGesture.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _mapTileUrls[mapType] ?? _mapTileUrls['Normal']!,
                userAgentPackageName: 'com.bhumitra.app',
                // Memory and performance optimizations
                keepBuffer: 3, // Restored to default for stability
                panBuffer: 1, // Restored to prevent blank screen at high zoom
                maxNativeZoom: 19,
                maxZoom: _maxZoom,
                minZoom: _minZoom,
                retinaMode: false, // Disabled for larger text
                // Smooth tile transitions to prevent blank screens
                tileDisplay: const TileDisplay.fadeIn(
                  duration: Duration(milliseconds: 100),
                ),
              ),

              // Polygon overlay (3+ points)
              if (latLngPoints.length > 2)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: latLngPoints,
                      color: const Color(0xFF66BB6A).withOpacity(0.4),
                      borderColor: const Color(0xFF2E7D32),
                      borderStrokeWidth: 3,
                      isFilled: true,
                    ),
                  ],
                ),

              // Polyline overlay (Exactly 2 points) - To show the single edge
              if (latLngPoints.length == 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: latLngPoints,
                      color: const Color(0xFF2E7D32),
                      strokeWidth: 3,
                    ),
                  ],
                ),

              // User Location Marker (Blue Dot)
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // Markers for points
              MarkerLayer(
                markers: points.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  final isDragging = _draggingIndex == index;

                  return Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: isDragging ? 40 : 24, // Scale up when dragging
                    height: isDragging ? 40 : 24,
                    child: GestureDetector(
                      onLongPressStart: (_) {
                        setState(() {
                          _draggingIndex = index;
                        });
                        // Haptic feedback
                        // HapticFeedback.selectionClick();
                      },
                      onLongPressMoveUpdate: (details) {
                        if (_draggingIndex == index) {
                          // Convert detailed screen position to map coordinates
                          // Note: We need a valid point from the map controller relative to the widget
                          // This requires the map controller to be ready

                          // Get locally within the map widget using the specific key
                          final RenderBox? mapBox =
                              _mapKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (mapBox == null) return;

                          final mapOffset = mapBox.localToGlobal(Offset.zero);
                          final localPosition =
                              details.globalPosition - mapOffset;

                          // Use the map controller to convert point to LatLng
                          final newPoint = _mapController.camera.pointToLatLng(
                            math.Point(localPosition.dx, localPosition.dy),
                          );

                          ref
                              .read(boundaryPointsProvider.notifier)
                              .updatePoint(
                                index,
                                newPoint.latitude,
                                newPoint.longitude,
                              );
                        }
                      },
                      onLongPressEnd: (_) {
                        setState(() {
                          _draggingIndex = null;
                        });
                      },
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
                    ),
                  );
                }).toList(),
              ),

              // Edge Distance Markers (New)
              if (latLngPoints.length > 1)
                MarkerLayer(markers: _buildEdgeDistanceMarkers(latLngPoints)),

              // Area Label at Center
              if (points.length >= 3)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _calculateCenter(latLngPoints),
                      width: 150,
                      height: 60,
                      child: _buildAreaLabel(latLngPoints),
                    ),
                  ],
                ),
            ],
          ),

          // Top Bar with Search
          _buildTopBar(context),

          // Map Type Dropdown (Top Right)
          _buildMapTypeDropdown(),

          // Unit Selector (Top Left) - Replaces Pin Mode Label
          _buildUnitSelector(),

          // Recenter Button
          Positioned(
            right: 16,
            bottom:
                195 +
                MediaQuery.of(context).padding.bottom, // Above zoom controls
            child: FloatingActionButton(
              heroTag: 'recenter',
              onPressed: _isLocating ? null : _recenterMap,
              backgroundColor: Theme.of(context).cardColor,
              child: _isLocating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      color:
                          Theme.of(context).iconTheme.color ??
                          const Color(0xFF2E7D32),
                    ),
            ),
          ),

          // Zoom In Button
          Positioned(
            right: 16,
            bottom: 140 + MediaQuery.of(context).padding.bottom,
            child: FloatingActionButton(
              heroTag: 'zoom_in',
              mini: true,
              onPressed: _isZooming ? null : () => _handleZoom(true),
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(
                Icons.add,
                color:
                    Theme.of(context).iconTheme.color ??
                    const Color(0xFF2E7D32),
              ),
            ),
          ),

          // Zoom Out Button
          Positioned(
            right: 16,
            bottom: 90 + MediaQuery.of(context).padding.bottom,
            child: FloatingActionButton(
              heroTag: 'zoom_out',
              mini: true,
              onPressed: _isZooming ? null : () => _handleZoom(false),
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(
                Icons.remove,
                color:
                    Theme.of(context).iconTheme.color ??
                    const Color(0xFF2E7D32),
              ),
            ),
          ),

          // Mode Controls
          _buildModeControls(points.length),
        ],
      ),
    );
  }

  LatLng _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double latSum = 0;
    double lngSum = 0;
    for (var p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  Widget _buildAreaLabel(List<LatLng> points) {
    final areaSqM = AreaCalculator.calculateAreaInSquareMeters(points);
    String displayedArea = '';

    switch (_selectedUnit) {
      case 'Sq Meter':
        displayedArea = '${AreaCalculator.formatArea(areaSqM)} sq m';
        break;
      case 'Sq Feet':
        displayedArea = '${AreaCalculator.formatArea(areaSqM * 10.764)} sq ft';
        break;
      case 'Sq Yard':
        displayedArea = '${AreaCalculator.formatArea(areaSqM * 1.196)} sq yd';
        break;
      case 'Acre':
        displayedArea = '${(areaSqM * 0.000247105).toStringAsFixed(4)} ac';
        break;
      case 'Hectare':
        displayedArea = '${(areaSqM * 0.0001).toStringAsFixed(4)} ha';
        break;
      case 'Sq Kilometer':
        displayedArea = '${(areaSqM * 0.000001).toStringAsFixed(6)} sq km';
        break;
      default:
        displayedArea = '${AreaCalculator.formatArea(areaSqM)} sq m';
    }

    return Center(
      child: Text(
        displayedArea,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          shadows: [
            Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
            Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
            Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Marker> _buildEdgeDistanceMarkers(List<LatLng> points) {
    if (points.length < 2) return [];

    // Hide warnings for large area units as per user request
    if (_selectedUnit == 'Acre' || _selectedUnit == 'Hectare') {
      return [];
    }

    final markers = <Marker>[];
    const distanceCalculator = Distance();

    // Loop through points to create edges
    final count = points.length;
    final edgeCount = count > 2 ? count : count - 1;

    for (int i = 0; i < edgeCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % count];

      // Calculate distance in meters
      final distMeters = distanceCalculator.as(LengthUnit.Meter, p1, p2);

      // Convert and format based on selected unit
      String distText = '';
      switch (_selectedUnit) {
        case 'Sq Meter':
          // case 'Hectare': // Hidden now
          distText = '${distMeters.toStringAsFixed(1)} m';
          break;
        case 'Sq Feet':
          // case 'Acre': // Hidden now
          final distFeet = distMeters * 3.28084;
          distText = '${distFeet.toStringAsFixed(1)} ft';
          break;
        case 'Sq Yard':
          final distYards = distMeters * 1.09361;
          distText = '${distYards.toStringAsFixed(1)} yd';
          break;
        case 'Sq Kilometer':
          final distKm = distMeters / 1000.0;
          distText = '${distKm.toStringAsFixed(3)} km';
          break;
        default:
          distText = '${distMeters.toStringAsFixed(1)} m';
      }

      // Calculate midpoint for label
      final midLat = (p1.latitude + p2.latitude) / 2;
      final midLng = (p1.longitude + p2.longitude) / 2;

      markers.add(
        Marker(
          point: LatLng(midLat, midLng),
          width: 80,
          height: 30,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 1,
                ),
              ),
              child: Text(
                distText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color:
                          Theme.of(context).iconTheme.color ??
                          const Color(0xFF2E7D32),
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchLocation,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).hintColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).hintColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeDropdown() {
    final mapType = ref.watch(mapTypeProvider);

    return Positioned(
      top: 120,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: mapType,
            dropdownColor: Theme.of(context).cardColor,
            icon: Icon(
              Icons.layers,
              color:
                  Theme.of(context).iconTheme.color ?? const Color(0xFF2E7D32),
            ),
            items: ['Normal', 'Satellite']
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value != null) {
                await ref.read(mapTypeProvider.notifier).setMapType(value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Positioned(
      top: 120,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _availableUnits.contains(_selectedUnit)
                ? _selectedUnit
                : _availableUnits[0],
            dropdownColor: Theme.of(context).cardColor,
            icon: Icon(
              Icons.arrow_drop_down,
              color:
                  Theme.of(context).iconTheme.color ?? const Color(0xFF2E7D32),
            ),
            items: _availableUnits
                .map(
                  (unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedUnit = value;
                });

                if (value == 'Acre' || value == 'Hectare') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Edge distance hidden for this unit. Switch to Sq Ft/Meter/Yard/Km to view.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  // Only pin mode controls
  Widget _buildModeControls(int pointCount) {
    return _buildPinControls(pointCount);
  }

  Widget _buildPinControls(int pointCount) {
    return Positioned(
      bottom: 25 + MediaQuery.of(context).padding.bottom,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Point Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: Text(
              '$pointCount point${pointCount != 1 ? 's' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Undo Button
          FloatingActionButton.small(
            heroTag: 'undo',
            onPressed: pointCount > 0
                ? () => ref
                      .read(boundaryPointsProvider.notifier)
                      .removeLastPoint()
                : null,
            backgroundColor: Theme.of(context).cardColor,
            child: Icon(
              Icons.undo,
              color:
                  Theme.of(context).iconTheme.color ?? const Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 12),

          // Clear Button
          FloatingActionButton.small(
            heroTag: 'clear',
            onPressed: pointCount > 0
                ? () => ref.read(boundaryPointsProvider.notifier).clearPoints()
                : null,
            backgroundColor: Theme.of(context).cardColor,
            child: const Icon(Icons.clear, color: Colors.red),
          ),

          const SizedBox(height: 12, width: 18),

          // Calculate Button
          FloatingActionButton.extended(
            heroTag: 'calculate',
            onPressed: pointCount >= 3 ? _calculateArea : null,
            backgroundColor: const Color(0xFF2E7D32),
            icon: const Icon(Icons.calculate),
            label: const Text(
              'Calculate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
