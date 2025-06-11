class TripModel {
  final String tripId;
  final String routeId;
  final String serviceId;
  final String headsign;
  final String shortName;
  final int direction;
  final String blockId;
  final String shapeId;
  final bool wheelchairAccessible;
  final bool bikesAllowed;

  TripModel({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    required this.headsign,
    required this.shortName,
    required this.direction,
    required this.blockId,
    required this.shapeId,
    required this.wheelchairAccessible,
    required this.bikesAllowed,
  });

  factory TripModel.fromJson(String tripId, Map<String, dynamic> json) {
    return TripModel(
      tripId: tripId,
      routeId: json['route_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      headsign: json['headsign'] ?? '',
      shortName: json['short_name'] ?? '',
      direction: json['direction'] ?? 0,
      blockId: json['block_id'] ?? '',
      shapeId: json['shape_id'] ?? '',
      wheelchairAccessible: json['wheelchair_accessible'] == 1,
      bikesAllowed: json['bikes_allowed'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'route_id': routeId,
      'service_id': serviceId,
      'headsign': headsign,
      'short_name': shortName,
      'direction': direction,
      'block_id': blockId,
      'shape_id': shapeId,
      'wheelchair_accessible': wheelchairAccessible ? 1 : 0,
      'bikes_allowed': bikesAllowed ? 1 : 0,
    };
  }

  String get directionDisplay {
    switch (direction) {
      case 0:
        return 'Outbound';
      case 1:
        return 'Inbound';
      default:
        return 'Unknown';
    }
  }

  bool get hasShape => shapeId.isNotEmpty;
} 