import 'package:desaster/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:weather/weather.dart';
import '../util/app_constants.dart';
import '../services/weather_service.dart';
import 'dart:developer' as developer;

class ViewLocationsScreen extends StatefulWidget {
  const ViewLocationsScreen({super.key});

  @override
  State<ViewLocationsScreen> createState() => _ViewLocationsScreenState();
}

class _ViewLocationsScreenState extends State<ViewLocationsScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _locations = [];
  double _currentZoom = 1.0;
  LatLng _currentLocation = LatLng(0, 0);
  bool _locationLoaded = false;

  // Weather and heat wave related variables
  final WeatherService _weatherService = WeatherService();
  Map<LatLng, Weather> _weatherData = {};
  bool _showHeatWaveLayer = true;
  bool _loadingWeatherData = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _fetchLocations();
  }

  Future<void> _initializeLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check location permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    try {
      LocationData locationData = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _locationLoaded = true;
      });

      // Move map to current location
      _mapController.move(_currentLocation, 1.75);
    } catch (e) {
      developer.log('Error getting location: $e');
    }
  }

  void _centerOnCurrentLocation() {
    if (_locationLoaded) {
      _mapController.move(_currentLocation, 1.75);
    } else {
      _initializeLocation();
    }
  }

  Future<void> _fetchLocations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();
      setState(() {
        _locations = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          double lat = data['lat'] ?? 0.0;
          double lng = data['lng'] ?? 0.0;
          double radius = data['radius'] ?? AppConstants.geofenceRadius;
          return {'position': LatLng(lat, lng), 'radius': radius};
        }).toList();
      });

      // Fetch weather data for all locations
      _fetchWeatherData();
    } catch (e) {
      developer.log('Error fetching locations: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_locations.isEmpty) return;

    setState(() {
      _loadingWeatherData = true;
    });

    try {
      List<LatLng> positions = _locations
          .map((location) => location['position'] as LatLng)
          .toList();

      Map<LatLng, Weather> weatherData = await _weatherService
          .getWeatherForLocations(positions);

      setState(() {
        _weatherData = weatherData;
        _loadingWeatherData = false;
      });
    } catch (e) {
      developer.log('Error fetching weather data: $e');
      setState(() {
        _loadingWeatherData = false;
      });
    }
  }

  int _getHeatWaveCount() {
    return _weatherData.values
        .where((weather) => WeatherService.isHeatWave(weather))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _locationLoaded ? _currentLocation : LatLng(0, 0),
              initialZoom: _locationLoaded ? 15.0 : 1.75,
              minZoom: 1.75,
              maxZoom: 100,
              onMapEvent: (MapEvent mapEvent) {
                if (mapEvent is MapEventMoveEnd) {
                  setState(() {
                    _currentZoom = mapEvent.camera.zoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName:
                    'net.tlserver6y.flutter_map_location_marker.example',
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(marker: DefaultLocationMarker()),
              ),
              CircleLayer(
                circles: _locations.map((location) {
                  LatLng position = location['position'] as LatLng;
                  double radius = location['radius'] as double;
                  double pixelRadius = MapUtils.metersToPixels(
                    radius,
                    _currentZoom,
                    position.latitude,
                  );
                  return CircleMarker(
                    point: position,
                    radius: pixelRadius,
                    color: Colors.red.withValues(
                      alpha: AppConstants.geofenceFillOpacity,
                    ),
                    borderColor: Colors.red.withValues(
                      alpha: AppConstants.geofenceBorderOpacity,
                    ),
                    borderStrokeWidth: AppConstants.geofenceBorderWidth,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: _locations.map((location) {
                  LatLng position = location['position'] as LatLng;
                  return Marker(
                    rotate: true,
                    point: position,
                    child: Icon(Icons.location_on, color: Colors.red, size: 30),
                  );
                }).toList(),
              ),
              // Heat Wave Layer
              if (_showHeatWaveLayer)
                CircleLayer(
                  circles: _locations
                      .where((location) {
                        LatLng position = location['position'] as LatLng;
                        Weather? weather = _weatherData[position];
                        return weather != null &&
                            WeatherService.isHeatWave(weather);
                      })
                      .map((location) {
                        LatLng position = location['position'] as LatLng;
                        double radius = location['radius'] as double;
                        Weather? weather = _weatherData[position];

                        if (weather == null) return null;

                        int intensity = WeatherService.getHeatWaveIntensity(
                          weather,
                        );
                        int colorValue = WeatherService.getHeatWaveColor(
                          intensity,
                        );

                        double pixelRadius = MapUtils.metersToPixels(
                          radius,
                          _currentZoom,
                          position.latitude,
                        );

                        return CircleMarker(
                          point: position,
                          radius: pixelRadius,
                          color: Color(colorValue),
                          borderColor: Color(
                            colorValue & 0xFF000000 | 0xFF000000,
                          ), // Fully opaque border
                          borderStrokeWidth: 2.0,
                        );
                      })
                      .where((marker) => marker != null)
                      .cast<CircleMarker>()
                      .toList(),
                ),
              // Heat Wave Warning Icons
              if (_showHeatWaveLayer)
                MarkerLayer(
                  markers: _locations
                      .where((location) {
                        LatLng position = location['position'] as LatLng;
                        Weather? weather = _weatherData[position];
                        return weather != null &&
                            WeatherService.isHeatWave(weather);
                      })
                      .map((location) {
                        LatLng position = location['position'] as LatLng;
                        Weather? weather = _weatherData[position];

                        if (weather == null) return null;

                        int intensity = WeatherService.getHeatWaveIntensity(
                          weather,
                        );
                        IconData icon = intensity >= 3
                            ? Icons.warning
                            : intensity >= 2
                            ? Icons.thermostat
                            : Icons.wb_sunny;

                        return Marker(
                          rotate: false,
                          point: position,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: intensity >= 3
                                  ? Colors.red[800]
                                  : intensity >= 2
                                  ? Colors.orange[800]
                                  : Colors.yellow[800],
                              size: 20,
                            ),
                          ),
                        );
                      })
                      .where((marker) => marker != null)
                      .cast<Marker>()
                      .toList(),
                ),
            ],
          ),
          // Heat Wave Layer Toggle and Status
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                // Heat Wave Toggle Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showHeatWaveLayer
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _showHeatWaveLayer
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showHeatWaveLayer = !_showHeatWaveLayer;
                      });
                    },
                    tooltip: _showHeatWaveLayer
                        ? 'Hide Heat Wave Layer'
                        : 'Show Heat Wave Layer',
                  ),
                ),
                const SizedBox(height: 8),
                // Weather Data Status Indicator
                if (_loadingWeatherData)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(height: 4),
                        Text('Weather', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                // Heat Wave Count
                if (_weatherData.isNotEmpty && _showHeatWaveLayer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thermostat,
                          color: Colors.red[700],
                          size: 16,
                        ),
                        Text(
                          '${_getHeatWaveCount()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        Text(
                          'Heat\nWaves',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 8, color: Colors.red[600]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: _centerOnCurrentLocation,
        backgroundColor: AppTheme.primaryColor,
        tooltip: 'Center on current location',
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
