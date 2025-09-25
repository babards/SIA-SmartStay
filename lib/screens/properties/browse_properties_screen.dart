import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../widgets/hover_weather_popup.dart';
import 'property_detail_screen.dart';

class BrowsePropertiesScreen extends StatefulWidget {
  final Function(PropertyModel)? onViewProperty;

  const BrowsePropertiesScreen({
    Key? key,
    this.onViewProperty,
  }) : super(key: key);

  @override
  _BrowsePropertiesScreenState createState() => _BrowsePropertiesScreenState();
}

class _BrowsePropertiesScreenState extends State<BrowsePropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng _center =
      LatLng(12.8797, 121.7740); // Default PH center; will fit to markers
  List<PropertyModel> _allProperties = [];
  List<PropertyModel> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final propertyService =
          Provider.of<PropertyService>(context, listen: false);
      await propertyService.getAllProperties();
      _allProperties = propertyService.properties;
      _filteredProperties = _allProperties;
      setState(() {});
      // Fit map to properties after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToMarkers(_filteredProperties);
      });
    } catch (e) {
      print('Error loading properties: $e');
    }
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredProperties = _allProperties;
    } else {
      _filteredProperties = _allProperties.where((property) {
        return property.title.toLowerCase().contains(query) ||
            property.address.toLowerCase().contains(query) ||
            property.description.toLowerCase().contains(query);
      }).toList();
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToMarkers(_filteredProperties);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filteredProperties = _allProperties;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToMarkers(_filteredProperties);
    });
  }

  void _fitToMarkers(List<PropertyModel> properties) {
    if (properties.isEmpty) return;

    if (properties.length == 1) {
      final only = properties.first;
      final ll = LatLng(only.latitude, only.longitude);
      _center = ll;
      _mapController.move(ll, 15.5);
      return;
    }

    double minLat = properties.first.latitude;
    double maxLat = properties.first.latitude;
    double minLng = properties.first.longitude;
    double maxLng = properties.first.longitude;

    for (final property in properties) {
      minLat = minLat < property.latitude ? minLat : property.latitude;
      maxLat = maxLat > property.latitude ? maxLat : property.latitude;
      minLng = minLng < property.longitude ? minLng : property.longitude;
      maxLng = maxLng > property.longitude ? maxLng : property.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(50),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadProperties,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Properties',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadProperties,
                    icon: Icon(Icons.refresh, color: Color(0xFF2196F3)),
                    tooltip: 'Refresh Properties',
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Search Bar
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search properties...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF2196F3)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Search'),
                    ),
                    SizedBox(width: 12),
                    TextButton(
                      onPressed: _clearSearch,
                      child: Text('Clear'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Properties Grid
              Consumer<PropertyService>(
                builder: (context, propertyService, child) {
                  final isLoading = propertyService.isLoading;

                  if (isLoading) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2196F3)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading properties...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_filteredProperties.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 64,
                              color: Color(0xFF666666),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No properties available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF666666),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Check back later for new listings',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadProperties,
                              icon: Icon(Icons.refresh, size: 16),
                              label: Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 1200
                          ? 3
                          : width > 800
                              ? 2
                              : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = _filteredProperties[index];
                          return _PropertyCard(
                            property: property,
                            onTap: () {
                              if (widget.onViewProperty != null) {
                                widget.onViewProperty!(property);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailScreen(
                                        property: property),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 24),

              // Properties Map Section
              Text(
                'Properties Map',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),

              // Map Container
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      FlutterMap(
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
                          MarkerLayer(
                            markers: _filteredProperties
                                .map((p) => Marker(
                                      point: LatLng(p.latitude, p.longitude),
                                      width: 40,
                                      height: 40,
                                      child: HoverWeatherPopup(
                                        property: p,
                                        onViewDetails: widget.onViewProperty,
                                        child: Tooltip(
                                          message: p.title,
                                          child: Icon(Icons.location_on,
                                              color: Colors.red, size: 36),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      // Map Controls
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            // Zoom In Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.add, color: Color(0xFF2196F3)),
                                onPressed: () {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    _mapController.camera.zoom + 1,
                                  );
                                },
                                tooltip: 'Zoom In',
                              ),
                            ),
                            SizedBox(height: 4),
                            // Zoom Out Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove,
                                    color: Color(0xFF2196F3)),
                                onPressed: () {
                                  _mapController.move(
                                    _mapController.camera.center,
                                    _mapController.camera.zoom - 1,
                                  );
                                },
                                tooltip: 'Zoom Out',
                              ),
                            ),
                            SizedBox(height: 4),
                            // Fit to Markers Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.my_location,
                                    color: Color(0xFF2196F3)),
                                onPressed: () {
                                  _fitToMarkers(_filteredProperties);
                                },
                                tooltip: 'Fit to Markers',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;

  const _PropertyCard({required this.property, this.onTap});

  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a base64 string (starts with data:image or is a long base64 string)
    if (imageUrl.startsWith('data:image/') || imageUrl.length > 100) {
      try {
        // Remove data:image/...;base64, prefix if present
        String base64String = imageUrl;
        if (imageUrl.contains(',')) {
          base64String = imageUrl.split(',')[1];
        }
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(Icons.home_work, size: 48, color: Color(0xFF2196F3)),
            );
          },
        );
      } catch (e) {
        return Center(
          child: Icon(Icons.home_work, size: 48, color: Color(0xFF2196F3)),
        );
      }
    } else {
      // It's a regular URL
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(Icons.home_work, size: 48, color: Color(0xFF2196F3)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: Color(0xFFE3F2FD),
                  child: property.imageUrl != null
                      ? _buildImageWidget(property.imageUrl!)
                      : Center(
                          child: Icon(Icons.home_work,
                              size: 48, color: Color(0xFF2196F3)),
                        ),
                ),
              ),
            ),
            // Property Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      property.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${property.price.toStringAsFixed(0)}.00',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: property.isAvailable
                                ? Color(0xFFE8F5E8)
                                : property.isUnderMaintenance
                                    ? Color(0xFFFFF3E0)
                                    : Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            property.statusDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: property.isAvailable
                                  ? Color(0xFF4CAF50)
                                  : property.isUnderMaintenance
                                      ? Color(0xFFFF9800)
                                      : Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
