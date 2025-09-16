import 'package:weather/weather.dart';
import 'package:latlong2/latlong.dart';
import 'dart:developer' as developer;

class WeatherService {
  static const String _apiKey = 'API_KEY_HERE';
  late final WeatherFactory _wf;

  WeatherService() {
    _wf = WeatherFactory(_apiKey);
  }

  /// Fetch current weather for a specific location
  Future<Weather?> getCurrentWeather(LatLng location) async {
    try {
      Weather weather = await _wf.currentWeatherByLocation(
        location.latitude,
        location.longitude,
      );
      return weather;
    } catch (e) {
      developer.log(
        'Error fetching weather for ${location.latitude}, ${location.longitude}: $e',
      );
      return null;
    }
  }

  /// Check if the weather conditions indicate a heat wave
  /// Heat wave criteria: Temperature > 35°C (95°F) for this example
  static bool isHeatWave(Weather weather) {
    if (weather.temperature == null) return false;
    return weather.temperature!.celsius! > 35.0;
  }

  /// Get heat wave intensity level
  /// Returns 0 (no heat wave), 1 (moderate), 2 (severe), 3 (extreme)
  static int getHeatWaveIntensity(Weather weather) {
    if (weather.temperature == null) return 0;

    double tempCelsius = weather.temperature!.celsius!;

    if (tempCelsius < 35.0) return 0; // No heat wave
    if (tempCelsius < 40.0) return 1; // Moderate heat wave
    if (tempCelsius < 45.0) return 2; // Severe heat wave
    return 3; // Extreme heat wave
  }

  /// Get color for heat wave visualization based on intensity
  static int getHeatWaveColor(int intensity) {
    switch (intensity) {
      case 0:
        return 0x00000000; // Transparent (no heat wave)
      case 1:
        return 0x80FFA500; // Orange with 50% opacity
      case 2:
        return 0x80FF4500; // Red-Orange with 50% opacity
      case 3:
        return 0x80DC143C; // Crimson with 50% opacity
      default:
        return 0x00000000;
    }
  }

  /// Fetch weather data for multiple locations
  Future<Map<LatLng, Weather>> getWeatherForLocations(
    List<LatLng> locations,
  ) async {
    Map<LatLng, Weather> weatherData = {};

    for (LatLng location in locations) {
      Weather? weather = await getCurrentWeather(location);
      if (weather != null) {
        weatherData[location] = weather;
      }
      // Add small delay to avoid API rate limiting
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return weatherData;
  }
}

/// Weather data model for UI display
class LocationWeatherData {
  final LatLng position;
  final double radius;
  final Weather? weather;
  final bool isHeatWave;
  final int heatWaveIntensity;

  LocationWeatherData({
    required this.position,
    required this.radius,
    this.weather,
    this.isHeatWave = false,
    this.heatWaveIntensity = 0,
  });

  factory LocationWeatherData.fromLocationData(
    Map<String, dynamic> locationData,
    Weather? weather,
  ) {
    LatLng position = locationData['position'] as LatLng;
    double radius = locationData['radius'] as double;

    bool isHeatWave = false;
    int intensity = 0;

    if (weather != null) {
      isHeatWave = WeatherService.isHeatWave(weather);
      intensity = WeatherService.getHeatWaveIntensity(weather);
    }

    return LocationWeatherData(
      position: position,
      radius: radius,
      weather: weather,
      isHeatWave: isHeatWave,
      heatWaveIntensity: intensity,
    );
  }
}
