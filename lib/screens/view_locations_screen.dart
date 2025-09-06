import 'package:desaster/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import '../util/app_constants.dart';
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
    } catch (e) {
      developer.log('Error fetching locations: $e');
    }
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
            ],
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
