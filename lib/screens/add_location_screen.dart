import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:toastification/toastification.dart';
import 'package:location/location.dart';
import '../services/location_service.dart';
import '../util/app_constants.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  double _currentZoom = 1.0;
  final Location _location = Location();
  LatLng? _currentLocation;
  double _customRadius = AppConstants.geofenceRadius;
  final TextEditingController _radiusController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _radiusController.text = _customRadius.toStringAsFixed(0);
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 1.75);
    } else {
      await _initializeLocation();
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 1.75);
      }
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
              initialCenter: _currentLocation ?? LatLng(0, 0),
              initialZoom: _currentLocation != null ? 2.0 : 1.75,
              minZoom: 1.75,
              maxZoom: 100,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
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
              if (_selectedLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation!,
                      radius: MapUtils.metersToPixels(
                        _customRadius,
                        _currentZoom,
                        _selectedLocation!.latitude,
                      ),
                      color: Colors.blue.withValues(
                        alpha: AppConstants.geofenceFillOpacity,
                      ),
                      borderColor: Colors.blue.withValues(
                        alpha: AppConstants.geofenceBorderOpacity,
                      ),
                      borderStrokeWidth: AppConstants.geofenceBorderWidth,
                    ),
                  ],
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  rotate: true,
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(50, 50),
                      maximumSize: Size(80, 80),
                      padding: EdgeInsets.all(8),
                      iconSize: 25,
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _centerOnCurrentLocation,
                    child: Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
                if (_selectedLocation != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _radiusController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Geofence Radius (meters)',
                              labelStyle: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              hintText: 'Enter radius in meters',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            style: TextStyle(color: Colors.black, fontSize: 14),
                            onChanged: (value) {
                              double? newRadius = double.tryParse(value);
                              if (newRadius != null && newRadius > 0) {
                                setState(() {
                                  _customRadius = newRadius;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: _selectedLocation != null ? _saveLocation : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (_selectedLocation != null
                          ? Colors.blue
                          : Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_selectedLocation != null
                            ? Colors.blue
                            : Colors.grey),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          _selectedLocation != null
                              ? 'Save Location'
                              : 'Tap on map to select location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedLocation != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    try {
      await LocationService.addLocation(
        _selectedLocation!,
        radius: _customRadius,
      );
      
      if (!mounted) return;
      
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flat,
        title: const Text('Success'),
        description: const Text('Location saved successfully!'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
      );
      setState(() {
        _selectedLocation = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        title: const Text('Error'),
        description: Text('Error saving location: $e'),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
        closeOnClick: true,
        pauseOnHover: true,
      );
    }
  }
}
