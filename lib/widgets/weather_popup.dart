import 'package:flutter/material.dart';
import '../models/property_model.dart';

class WeatherPopup extends StatelessWidget {
  final PropertyModel property;
  final WeatherData? weather;
  final List<WeatherData>? forecast;
  final VoidCallback? onViewDetails;
  final VoidCallback? onClose;

  const WeatherPopup({
    Key? key,
    required this.property,
    this.weather,
    this.forecast,
    this.onViewDetails,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with property title and close button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    property.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Close button removed for hover popover UX
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: property.address,
                  color: Color(0xFF666666),
                ),
                SizedBox(height: 12),

                // Rent
                _buildInfoRow(
                  icon: Icons.attach_money,
                  label: 'Rent',
                  value: '₱${property.price.toStringAsFixed(0)}.00',
                  color: Color(0xFF4CAF50),
                ),
                SizedBox(height: 12),

                // Status
                _buildInfoRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: property.statusDisplayName,
                  color: property.isAvailable
                      ? Color(0xFF4CAF50)
                      : property.isUnderMaintenance
                          ? Color(0xFFFF9800)
                          : Color(0xFF9E9E9E),
                ),

                // Weather Section
                if (weather != null) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 12),

                  // Current Weather
                  Row(
                    children: [
                      _buildWeatherIcon(weather!.weatherCode),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather!.temperature.toStringAsFixed(0)}°C',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            Text(
                              weather!.weatherDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Weather Details
                  Row(
                    children: [
                      Expanded(
                        child: _buildWeatherDetail(
                          'Humidity',
                          '${weather!.humidity.toStringAsFixed(0)}%',
                          Icons.water_drop,
                        ),
                      ),
                      Expanded(
                        child: _buildWeatherDetail(
                          'Wind',
                          '${weather!.windSpeed.toStringAsFixed(0)} km/h',
                          Icons.air,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),
                  _buildWeatherDetail(
                    'Rainfall',
                    '${weather!.rainfall.toStringAsFixed(1)} mm',
                    Icons.grain,
                  ),

                  // 4-Day Forecast
                  if (forecast != null && forecast!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 12),
                    Text(
                      'Next 4 Days Forecast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < 4 && i < forecast!.length; i++)
                          _buildForecastDay(forecast![i], i),
                      ],
                    ),
                  ],
                ] else ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading weather...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewDetails,
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Color(0xFF666666)),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(int weatherCode) {
    IconData icon;
    Color color;

    // Use the same logic as _getWeatherIcon for consistency
    if (weatherCode == 0) {
      icon = Icons.wb_sunny;
      color = Colors.orange;
    } else if (weatherCode == 1 || weatherCode == 2) {
      icon = Icons.wb_cloudy;
      color = Colors.lightBlue;
    } else if (weatherCode == 3) {
      icon = Icons.cloud;
      color = Colors.grey;
    } else if (weatherCode == 45 || weatherCode == 48) {
      icon = Icons.blur_on;
      color = Colors.grey;
    } else if (weatherCode >= 51 && weatherCode <= 57) {
      icon = Icons.grain;
      color = Colors.blue;
    } else if (weatherCode >= 61 && weatherCode <= 67) {
      icon = Icons.beach_access;
      color = Colors.blue;
    } else if (weatherCode >= 71 && weatherCode <= 77) {
      icon = Icons.ac_unit;
      color = Colors.lightBlue;
    } else if (weatherCode >= 80 && weatherCode <= 82) {
      icon = Icons.beach_access;
      color = Colors.blue;
    } else if (weatherCode >= 85 && weatherCode <= 86) {
      icon = Icons.ac_unit;
      color = Colors.lightBlue;
    } else if (weatherCode == 95 || weatherCode == 96 || weatherCode == 99) {
      icon = Icons.flash_on;
      color = Colors.deepOrange;
    } else {
      // Better fallback - use cloud instead of question mark
      icon = Icons.cloud;
      color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildForecastDay(WeatherData dayWeather, int dayIndex) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateTime.now();
    // Calculate the actual day for the forecast (starting from tomorrow)
    final forecastDate = today.add(Duration(days: dayIndex + 1));
    final dayName = dayNames[forecastDate.weekday % 7];
    final dayNumber = forecastDate.day;

    return Expanded(
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            '$dayNumber',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF999999),
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getWeatherColor(dayWeather.weatherCode).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getWeatherIcon(dayWeather.weatherCode),
              color: _getWeatherColor(dayWeather.weatherCode),
              size: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${dayWeather.temperature.toStringAsFixed(0)}°',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int weatherCode) {
    // WMO Weather Codes (based on actual Open-Meteo API response)
    // Tested with Malaybalay City API call - found codes: 3, 80, 95
    if (weatherCode == 0) return Icons.wb_sunny; // Clear
    if (weatherCode == 1) return Icons.wb_cloudy; // Mainly Clear
    if (weatherCode == 2) return Icons.wb_cloudy; // Partly Cloudy
    if (weatherCode == 3) return Icons.cloud; // Overcast (confirmed from API)
    if (weatherCode == 45 || weatherCode == 48) return Icons.blur_on; // Fog
    if (weatherCode >= 51 && weatherCode <= 57) return Icons.grain; // Drizzle
    if (weatherCode >= 61 && weatherCode <= 67)
      return Icons.beach_access; // Rain
    if (weatherCode >= 71 && weatherCode <= 77) return Icons.ac_unit; // Snow
    if (weatherCode >= 80 && weatherCode <= 82)
      return Icons.beach_access; // Rain Showers (confirmed from API)
    if (weatherCode >= 85 && weatherCode <= 86)
      return Icons.ac_unit; // Snow Showers
    if (weatherCode == 95)
      return Icons.flash_on; // Thunderstorm (confirmed from API)
    if (weatherCode == 96)
      return Icons.flash_on; // Thunderstorm with Slight Hail
    if (weatherCode == 99)
      return Icons.flash_on; // Thunderstorm with Heavy Hail
    return Icons.wb_sunny; // Default to sunny
  }

  Color _getWeatherColor(int weatherCode) {
    // WMO Weather Codes (Open-Meteo uses these)
    if (weatherCode == 0) return Colors.orange; // Clear
    if (weatherCode == 1) return Colors.lightBlue; // Mainly Clear
    if (weatherCode == 2) return Colors.grey; // Partly Cloudy
    if (weatherCode == 3) return Colors.grey; // Overcast
    if (weatherCode == 45 || weatherCode == 48) return Colors.grey; // Fog
    if (weatherCode >= 51 && weatherCode <= 57) return Colors.blue; // Drizzle
    if (weatherCode >= 61 && weatherCode <= 67) return Colors.blue; // Rain
    if (weatherCode >= 71 && weatherCode <= 77) return Colors.lightBlue; // Snow
    if (weatherCode >= 80 && weatherCode <= 82)
      return Colors.blue; // Rain Showers
    if (weatherCode >= 85 && weatherCode <= 86)
      return Colors.lightBlue; // Snow Showers
    if (weatherCode == 95) return Colors.deepOrange; // Thunderstorm
    if (weatherCode == 96)
      return Colors.deepOrange; // Thunderstorm with Slight Hail
    if (weatherCode == 99)
      return Colors.deepOrange; // Thunderstorm with Heavy Hail
    return Colors.orange; // Default to orange for sunny weather
  }
}
