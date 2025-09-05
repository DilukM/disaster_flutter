import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<void> addLocation(LatLng position, {double? radius}) async {
    try {
      await FirebaseFirestore.instance.collection('locations').add({
        'lat': position.latitude,
        'lng': position.longitude,
        'radius': radius ?? 100000.0, // Default to 100km if not specified
        'timestamp': FieldValue.serverTimestamp(),
      });
      print(
        'Location added successfully: ${position.latitude}, ${position.longitude}, radius: ${radius ?? 100000.0}',
      );
    } catch (e) {
      print('Error adding location: $e');
      throw e;
    }
  }
}
