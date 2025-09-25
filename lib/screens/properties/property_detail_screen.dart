import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/property_model.dart';
// import '../../widgets/dynamic_weather_widget.dart';

class PropertyDetailScreen extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onBack;

  const PropertyDetailScreen({
    Key? key,
    required this.property,
    this.onBack,
  }) : super(key: key);

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
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 220,
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          height: 220,
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text('Failed to load image',
                    style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      }
    } else {
      // It's a regular URL
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 220,
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 8),
                  Text('Failed to load image',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(property.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) {
              onBack!();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (property.imageUrl != null && property.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(property.imageUrl!),
                  )
                else
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.home_work,
                        size: 64, color: Color(0xFF2196F3)),
                  ),
                SizedBox(height: 16),
                Text(property.title,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                _kv('Location', property.address),
                _kv('Rent', '₱${property.price.toStringAsFixed(0)} / mo'),
                _kv('Status',
                    property.isAvailable ? 'Available' : 'Unavailable'),
                _kv('Bedrooms', property.bedrooms.toString()),
                _kv('Bathrooms', property.bathrooms.toString()),
                if (property.description.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text(property.description),
                ],

                // Weather removed from details to reduce lag
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(k, style: TextStyle(color: Colors.black54))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
