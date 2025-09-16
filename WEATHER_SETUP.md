# Weather Heat Wave Layer Setup

This feature adds a heat wave visualization layer to your disaster management app using the OpenWeatherMap API.

## Setup Instructions

### 1. Get OpenWeatherMap API Key

1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Navigate to "API Keys" in your account dashboard
4. Copy your API key

### 2. Configure API Key

1. Open `lib/services/weather_service.dart`
2. Replace `YOUR_API_KEY_HERE` with your actual API key:

```dart
static const String _apiKey = 'your_actual_api_key_here';
```

### 3. Heat Wave Detection

The system automatically detects heat waves based on temperature thresholds:

- **No Heat Wave**: < 35°C (95°F)
- **Moderate Heat Wave**: 35°C - 40°C (95°F - 104°F) - Orange overlay
- **Severe Heat Wave**: 40°C - 45°C (104°F - 113°F) - Red-Orange overlay
- **Extreme Heat Wave**: > 45°C (113°F) - Crimson overlay

### 4. Features

- **Heat Wave Visualization**: Colored circular overlays on affected locations
- **Warning Icons**: Different icons based on heat wave intensity
- **Layer Toggle**: Show/hide heat wave layer using the eye icon
- **Heat Wave Counter**: Real-time count of locations experiencing heat waves
- **Loading Indicator**: Shows when weather data is being fetched

### 5. Usage

- The app automatically fetches weather data for all marked locations
- Heat wave overlays appear on locations with temperatures above 35°C
- Use the toggle button (eye icon) to show/hide the heat wave layer
- The red counter shows the number of active heat wave locations

### 6. API Rate Limiting

The app includes a 200ms delay between API calls to respect OpenWeatherMap's rate limits. For production use, consider:

- Caching weather data
- Reducing update frequency
- Using a paid API plan for higher limits

### 7. Customization

You can modify heat wave thresholds in `weather_service.dart`:

```dart
static bool isHeatWave(Weather weather) {
  if (weather.temperature == null) return false;
  return weather.temperature!.celsius! > 35.0; // Change this threshold
}
```
