import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/weather_service.dart';

class LocationSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  LocationSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});
  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  List<WeightedLatLng> _heatmapPoints = [];
  List<WeightedLatLng> _filteredPoints = [];
  List<double> _intensities = []; // Store intensity values separately
  List<double> _filteredIntensities = []; // Store filtered intensity values
  bool _isLoading = true;
  String _loadingMessage = 'Loading heatmap data...';
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  List<LocationSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  late final WeatherService _weatherService;

  @override
  void initState() {
    super.initState();
    _weatherService = WeatherService();
    _loadHeatmapData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHeatmapData() async {
    try {
      setState(() => _loadingMessage = 'Loading location data...');
      // First load the static data to get coordinates
      final String jsonString = await rootBundle.loadString(
        'assets/heatmap_data.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);
      print('Loaded ${jsonData.length} locations from JSON');

      // Extract coordinates from the static data
      final List<LatLng> locations = jsonData.map((item) {
        return LatLng(item['lat'], item['lng']);
      }).toList();

      // Sample locations to reduce API calls (every 10th location for performance)
      const int sampleRate = 10;
      final List<LatLng> sampledLocations = [];
      final List<int> sampledIndices = [];

      for (int i = 0; i < locations.length; i += sampleRate) {
        sampledLocations.add(locations[i]);
        sampledIndices.add(i);
      }

      print('Sampling ${sampledLocations.length} locations out of ${locations.length} for API calls');

      setState(() => _loadingMessage = 'Fetching weather data...');
      // Fetch real temperature data from Open-Meteo API with timeout
      final Map<LatLng, double> temperatureData =
          await _weatherService.fetchTemperaturesForLocations(sampledLocations)
              .timeout(const Duration(seconds: 30), onTimeout: () {
            print('Weather API call timed out after 30 seconds');
            return {}; // Return empty map on timeout
          });

      print('Received temperature data for ${temperatureData.length} locations');

      setState(() => _loadingMessage = 'Processing data...');
      // Create heatmap points with real temperature data
      List<WeightedLatLng> points = [];
      List<double> intensities = [];

      for (int i = 0; i < locations.length; i++) {
        final location = locations[i];
        final temperature = temperatureData[location];

        if (temperature != null) {
          // Use real temperature to calculate intensity
          final intensity = _weatherService.temperatureToIntensity(temperature);
          points.add(WeightedLatLng(location, intensity));
          intensities.add(intensity);
        } else {
          // Fallback to static data if API fails for this location
          final staticIntensity = (jsonData[i]['intensity'] as num).toDouble();
          points.add(WeightedLatLng(location, staticIntensity));
          intensities.add(staticIntensity);
        }
      }

      print('Created ${points.length} heatmap points');
      setState(() {
        _heatmapPoints = points;
        _intensities = intensities;
        _filteredPoints = _heatmapPoints;
        _filteredIntensities = _intensities;
        _isLoading = false;
      });
      print('Heatmap data loading completed successfully');
    } catch (e) {
      print('Error loading heatmap data: $e');
      // Load fallback data if everything fails
      await _loadFallbackData();
    }
  }

  Future<void> _loadFallbackData() async {
    try {
      print('Loading fallback data...');
      final String jsonString = await rootBundle.loadString(
        'assets/heatmap_data.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        _heatmapPoints = jsonData.map((item) {
          return WeightedLatLng(
            LatLng(item['lat'], item['lng']),
            item['intensity'],
          );
        }).toList();
        _intensities = jsonData.map((item) => (item['intensity'] as num).toDouble()).toList();
        _filteredPoints = _heatmapPoints;
        _filteredIntensities = _intensities;
        _isLoading = false;
        _loadingMessage = 'Loaded static data';
      });
      print('Fallback data loaded successfully');
    } catch (e) {
      print('Error loading fallback data: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Failed to load data';
      });
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredPoints = _heatmapPoints;
        _filteredIntensities = _intensities;
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        locations.first.latitude,
        locations.first.longitude,
      );

      setState(() {
        _suggestions = locations.take(5).map((location) {
          String displayName = query; // Default to the search query
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            displayName =
                [
                      placemark.locality,
                      placemark.administrativeArea,
                      placemark.country,
                    ]
                    .where((element) => element != null && element.isNotEmpty)
                    .join(', ');
            if (displayName.isEmpty) {
              displayName = query;
            }
          }
          return LocationSuggestion(
            displayName: displayName,
            latitude: location.latitude,
            longitude: location.longitude,
          );
        }).toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _onSuggestionSelected(LocationSuggestion suggestion) {
    setState(() {
      _searchController.text = suggestion.displayName;
      _showSuggestions = false;
      _suggestions = [];
    });

    // Animate map to the selected location
    _mapController.move(
      LatLng(suggestion.latitude, suggestion.longitude),
      12.0,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredPoints = _heatmapPoints;
      _filteredIntensities = _intensities;
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < 18.0) {
      // Maximum zoom level for most tile providers
      _mapController.move(_mapController.camera.center, currentZoom + 1.0);
    }
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > 1.0) {
      // Minimum zoom level
      _mapController.move(_mapController.camera.center, currentZoom - 1.0);
    }
  }

  // Calculate radius based on intensity and zoom level
  double _calculateRadius(double intensity, double zoomLevel) {
    // Base radius scales with zoom level
    double baseRadius = 20.0 + (zoomLevel * 5.0);

    // Intensity multiplier (higher intensity = larger radius)
    double intensityMultiplier = 0.5 + (intensity * 1.5);

    // Ensure reasonable bounds
    return (baseRadius * intensityMultiplier).clamp(15.0, 200.0);
  }

  // Calculate blur factor based on intensity and data density
  double _calculateBlurFactor(double intensity, int nearbyPoints) {
    // Base blur factor
    double baseBlur = 10.0;

    // Intensity affects blur (higher intensity = more spread)
    double intensityBlur = intensity * 15.0;

    // Nearby points affect blur (more points = more blending)
    double densityBlur = nearbyPoints * 2.0;

    // Ensure reasonable bounds
    return (baseBlur + intensityBlur + densityBlur).clamp(5.0, 50.0);
  }





  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _loadingMessage,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate average intensity for overall heatmap settings
    double averageIntensity = _filteredIntensities.isNotEmpty
        ? _filteredIntensities.reduce((a, b) => a + b) / _filteredIntensities.length
        : 0.5;

    // Get current zoom level for radius calculation (with safety check)
    double currentZoom = 10.0; // Default zoom level
    try {
      // Check if map controller is properly initialized
      currentZoom = _mapController.camera.zoom;
    } catch (e) {
      // Map controller not ready yet, use default zoom
      print('Map controller not ready, using default zoom: $e');
    }

    // Calculate radius and blur factor based on data
    final radius = _calculateRadius(averageIntensity, currentZoom);

    // For blur factor, calculate based on data density
    int totalPoints = _filteredPoints.length;
    double dataDensity = totalPoints > 0 ? totalPoints / 1000.0 : 0.1; // Normalize density
    final blurFactor = _calculateBlurFactor(averageIntensity, (dataDensity * 10).round());

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(0, 0), // Center on equator for global view
              initialZoom: 2.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName:
                    'net.tlserver6y.flutter_map_location_marker.example',
              ),
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(
                  data: _filteredPoints,
                ),
                heatMapOptions: HeatMapOptions(
                  radius: radius,
                  blurFactor: blurFactor,
                  layerOpacity: 1,
                  gradient: {
                    0.0: Colors.blue,
                    0.2: Colors.green,
                    0.4: Colors.yellow,
                    0.7: Colors.orange,
                    1.0: Colors.red,
                  },
                  minOpacity: 0.2,
                ),
              ),
            ],
          ),
          // Floating Search Bar
          Positioned(
            top: 50.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search locations...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                // Suggestions Dropdown
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4.0),
                    constraints: BoxConstraints(maxHeight: 200.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            suggestion.displayName,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          leading: Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 20.0,
                          ),
                          onTap: () => _onSuggestionSelected(suggestion),
                          shape: RoundedRectangleBorder(
                            borderRadius: index == 0
                                ? BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                  )
                                : index == _suggestions.length - 1
                                ? BorderRadius.only(
                                    bottomLeft: Radius.circular(12.0),
                                    bottomRight: Radius.circular(12.0),
                                  )
                                : BorderRadius.zero,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Zoom Controls
          Positioned(
            right: 16.0,
            bottom: 100.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.black87),
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                        iconSize: 24.0,
                        padding: EdgeInsets.all(8.0),
                        constraints: BoxConstraints(
                          minWidth: 40.0,
                          minHeight: 40.0,
                        ),
                      ),
                      Divider(
                        height: 1.0,
                        thickness: 1.0,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.black87),
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                        iconSize: 24.0,
                        padding: EdgeInsets.all(8.0),
                        constraints: BoxConstraints(
                          minWidth: 40.0,
                          minHeight: 40.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
