import 'package:latlong2/latlong.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _openMeteoBaseUrl =
      'https://api.open-meteo.com/v1/forecast';

  // ===== OPEN-METEO API METHODS =====

  /// Fetch current temperature from Open-Meteo API for a single location
  Future<double?> fetchTemperatureFromOpenMeteo(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_openMeteoBaseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m&timezone=auto',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['current']['temperature_2m'].toDouble();
      } else {
        developer.log(
          'Failed to fetch Open-Meteo data: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      developer.log('Error fetching Open-Meteo data: $e');
      return null;
    }
  }

  /// Fetch temperature data for multiple locations using Open-Meteo API
  Future<Map<LatLng, double>> fetchTemperaturesForLocations(
    List<LatLng> locations,
  ) async {
    Map<LatLng, double> temperatureData = {};

    for (final location in locations) {
      final temperature = await fetchTemperatureFromOpenMeteo(
        location.latitude,
        location.longitude,
      );
      if (temperature != null) {
        temperatureData[location] = temperature;
      }

      // Small delay to respect API rate limits
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return temperatureData;
  }

  /// Convert temperature to intensity value (0.0 to 1.0) for heatmap
  double temperatureToIntensity(double temperature) {
    // Temperature range from -20°C to 40°C
    const double minTemp = -20.0;
    const double maxTemp = 40.0;

    double normalized = (temperature - minTemp) / (maxTemp - minTemp);
    return normalized.clamp(0.0, 1.0);
  }

  /// Get intensity values for multiple temperature data points
  List<double> getIntensitiesFromTemperatures(
    Map<LatLng, double> temperatureData,
  ) {
    return temperatureData.values
        .map((temp) => temperatureToIntensity(temp))
        .toList();
  }
}
