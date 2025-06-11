import 'dart:math' as Math;

class StopModel {
  final String stopId;
  final String stopName;
  final double latitude;
  final double longitude;
  final String zone;
  final int locationType;
  final String description;
  final String url;
  final String parentStation;
  final String platformCode;

  StopModel({
    required this.stopId,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.locationType,
    required this.description,
    required this.url,
    required this.parentStation,
    required this.platformCode,
  });

  factory StopModel.fromJson(String stopId, Map<String, dynamic> json) {
    return StopModel(
      stopId: stopId,
      stopName: json['stop_name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      zone: json['zone'] ?? '',
      locationType: json['location_type'] ?? 0,
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      parentStation: json['parent_station'] ?? '',
      platformCode: json['platform_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': stopId,
      'stop_name': stopName,
      'latitude': latitude,
      'longitude': longitude,
      'zone': zone,
      'location_type': locationType,
      'description': description,
      'url': url,
      'parent_station': parentStation,
      'platform_code': platformCode,
    };
  }

  // Convenience getters for compatibility
  double get stopLat => latitude;
  double get stopLon => longitude;

  bool get isValidCoordinates => latitude != 0.0 && longitude != 0.0;
  
  String get locationTypeDisplay {
    switch (locationType) {
      case 0:
        return 'Stop/Platform';
      case 1:
        return 'Station';
      case 2:
        return 'Station Entrance/Exit';
      case 3:
        return 'Generic Node';
      case 4:
        return 'Boarding Area';
      default:
        return 'Unknown';
    }
  }

  double distanceTo(double lat, double lon) {
    // Haversine formula for calculating distance
    const double earthRadius = 6371; // km
    
    double dLat = _toRadians(lat - latitude);
    double dLon = _toRadians(lon - longitude);
    
    double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(latitude)) * Math.cos(_toRadians(lat)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (Math.pi / 180);
  }
} 