// App constants
import 'dart:math';

class AppConstants {
  // Geofence radius in meters (1km = 1000 meters)
  static const double geofenceRadius = 100000.0;

  // Geofence colors
  static const double geofenceFillOpacity = 0.2;
  static const double geofenceBorderOpacity = 0.5;
  static const double geofenceBorderWidth = 2.0;
}

// Utility functions for map calculations
class MapUtils {
  // Convert meters to pixels based on zoom level and latitude
  static double metersToPixels(double meters, double zoom, double latitude) {
    // Earth's circumference at equator in meters
    const double earthCircumference = 40075016.686;
    // Number of pixels per tile at zoom level 0
    const double pixelsPerTile = 256.0;

    // Calculate meters per pixel at this zoom level and latitude
    double metersPerPixel =
        earthCircumference *
        cos(latitude * pi / 180) /
        (pixelsPerTile * pow(2, zoom));

    // Return pixel radius for the given meter radius
    return meters / metersPerPixel;
  }
}
