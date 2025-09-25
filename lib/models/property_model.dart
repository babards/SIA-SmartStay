class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String type;
  final int bedrooms;
  final int bathrooms;
  final double latitude;
  final double longitude;
  final String address;
  final String? imageUrl;
  final String landlordId;
  final DateTime createdAt;
  final String status; // 'available', 'fullyoccupied', 'maintenance'

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.imageUrl,
    required this.landlordId,
    required this.createdAt,
    required this.status,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      type: map['type'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'],
      landlordId: map['landlordId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      status: map['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'type': type,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'imageUrl': imageUrl,
      'landlordId': landlordId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  // Helper methods for status checking
  bool get isAvailable => status == 'available';
  bool get isFullyOccupied => status == 'fullyoccupied';
  bool get isUnderMaintenance => status == 'maintenance';

  String get statusDisplayName {
    switch (status) {
      case 'available':
        return 'Available';
      case 'fullyoccupied':
        return 'Fully Occupied';
      case 'maintenance':
        return 'Under Maintenance';
      default:
        return 'Unknown';
    }
  }
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final double windDirection;
  final String weatherDescription;
  final int weatherCode;
  final DateTime timestamp;
  final bool isAlert;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherDescription,
    required this.weatherCode,
    required this.timestamp,
    this.isAlert = false,
  });

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
      rainfall: (map['rainfall'] ?? 0).toDouble(),
      windSpeed: (map['windSpeed'] ?? 0).toDouble(),
      windDirection: (map['windDirection'] ?? 0).toDouble(),
      weatherDescription: map['weatherDescription'] ?? '',
      weatherCode: map['weatherCode'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isAlert: map['isAlert'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'weatherDescription': weatherDescription,
      'weatherCode': weatherCode,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isAlert': isAlert,
    };
  }

  bool get isSevereWeather {
    return rainfall > 20 || windSpeed > 54 || weatherCode >= 200;
  }
}
