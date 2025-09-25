import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/weather_service.dart';
import '../../models/property_model.dart';

class WeatherDashboardScreen extends StatefulWidget {
  @override
  State<WeatherDashboardScreen> createState() => _WeatherDashboardScreenState();
}

class _WeatherDashboardScreenState extends State<WeatherDashboardScreen> {
  WeatherData? _current;
  List<WeatherData> _forecast = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = Provider.of<WeatherService>(context, listen: false);
    final now = await svc.getCurrentWeather(8.15, 125.13);
    final fc = await svc.getWeatherForecast(8.15, 125.13);
    setState(() {
      _current = now;
      _forecast = fc;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 800,
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight -
                kBottomNavigationBarHeight,
          ),
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              if (_current != null)
                Card(
                  child: ListTile(
                    title: Text('Current Weather'),
                    subtitle: Text(
                        '${_current!.weatherDescription} • ${_current!.temperature.toStringAsFixed(1)}°C • RH ${_current!.humidity.toStringAsFixed(0)}%'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rain ${_current!.rainfall.toStringAsFixed(1)}mm'),
                        Text(
                            'Wind ${_current!.windSpeed.toStringAsFixed(1)} km/h'),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 12),
              Text('7-day Forecast',
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              ..._forecast.map((d) => Card(
                    child: ListTile(
                      title: Text('${d.weatherDescription}'),
                      subtitle: Text(
                          '${d.timestamp.toLocal().toString().split(' ').first}'),
                      trailing: Text('${d.temperature.toStringAsFixed(0)}°C'),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
