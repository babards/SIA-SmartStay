import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import '../../services/property_service.dart';
import '../../services/auth_service.dart';
import '../../models/property_model.dart';

/// Mixin that provides common functionality for property forms (add/edit)
mixin PropertyFormMixin<T extends StatefulWidget> on State<T> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _bed = TextEditingController(text: '1');
  final _bath = TextEditingController(text: '1');

  // Form state
  String _type = 'Boarding House';
  String _status = 'available';
  final LatLng _defaultPoint =
      LatLng(8.1575, 125.1278); // Malaybalay City (Capital)
  LatLng _point = LatLng(8.1575, 125.1278); // Malaybalay City (Capital)
  bool _isGeocoding = false;
  final MapController _mapController = MapController();
  Timer? _debounce;
  String _lastGeocodedQuery = '';
  bool _isSaving = false;
  bool _isProcessingImage = false;
  Uint8List? _selectedImageBytes;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  // Getters for form data
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get titleController => _title;
  TextEditingController get descController => _desc;
  TextEditingController get addressController => _address;
  TextEditingController get priceController => _price;
  TextEditingController get bedController => _bed;
  TextEditingController get bathController => _bath;
  String get type => _type;
  String get status => _status;
  LatLng get point => _point;
  MapController get mapController => _mapController;
  bool get isGeocoding => _isGeocoding;
  bool get isSaving => _isSaving;
  bool get isProcessingImage => _isProcessingImage;
  String? get imageBase64 => _imageBase64;
  Uint8List? get selectedImageBytes => _selectedImageBytes;

  // Initialize form with property data (for editing)
  void initializeForm(PropertyModel? property) {
    if (property != null) {
      _title.text = property.title;
      _desc.text = property.description;
      _address.text = property.address;
      _price.text = property.price.toStringAsFixed(0);
      _bed.text = property.bedrooms.toString();
      _bath.text = property.bathrooms.toString();
      _type = property.type;
      _status = property.status;
      _point = LatLng(property.latitude, property.longitude);
      _imageBase64 = property.imageUrl; // Store base64 string
    }
  }

  // Setup address listener for geocoding
  void setupAddressListener() {
    _address.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    final text = _address.text.trim();
    if (text.length < 4) return; // avoid tiny queries
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 700), () async {
      if (text == _lastGeocodedQuery) return;
      await _geocodeAddress(auto: true);
    });
  }

  // Geocoding functionality
  Future<void> _geocodeAddress({bool auto = false}) async {
    final query = _address.text.trim();
    if (query.isEmpty) return;
    if (!auto) setState(() => _isGeocoding = true);
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${Uri.encodeComponent(query)}&countrycodes=ph');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'smartstay-app/1.0 (contact: example@example.com)'
      });
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body) as List;
        if (data.isNotEmpty) {
          final item = data.first as Map<String, dynamic>;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            final ll = LatLng(lat, lon);
            setState(() {
              _point = ll;
              _lastGeocodedQuery = query;
            });
            _mapController.move(ll, 16);
          }
        } else if (!auto) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Address not found. Tap the map to set a location.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geocoding failed (${resp.statusCode}).'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geocoding error: ${e.toString()}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (!auto && mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      final resp = await http.get(uri, headers: {
        'User-Agent': 'smartstay-app/1.0 (contact: example@example.com)'
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          _address.text = displayName;
        }
      }
    } catch (e) {
      // Silent fail for reverse geocoding
    }
  }

  // Image handling functionality
  Future<void> pickImage() async {
    try {
      setState(() {
        _isProcessingImage = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Reduced size for better performance
        maxHeight: 600,
        imageQuality: 70, // Reduced quality to keep base64 size manageable
      );

      if (image != null) {
        print('Image picked: ${image.path}');
        final bytes = await image.readAsBytes();
        print('Image bytes length: ${bytes.length}');

        // Convert to base64
        final base64String = base64Encode(bytes);
        print('Base64 string length: ${base64String.length}');

        if (mounted) {
          setState(() {
            _selectedImageBytes = bytes;
            _imageBase64 = base64String;
            _isProcessingImage = false;
          });
          print('Image converted to base64 successfully');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image selected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        setState(() {
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void removeImage() {
    setState(() {
      _imageBase64 = null;
      _selectedImageBytes = null;
    });
  }

  // Save functionality (to be implemented by the using class)
  Future<void> saveProperty(PropertyModel? initialProperty) async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // If user did not move the marker and provided an address, try geocoding once
      if (_point == _defaultPoint && _address.text.trim().isNotEmpty) {
        await _geocodeAddress();
      }

      final svc = Provider.of<PropertyService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final model = PropertyModel(
        id: initialProperty?.id ?? '',
        title: _title.text.trim(),
        description: _desc.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        type: _type,
        bedrooms: int.tryParse(_bed.text.trim()) ?? 1,
        bathrooms: int.tryParse(_bath.text.trim()) ?? 1,
        latitude: _point.latitude,
        longitude: _point.longitude,
        address: _address.text.trim(),
        imageUrl: _imageBase64, // Store base64 string directly
        landlordId: auth.currentUserModel?.id ?? auth.currentUser?.uid ?? '',
        createdAt: initialProperty?.createdAt ?? DateTime.now(),
        status: _status,
      );

      print(
          'Saving property with base64 image: ${_imageBase64 != null ? "Yes" : "No"}');

      if (initialProperty == null) {
        await svc.addProperty(model);
      } else {
        await svc.updateProperty(model);
      }

      if (!mounted) return;

      // Success handled by caller (add/edit screens) to avoid duplicate snackbars
    } catch (e) {
      print('Error saving property: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving property: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Map tap handler
  void onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _point = point);
    _mapController.move(point, 16);
    _reverseGeocode(point);
  }

  // Geocode button handler
  void onGeocodePressed() {
    if (!_isGeocoding) {
      _geocodeAddress();
    }
  }

  // Status change handler
  void onStatusChanged(String? value) {
    if (value != null) {
      setState(() {
        _status = value;
      });
    }
  }

  // Cleanup
  void disposeForm() {
    _debounce?.cancel();
    _title.dispose();
    _desc.dispose();
    _address.dispose();
    _price.dispose();
    _bed.dispose();
    _bath.dispose();
  }
}
