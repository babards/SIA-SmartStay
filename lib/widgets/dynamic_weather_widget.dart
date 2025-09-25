import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/weather_service.dart';
import '../models/property_model.dart';

/// A widget that displays dynamic weather data for a property
/// This widget automatically fetches fresh weather data and updates in real-time
class DynamicWeatherWidget extends StatefulWidget {
  final PropertyModel property;
  final Widget Function(
          WeatherData? weather, List<WeatherData>? forecast, bool isLoading)
      builder;
  final bool showForecast;
  final Duration refreshInterval;

  const DynamicWeatherWidget({
    Key? key,
    required this.property,
    required this.builder,
    this.showForecast = false,
    this.refreshInterval = const Duration(minutes: 15),
  }) : super(key: key);

  @override
  State<DynamicWeatherWidget> createState() => _DynamicWeatherWidgetState();
}

class _DynamicWeatherWidgetState extends State<DynamicWeatherWidget> {
  WeatherData? _weather;
  List<WeatherData>? _forecast;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      if (mounted) {
        _loadWeatherData();
      }
    });
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final weatherService =
          Provider.of<WeatherService>(context, listen: false);

      // Fetch current weather
      final weather = await weatherService.getCurrentWeather(
        widget.property.latitude,
        widget.property.longitude,
      );

      // Fetch forecast if requested
      List<WeatherData>? forecast;
      if (widget.showForecast) {
        forecast = await weatherService.getWeatherForecast(
          widget.property.latitude,
          widget.property.longitude,
        );
      }

      if (mounted) {
        setState(() {
          _weather = weather;
          _forecast = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weather data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_weather, _forecast, _isLoading);
  }
}

/// A compact weather display widget for property cards
class CompactWeatherDisplay extends StatelessWidget {
  final PropertyModel property;
  final double? temperature;
  final String? condition;
  final double? rainfall;

  const CompactWeatherDisplay({
    Key? key,
    required this.property,
    this.temperature,
    this.condition,
    this.rainfall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicWeatherWidget(
      property: property,
      builder: (weather, forecast, isLoading) {
        if (isLoading) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 4),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }

        if (weather == null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'No weather data',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getWeatherIcon(weather.weatherCode),
              size: 16,
              color: Color(0xFF2196F3),
            ),
            SizedBox(width: 4),
            Text(
              '${weather.temperature.toStringAsFixed(0)}°C',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2196F3),
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.grain,
              size: 14,
              color: Colors.blue[600],
            ),
            SizedBox(width: 2),
            Text(
              '${weather.rainfall.toStringAsFixed(1)}mm',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode == 1 || weatherCode == 2) return Icons.wb_cloudy;
    if (weatherCode == 3) return Icons.cloud;
    if (weatherCode >= 45 && weatherCode <= 48) return Icons.foggy;
    if (weatherCode >= 51 && weatherCode <= 57) return Icons.grain;
    if (weatherCode >= 61 && weatherCode <= 67) return Icons.beach_access;
    if (weatherCode >= 71 && weatherCode <= 77) return Icons.ac_unit;
    if (weatherCode >= 80 && weatherCode <= 99) return Icons.thunderstorm;
    return Icons.wb_cloudy;
  }
}

/// A detailed weather display widget for property detail screens
class DetailedWeatherDisplay extends StatelessWidget {
  final PropertyModel property;

  const DetailedWeatherDisplay({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicWeatherWidget(
      property: property,
      showForecast: true,
      builder: (weather, forecast, isLoading) {
        if (isLoading) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading weather data...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (weather == null) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Weather data unavailable'),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Weather',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Current weather
                Row(
                  children: [
                    Icon(
                      _getWeatherIcon(weather.weatherCode),
                      size: 48,
                      color: Color(0xFF2196F3),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature.toStringAsFixed(0)}°C',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          Text(
                            weather.weatherDescription,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Weather details
                Row(
                  children: [
                    Expanded(
                      child: _buildWeatherDetail(
                        'Humidity',
                        '${weather.humidity.toStringAsFixed(0)}%',
                        Icons.water_drop,
                      ),
                    ),
                    Expanded(
                      child: _buildWeatherDetail(
                        'Wind',
                        '${weather.windSpeed.toStringAsFixed(0)} km/h',
                        Icons.air,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                _buildWeatherDetail(
                  'Rainfall',
                  '${weather.rainfall.toStringAsFixed(1)} mm',
                  Icons.grain,
                ),

                // Forecast if available
                if (forecast != null && forecast.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Text(
                    '4-Day Forecast',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: forecast
                        .take(4)
                        .map((day) => Expanded(
                              child: _buildForecastDay(day),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Color(0xFF666666)),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastDay(WeatherData day) {
    return Column(
      children: [
        Text(
          _getDayName(day.timestamp),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Icon(
          _getWeatherIcon(day.weatherCode),
          size: 24,
          color: Color(0xFF2196F3),
        ),
        SizedBox(height: 4),
        Text(
          '${day.temperature.toStringAsFixed(0)}°',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode == 1 || weatherCode == 2) return Icons.wb_cloudy;
    if (weatherCode == 3) return Icons.cloud;
    if (weatherCode >= 45 && weatherCode <= 48) return Icons.foggy;
    if (weatherCode >= 51 && weatherCode <= 57) return Icons.grain;
    if (weatherCode >= 61 && weatherCode <= 67) return Icons.beach_access;
    if (weatherCode >= 71 && weatherCode <= 77) return Icons.ac_unit;
    if (weatherCode >= 80 && weatherCode <= 99) return Icons.thunderstorm;
    return Icons.wb_cloudy;
  }
}
