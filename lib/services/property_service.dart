import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';

class PropertyService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PropertyModel> _properties = [];
  List<PropertyModel> get properties => _properties;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Get all properties
  Future<void> getAllProperties() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔍 Fetching all available properties...');

      // First, try to get all properties without the compound query
      QuerySnapshot allSnapshot =
          await _firestore.collection('properties').get();
      print(
          '📊 Total documents in properties collection: ${allSnapshot.docs.length}');

      // Filter available properties on the client side
      List<PropertyModel> allProperties = allSnapshot.docs
          .map((doc) =>
              PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter for available properties and sort by creation date
      _properties = allProperties
          .where((property) => property.status == 'available')
          .toList();

      // Sort by creation date (newest first)
      _properties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print(
          '📋 Loaded ${_properties.length} available properties for browsing');

      if (_properties.isEmpty) {
        print('⚠️ No available properties found - checking all properties...');
        for (var property in allProperties) {
          print('   - ${property.title} - status: ${property.status}');
        }
      }
    } catch (e) {
      print('❌ Error fetching properties: ${e.toString()}');
      _properties = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get properties by landlord
  Future<List<PropertyModel>> getPropertiesByLandlord(String landlordId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('properties')
          .where('landlordId', isEqualTo: landlordId)
          .get();

      final list = snapshot.docs
          .map((doc) => PropertyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      print('Error fetching landlord properties: ${e.toString()}');
      return [];
    }
  }

  // Add new property (simplified - no image upload)
  Future<String?> addProperty(PropertyModel property) async {
    try {
      print(
          '🏠 Adding property: ${property.title} - Status: ${property.status}');

      DocumentReference docRef =
          await _firestore.collection('properties').add(property.toMap());

      print('✅ Property added with ID: ${docRef.id}');
      await getAllProperties(); // Refresh the list
      return docRef.id;
    } catch (e) {
      print('❌ Failed to add property: ${e.toString()}');
      throw Exception('Failed to add property: ${e.toString()}');
    }
  }

  // Update property
  Future<void> updateProperty(PropertyModel property) async {
    try {
      await _firestore
          .collection('properties')
          .doc(property.id)
          .update(property.toMap());

      await getAllProperties(); // Refresh the list
    } catch (e) {
      throw Exception('Failed to update property: ${e.toString()}');
    }
  }

  // Delete property
  Future<void> deleteProperty(String propertyId) async {
    try {
      if (propertyId.isEmpty) {
        throw Exception('Property ID cannot be empty');
      }
      print('🗑️ Deleting property with ID: $propertyId');
      await _firestore.collection('properties').doc(propertyId).delete();
      print('✅ Property deleted successfully');
      await getAllProperties();
    } catch (e) {
      print('❌ Failed to delete property: ${e.toString()}');
      throw Exception('Failed to delete property: ${e.toString()}');
    }
  }

  // Search properties
  Future<List<PropertyModel>> searchProperties({
    String? location,
    double? minPrice,
    double? maxPrice,
    String? type,
    int? minBedrooms,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('properties')
          .where('status', isEqualTo: 'available')
          .get();

      List<PropertyModel> results = snapshot.docs
          .map((doc) =>
              PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply filters
      if (type != null && type.isNotEmpty) {
        results = results.where((property) => property.type == type).toList();
      }

      if (minPrice != null) {
        results =
            results.where((property) => property.price >= minPrice).toList();
      }

      if (maxPrice != null) {
        results =
            results.where((property) => property.price <= maxPrice).toList();
      }

      // Filter by location and bedrooms (client-side filtering)
      if (location != null && location.isNotEmpty) {
        results = results
            .where((property) =>
                property.address.toLowerCase().contains(location.toLowerCase()))
            .toList();
      }

      if (minBedrooms != null) {
        results = results
            .where((property) => property.bedrooms >= minBedrooms)
            .toList();
      }

      return results;
    } catch (e) {
      print('Error searching properties: ${e.toString()}');
      return [];
    }
  }
}
