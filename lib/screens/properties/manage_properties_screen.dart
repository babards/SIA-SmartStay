import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../models/property_model.dart';
import '../../widgets/hover_weather_popup.dart';
import 'property_detail_screen.dart';
import 'edit_property_screen.dart';

class ManagePropertiesScreen extends StatefulWidget {
  final Function(PropertyModel)? onEditProperty;
  final Function(PropertyModel)? onViewProperty;

  const ManagePropertiesScreen({
    Key? key,
    this.onEditProperty,
    this.onViewProperty,
  }) : super(key: key);

  @override
  State<ManagePropertiesScreen> createState() => _ManagePropertiesScreenState();
}

class _ManagePropertiesScreenState extends State<ManagePropertiesScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _center = LatLng(8.1575, 125.1278); // Malaybalay City (Capital)
  List<PropertyModel> _properties = [];
  List<PropertyModel> _filteredProperties = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final propertyService =
          Provider.of<PropertyService>(context, listen: false);
      final userId = auth.currentUserModel?.id ?? auth.currentUser?.uid;
      if (userId == null || userId.isEmpty) return;
      final list = await propertyService.getPropertiesByLandlord(userId);
      setState(() {
        _properties = list;
        _filteredProperties = list;
      });
      _fitToMarkers(list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Public method to refresh data
  Future<void> refreshData() async {
    await _load();
  }

  void _fitToMarkers(List<PropertyModel> properties) {
    if (properties.isEmpty) return;
    if (properties.length == 1) {
      final ll = LatLng(properties.first.latitude, properties.first.longitude);
      _mapController.move(ll, 16);
      _center = ll;
      return;
    }
    final points =
        properties.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(points);
    final fit = CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(48))
        .fit(_mapController.camera);
    final zoom = fit.zoom.isFinite ? fit.zoom : 14.0;
    _mapController.move(fit.center, zoom);
    _center = fit.center;
  }

  void _focusOn(PropertyModel p) {
    final ll = LatLng(p.latitude, p.longitude);
    _mapController.move(ll, 16);
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredProperties = _properties;
    } else {
      _filteredProperties = _properties.where((property) {
        return property.title.toLowerCase().contains(query) ||
            property.address.toLowerCase().contains(query) ||
            property.description.toLowerCase().contains(query);
      }).toList();
    }
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _filteredProperties = _properties;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Property Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // If we're in a layout, use the layout's navigation
                        if (widget.onEditProperty != null) {
                          // This means we're in the landlord layout, trigger add property
                          widget.onEditProperty!(PropertyModel(
                            id: '',
                            title: '',
                            description: '',
                            price: 0,
                            type: 'Boarding House',
                            bedrooms: 1,
                            bathrooms: 1,
                            latitude: 8.1575,
                            longitude: 125.1278,
                            address: '',
                            imageUrl: null,
                            landlordId: '',
                            createdAt: DateTime.now(),
                            status: 'available',
                          ));
                        } else {
                          // Fallback to direct navigation
                          Navigator.pushNamed(context, '/add-property')
                              .then((_) => _load());
                        }
                      },
                      icon: Icon(Icons.add),
                      label: Text('Create New Property'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                            hintText: 'Search property...',
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
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

                // Property Cards
                if (_loading)
                  SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredProperties.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                          'No properties yet. Tap "Add Property" to create one.'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 768;
                      if (isMobile) {
                        // Vertical list for mobile
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _filteredProperties.length,
                          itemBuilder: (context, index) {
                            final p = _filteredProperties[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: _PropertyCard(
                                property: p,
                                onViewOnMap: () => _focusOn(p),
                                onOpenDetails: () {
                                  if (widget.onViewProperty != null) {
                                    widget.onViewProperty!(p);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PropertyDetailScreen(property: p),
                                      ),
                                    );
                                  }
                                },
                                onEdit: () {
                                  if (widget.onEditProperty != null) {
                                    widget.onEditProperty!(p);
                                  } else {
                                    // Fallback to direct navigation if no callback provided
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditPropertyScreen(property: p),
                                      ),
                                    );
                                  }
                                },
                                onDelete: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete property?'),
                                      content: Text(
                                          'This will permanently remove "${p.title}".'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  try {
                                    final svc = Provider.of<PropertyService>(
                                        context,
                                        listen: false);
                                    await svc.deleteProperty(p.id);
                                    await _load();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Property deleted successfully'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to delete property: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        );
                      } else {
                        // Grid layout for desktop
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            // Calculate number of columns based on screen width
                            // Each card is ~350px wide + 16px margin = ~366px
                            final crossAxisCount =
                                (width / 366).floor().clamp(1, 4);

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: _filteredProperties.length,
                              itemBuilder: (context, index) {
                                final p = _filteredProperties[index];
                                return _PropertyCard(
                                  property: p,
                                  onViewOnMap: () => _focusOn(p),
                                  onOpenDetails: () {
                                    if (widget.onViewProperty != null) {
                                      widget.onViewProperty!(p);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PropertyDetailScreen(property: p),
                                        ),
                                      );
                                    }
                                  },
                                  onEdit: () {
                                    if (widget.onEditProperty != null) {
                                      widget.onEditProperty!(p);
                                    } else {
                                      // Fallback to direct navigation if no callback provided
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              EditPropertyScreen(property: p),
                                        ),
                                      );
                                    }
                                  },
                                  onDelete: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete property?'),
                                        content: Text(
                                            'This will permanently remove "${p.title}".'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    try {
                                      final svc = Provider.of<PropertyService>(
                                          context,
                                          listen: false);
                                      await svc.deleteProperty(p.id);
                                      await _load();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Property deleted successfully'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to delete property: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                SizedBox(height: 24),

                // Properties Map Section
                Text(
                  'Properties Map',
                  style: TextStyle(
                    fontSize: 20,
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
                                  icon:
                                      Icon(Icons.add, color: Color(0xFF2196F3)),
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
                                    _fitToMarkers(_properties);
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
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onViewOnMap;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PropertyCard({
    required this.property,
    required this.onViewOnMap,
    this.onOpenDetails,
    this.onEdit,
    this.onDelete,
  });

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
        onTap: onOpenDetails,
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
                    Spacer(),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.edit,
                                size: 14, color: Color(0xFFFF9800)),
                            onPressed: onEdit,
                            tooltip: 'Edit',
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.delete,
                                size: 14, color: Color(0xFFF44336)),
                            onPressed: onDelete,
                            tooltip: 'Delete',
                          ),
                        ),
                      ],
                    ),
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
