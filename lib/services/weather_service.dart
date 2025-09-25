import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';

class WeatherService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'https://api.open-meteo.com/v1';

  // Note: Weather data accuracy may vary between different weather services
  // Open-Meteo provides free weather data that may differ from commercial services
  // like AccuWeather, Weather.com, etc. This is normal and expected.

  Map<String, WeatherData> _weatherCache = {};
  Map<String, List<WeatherData>> _forecastCache = {};

  // Get current weather for a location
  Future<WeatherData?> getCurrentWeather(
      double latitude, double longitude) async {
    final String cacheKey = '${latitude}_${longitude}';

    // Check cache first (15-minute cache)
    if (_weatherCache.containsKey(cacheKey)) {
      final cached = _weatherCache[cacheKey]!;
      if (DateTime.now().difference(cached.timestamp).inMinutes < 15) {
        return cached;
      }
    }

    try {
      final url = '$_baseUrl/forecast?'
          'latitude=$latitude&'
          'longitude=$longitude&'
          'current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_direction_10m,weather_code,cloud_cover&'
          'timezone=Asia/Manila&'
          'timezone_abbreviation=PST';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];

        WeatherData weatherData = WeatherData(
          temperature: (current['temperature_2m'] ?? 0).toDouble(),
          humidity: (current['relative_humidity_2m'] ?? 0).toDouble(),
          rainfall: (current['precipitation'] ?? 0).toDouble(),
          windSpeed: (current['wind_speed_10m'] ?? 0).toDouble(),
          windDirection: (current['wind_direction_10m'] ?? 0).toDouble(),
          weatherDescription: _getWeatherDescription(current['weather_code']),
          weatherCode: current['weather_code'] ?? 0,
          timestamp: DateTime.now(),
          isAlert: _checkIfAlert(current),
        );

        // Cache the data
        _weatherCache[cacheKey] = weatherData;

        // Store in Firestore for persistence
        await _cacheWeatherInFirestore(latitude, longitude, weatherData);

        // Check for severe weather alerts
        if (weatherData.isSevereWeather) {
          await _sendWeatherAlert(latitude, longitude, weatherData);
        }

        notifyListeners();
        return weatherData;
      }
    } catch (e) {
      print('Error fetching weather data: ${e.toString()}');
      // Try to get cached data from Firestore
      return await _getCachedWeatherFromFirestore(latitude, longitude);
    }

    return null;
  }

  // Get 7-day weather forecast
  Future<List<WeatherData>> getWeatherForecast(
      double latitude, double longitude) async {
    final String cacheKey = '${latitude}_${longitude}';

    try {
      final url = '$_baseUrl/forecast?'
          'latitude=$latitude&'
          'longitude=$longitude&'
          'daily=temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max,weather_code,precipitation_probability_max&'
          'timezone=Asia/Manila&'
          'timezone_abbreviation=PST&'
          'forecast_days=7';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];

        List<WeatherData> forecast = [];

        for (int i = 0; i < 7; i++) {
          forecast.add(WeatherData(
            temperature: (daily['temperature_2m_max'][i] ?? 0).toDouble(),
            humidity:
                70.0, // Open-Meteo doesn't provide daily humidity, using average
            rainfall: (daily['precipitation_sum'][i] ?? 0).toDouble(),
            windSpeed: (daily['wind_speed_10m_max'][i] ?? 0).toDouble(),
            windDirection: 0.0,
            weatherDescription:
                _getWeatherDescription(daily['weather_code'][i]),
            weatherCode: daily['weather_code'][i] ?? 0,
            timestamp: DateTime.now().add(Duration(days: i)),
          ));
        }

        _forecastCache[cacheKey] = forecast;
        notifyListeners();
        return forecast;
      }
    } catch (e) {
      print('Error fetching forecast data: ${e.toString()}');
    }

    return [];
  }

  // Cache weather data in Firestore
  Future<void> _cacheWeatherInFirestore(
      double lat, double lon, WeatherData data) async {
    try {
      await _firestore.collection('weather_cache').doc('${lat}_${lon}').set({
        'latitude': lat,
        'longitude': lon,
        'weather_data': data.toMap(),
        'cached_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error caching weather data: ${e.toString()}');
    }
  }

  // Get cached weather from Firestore
  Future<WeatherData?> _getCachedWeatherFromFirestore(
      double lat, double lon) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('weather_cache')
          .doc('${lat}_${lon}')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return WeatherData.fromMap(data['weather_data']);
      }
    } catch (e) {
      print('Error getting cached weather: ${e.toString()}');
    }
    return null;
  }

  // Send weather alert
  Future<void> _sendWeatherAlert(
      double lat, double lon, WeatherData weather) async {
    try {
      await _firestore.collection('weather_alerts').add({
        'latitude': lat,
        'longitude': lon,
        'weather_data': weather.toMap(),
        'alert_type': _getAlertType(weather),
        'message': _getAlertMessage(weather),
        'created_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });
    } catch (e) {
      print('Error sending weather alert: ${e.toString()}');
    }
  }

  // Helper methods
  String _getWeatherDescription(int code) {
    // WMO Weather Codes (based on actual Open-Meteo API response)
    // Tested with Malaybalay City API call - found codes: 3, 80, 95

    if (code == 0) return 'Clear';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast'; // Confirmed from API response

    // Fog codes
    if (code == 45) return 'Fog';
    if (code == 48) return 'Depositing Rime Fog';

    // Drizzle codes
    if (code == 51) return 'Light Drizzle';
    if (code == 53) return 'Moderate Drizzle';
    if (code == 55) return 'Dense Drizzle';
    if (code == 56) return 'Light Freezing Drizzle';
    if (code == 57) return 'Dense Freezing Drizzle';

    // Rain codes
    if (code == 61) return 'Slight Rain';
    if (code == 63) return 'Moderate Rain';
    if (code == 65) return 'Heavy Rain';
    if (code == 66) return 'Light Freezing Rain';
    if (code == 67) return 'Heavy Freezing Rain';

    // Snow codes
    if (code == 71) return 'Slight Snow Fall';
    if (code == 73) return 'Moderate Snow Fall';
    if (code == 75) return 'Heavy Snow Fall';
    if (code == 77) return 'Snow Grains';

    // Rain shower codes
    if (code == 80) return 'Slight Rain Showers'; // Confirmed from API response
    if (code == 81) return 'Moderate Rain Showers';
    if (code == 82) return 'Violent Rain Showers';

    // Snow shower codes
    if (code == 85) return 'Slight Snow Showers';
    if (code == 86) return 'Heavy Snow Showers';

    // Thunderstorm codes
    if (code == 95) return 'Thunderstorm'; // Confirmed from API response
    if (code == 96) return 'Thunderstorm with Slight Hail';
    if (code == 99) return 'Thunderstorm with Heavy Hail';

    // Fallback for any unhandled codes
    return 'Unknown Weather (Code: $code)';
  }

  bool _checkIfAlert(Map<String, dynamic> current) {
    double rainfall = (current['precipitation'] ?? 0).toDouble();
    double windSpeed = (current['wind_speed_10m'] ?? 0).toDouble();
    int weatherCode = current['weather_code'] ?? 0;

    return rainfall > 20 || windSpeed > 54 || weatherCode >= 200;
  }

  String _getAlertType(WeatherData weather) {
    if (weather.rainfall > 20) return 'Heavy Rain Alert';
    if (weather.windSpeed > 54) return 'Strong Wind Alert';
    if (weather.weatherCode >= 200 && weather.weatherCode < 300)
      return 'Thunderstorm Alert';
    return 'Severe Weather Alert';
  }

  String _getAlertMessage(WeatherData weather) {
    if (weather.rainfall > 20) {
      return 'Heavy rainfall detected (${weather.rainfall.toStringAsFixed(1)}mm/h). Flooding possible.';
    }
    if (weather.windSpeed > 54) {
      return 'Strong winds detected (${weather.windSpeed.toStringAsFixed(1)} km/h). Take precautions.';
    }
    return 'Severe weather conditions detected in your area. Stay safe.';
  }
}
