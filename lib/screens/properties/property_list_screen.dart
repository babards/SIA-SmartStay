import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/property_service.dart';
import '../../models/property_model.dart';

class PropertyListScreen extends StatefulWidget {
  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(8.1575, 125.1278); // Malaybalay City (Capital)
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _center = _myLocation!;
      });
      _mapController.move(_center, 13);
    } catch (_) {}
  }

  void _fitToMarkers(List<PropertyModel> properties) {
    if (properties.isEmpty) return;
    final points = properties
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);
    final bounds = LatLngBounds.fromPoints(points);
    final fit = CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50))
        .fit(_mapController.camera);
    _mapController.move(fit.center, fit.zoom);
  }

  void _focusOn(PropertyModel p) {
    final ll = LatLng(p.latitude, p.longitude);
    _mapController.move(ll, 16);
  }

  @override
  Widget build(BuildContext context) {
    final propertyService = Provider.of<PropertyService>(context);
    final properties = propertyService.properties;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1400,
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartstay.app',
                  ),
                  if (_myLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _myLocation!,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: properties
                        .map(
                          (p) => Marker(
                            point: LatLng(p.latitude, p.longitude),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showProperty(context, p),
                              child: Icon(Icons.location_on,
                                  color: Colors.red, size: 36),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _fitToMarkers(properties),
                    icon: Icon(Icons.fit_screen),
                    label: Text('Fit to markers'),
                  ),
                  SizedBox(width: 8),
                  if (_myLocation != null)
                    ElevatedButton.icon(
                      onPressed: () => _mapController.move(_myLocation!, 14),
                      icon: Icon(Icons.my_location),
                      label: Text('My location'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final p = properties[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      onTap: () => _focusOn(p),
                      leading: p.imageUrl != null
                          ? Image.network(p.imageUrl!,
                              width: 56, height: 56, fit: BoxFit.cover)
                          : Icon(Icons.home_work,
                              size: 32, color: Color(0xFF2196F3)),
                      title: Text(p.title),
                      subtitle: Text(
                          '${p.address}\n₱${p.price.toStringAsFixed(0)} / mo'),
                      isThreeLine: true,
                      trailing: Icon(Icons.map),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProperty(BuildContext context, PropertyModel p) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text(p.address),
            SizedBox(height: 6),
            Text('₱${p.price.toStringAsFixed(0)} / month'),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _focusOn(p),
                  icon: Icon(Icons.navigation),
                  label: Text('Focus'),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                  label: Text('Close'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
