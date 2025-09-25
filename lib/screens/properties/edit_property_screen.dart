import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';

import '../../models/property_model.dart';
import 'property_form_mixin.dart';

/// Screen for editing existing properties
class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool showAppBar;

  const EditPropertyScreen({
    Key? key,
    required this.property,
    this.onSave,
    this.onCancel,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen>
    with PropertyFormMixin<EditPropertyScreen> {
  @override
  void initState() {
    super.initState();
    setupAddressListener();
    initializeForm(widget.property);
  }

  @override
  void dispose() {
    disposeForm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If showAppBar is false, we're embedded in a layout, so don't use Scaffold
    if (!widget.showAppBar) {
      return Container(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 800,
              minHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header when no AppBar is shown
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          if (widget.onCancel != null) {
                            widget.onCancel!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Text(
                        'Edit Property',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildPropertyForm(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Original Scaffold implementation for standalone use
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Property'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 800,
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: _buildPropertyForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map Section
        SizedBox(
          height: 220,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: point,
              initialZoom: 14,
              onTap: onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartstay.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child:
                        Icon(Icons.location_pin, color: Colors.red, size: 36),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Form Section
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  suffixIcon: IconButton(
                    onPressed: isGeocoding ? null : onGeocodePressed,
                    icon: isGeocoding
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.search),
                    tooltip: 'Locate on map',
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Monthly Price (₱)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: bedController,
                      decoration: InputDecoration(labelText: 'Bedrooms'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: bathController,
                      decoration: InputDecoration(labelText: 'Bathrooms'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'available',
                    child: Text('Available'),
                  ),
                  DropdownMenuItem(
                    value: 'fullyoccupied',
                    child: Text('Fully Occupied'),
                  ),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Under Maintenance'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
              SizedBox(height: 16),

              // Image Upload Section
              Text(
                'Property Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8),

              // Add Image Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isProcessingImage ? null : pickImage,
                  icon: isProcessingImage
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.add_photo_alternate),
                  label: Text(
                      isProcessingImage ? 'Processing...' : 'Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isProcessingImage ? Colors.grey : Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Image Display Area
              _buildImageDisplayArea(),

              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (isSaving || isProcessingImage) ? null : _handleSave,
                  child: (isSaving || isProcessingImage)
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Update Property'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageDisplayArea() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFFF9F9F9),
      ),
      child: selectedImageBytes != null || imageBase64 != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: selectedImageBytes != null
                      ? Image.memory(
                          selectedImageBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : imageBase64 != null
                          ? Image.memory(
                              base64Decode(imageBase64!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error,
                                            color: Colors.red, size: 48),
                                        SizedBox(height: 8),
                                        Text('Failed to load image',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(),
                ),
                // Processing indicator
                if (isProcessingImage)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: isProcessingImage ? null : removeImage,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isProcessingImage ? Colors.grey : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Color(0xFF666666),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No image selected',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _handleSave() async {
    await saveProperty(
        widget.property); // Pass the existing property for updating

    if (!mounted) return;

    // Small delay to show success message
    await Future.delayed(Duration(milliseconds: 500));

    if (!mounted) return;

    // Show success snackbar (ensure only one)
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Property updated successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    // Use callback if available, otherwise navigate to manage properties
    if (widget.onSave != null) {
      widget.onSave!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/manage-properties',
          (route) => route.settings.name == '/dashboard' || route.isFirst);
    }
  }
}
