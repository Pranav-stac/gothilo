class RouteModel {
  final String routeId;
  final String routeName;
  final String routeShortName;
  final String routeLongName;
  final int routeType;
  final String agency;
  final String color;
  final String textColor;
  final String description;
  final String direction;
  final String url;

  RouteModel({
    required this.routeId,
    required this.routeName,
    required this.routeShortName,
    required this.routeLongName,
    required this.routeType,
    required this.agency,
    required this.color,
    required this.textColor,
    required this.description,
    required this.direction,
    required this.url,
  });

  factory RouteModel.fromJson(String routeId, Map<String, dynamic> json) {
    return RouteModel(
      routeId: routeId,
      routeName: json['route_name'] ?? '',
      routeShortName: json['route_short_name'] ?? '',
      routeLongName: json['route_long_name'] ?? json['route_name'] ?? '',
      routeType: json['route_type'] ?? 3,
      agency: json['agency'] ?? '',
      color: json['color'] ?? '000000',
      textColor: json['text_color'] ?? 'FFFFFF',
      description: json['description'] ?? '',
      direction: json['direction'] ?? 'unknown',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'route_name': routeName,
      'route_short_name': routeShortName,
      'route_long_name': routeLongName,
      'route_type': routeType,
      'agency': agency,
      'color': color,
      'text_color': textColor,
      'description': description,
      'direction': direction,
      'url': url,
    };
  }

  bool get isAMTS => agency.toUpperCase() == 'AMTS';
  bool get isBRTS => agency.toUpperCase() == 'BRTS';
  
  String get agencyFullName {
    switch (agency.toUpperCase()) {
      case 'AMTS':
        return 'Ahmedabad Municipal Transport Service';
      case 'BRTS':
        return 'Bus Rapid Transit System (Janmarg)';
      default:
        return agency;
    }
  }

  String get directionDisplay {
    switch (direction) {
      case 'down':
        return 'Downward';
      case 'up':
        return 'Upward';
      case 'short':
        return 'Short Route';
      case 'express':
        return 'Express';
      default:
        return 'Regular';
    }
  }
} 