class StopTimeModel {
  final String tripId;
  final String stopId;
  final String arrivalTime;
  final String departureTime;
  final int stopSequence;
  final String headsign;
  final int pickupType;
  final int dropOffType;
  final double shapeDistTraveled;
  final int timepoint;

  StopTimeModel({
    required this.tripId,
    required this.stopId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopSequence,
    required this.headsign,
    required this.pickupType,
    required this.dropOffType,
    required this.shapeDistTraveled,
    required this.timepoint,
  });

  factory StopTimeModel.fromJson(Map<String, dynamic> json) {
    return StopTimeModel(
      tripId: json['trip_id'] ?? '',
      stopId: json['stop_id'] ?? '',
      arrivalTime: json['arrival_time'] ?? '',
      departureTime: json['departure_time'] ?? '',
      stopSequence: json['stop_sequence'] ?? 0,
      headsign: json['headsign'] ?? '',
      pickupType: json['pickup_type'] ?? 0,
      dropOffType: json['drop_off_type'] ?? 0,
      shapeDistTraveled: (json['shape_dist_traveled'] ?? 0.0).toDouble(),
      timepoint: json['timepoint'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      'stop_id': stopId,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
      'stop_sequence': stopSequence,
      'headsign': headsign,
      'pickup_type': pickupType,
      'drop_off_type': dropOffType,
      'shape_dist_traveled': shapeDistTraveled,
      'timepoint': timepoint,
    };
  }

  // Convert time string (HH:MM:SS) to minutes from midnight
  int get arrivalMinutes => _timeToMinutes(arrivalTime);
  int get departureMinutes => _timeToMinutes(departureTime);

  String get formattedArrivalTime => _formatTime(arrivalTime);
  String get formattedDepartureTime => _formatTime(departureTime);

  bool get isPickupAvailable => pickupType == 0;
  bool get isDropOffAvailable => dropOffType == 0;

  String get pickupTypeDisplay {
    switch (pickupType) {
      case 0:
        return 'Regular pickup';
      case 1:
        return 'No pickup available';
      case 2:
        return 'Must phone agency';
      case 3:
        return 'Must coordinate with driver';
      default:
        return 'Unknown';
    }
  }

  String get dropOffTypeDisplay {
    switch (dropOffType) {
      case 0:
        return 'Regular drop off';
      case 1:
        return 'No drop off available';
      case 2:
        return 'Must phone agency';
      case 3:
        return 'Must coordinate with driver';
      default:
        return 'Unknown';
    }
  }

  int _timeToMinutes(String time) {
    if (time.isEmpty) return 0;
    
    final parts = time.split(':');
    if (parts.length != 3) return 0;
    
    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      return 0;
    }
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    
    final parts = time.split(':');
    if (parts.length != 3) return time;
    
    try {
      int hours = int.parse(parts[0]);
      final minutes = parts[1];
      
      // Handle 24+ hour format in GTFS
      if (hours >= 24) {
        hours = hours - 24;
      }
      
      final period = hours >= 12 ? 'PM' : 'AM';
      final displayHours = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours);
      
      return '$displayHours:$minutes $period';
    } catch (e) {
      return time;
    }
  }
} 