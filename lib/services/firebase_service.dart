import 'package:firebase_database/firebase_database.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/trip_model.dart';
import '../models/stop_time_model.dart';
import '../models/fare_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static const String basePath = 'in/gujarat/ahmedabad/metadata/services/bus';

  // Check Firebase connection
  Future<bool> isConnected() async {
    try {
      final snapshot = await _database.child('.info/connected').get();
      return snapshot.value == true;
    } catch (e) {
      print('Firebase connection check failed: $e');
      return false;
    }
  }

  // Routes - completely dynamic from Firebase
  Future<List<RouteModel>> getRoutes({String? agency}) async {
    try {
      String path = agency != null ? '$basePath/$agency/routes' : '$basePath';
      final snapshot = await _database.child(path).get();
      
      if (!snapshot.exists) {
        print('No routes data found at path: $path');
        return [];
      }

      List<RouteModel> routes = [];
      
      if (agency != null) {
        // Single agency
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var entry in data.entries) {
            try {
              final routeData = Map<String, dynamic>.from(entry.value);
              routeData['agency'] = agency; // Ensure agency is set
              routes.add(RouteModel.fromJson(entry.key, routeData));
            } catch (e) {
              print('Error parsing route ${entry.key}: $e');
            }
          }
        }
      } else {
        // All agencies
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var agencyEntry in data.entries) {
            final agencyName = agencyEntry.key;
            final agencyData = agencyEntry.value as Map<dynamic, dynamic>?;
            if (agencyData != null && agencyData.containsKey('routes')) {
              final routesData = agencyData['routes'] as Map<dynamic, dynamic>;
              for (var routeEntry in routesData.entries) {
                try {
                  final routeData = Map<String, dynamic>.from(routeEntry.value);
                  routeData['agency'] = agencyName; // Set agency name
                  routes.add(RouteModel.fromJson(routeEntry.key, routeData));
                } catch (e) {
                  print('Error parsing route ${routeEntry.key} for agency $agencyName: $e');
                }
              }
            }
          }
        }
      }
      
      print('✅ Loaded ${routes.length} routes from Firebase');
      return routes;
    } catch (e) {
      print('❌ Error fetching routes: $e');
      return [];
    }
  }

  // Single route
  Future<RouteModel?> getRoute(String agency, String routeId) async {
    try {
      final snapshot = await _database
          .child('$basePath/$agency/routes/$routeId')
          .get();
      
      if (!snapshot.exists) {
        print('Route $routeId not found for agency $agency');
        return null;
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['agency'] = agency; // Ensure agency is set
      return RouteModel.fromJson(routeId, data);
    } catch (e) {
      print('❌ Error fetching route $routeId: $e');
      return null;
    }
  }

  // Stops - completely dynamic from Firebase
  Future<List<StopModel>> getStops({String? agency}) async {
    try {
      String path = agency != null ? '$basePath/$agency/stops' : '$basePath';
      final snapshot = await _database.child(path).get();
      
      if (!snapshot.exists) {
        print('No stops data found at path: $path');
        return [];
      }

      List<StopModel> stops = [];
      
      if (agency != null) {
        // Single agency
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var entry in data.entries) {
            try {
              final stopData = Map<String, dynamic>.from(entry.value);
              stops.add(StopModel.fromJson(entry.key, stopData));
            } catch (e) {
              print('Error parsing stop ${entry.key}: $e');
            }
          }
        }
      } else {
        // All agencies
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var agencyEntry in data.entries) {
            final agencyData = agencyEntry.value as Map<dynamic, dynamic>?;
            if (agencyData != null && agencyData.containsKey('stops')) {
              final stopsData = agencyData['stops'] as Map<dynamic, dynamic>;
              for (var stopEntry in stopsData.entries) {
                try {
                  final stopData = Map<String, dynamic>.from(stopEntry.value);
                  stops.add(StopModel.fromJson(stopEntry.key, stopData));
                } catch (e) {
                  print('Error parsing stop ${stopEntry.key}: $e');
                }
              }
            }
          }
        }
      }
      
      print('✅ Loaded ${stops.length} stops from Firebase');
      return stops;
    } catch (e) {
      print('❌ Error fetching stops: $e');
      return [];
    }
  }

  // Single stop
  Future<StopModel?> getStop(String agency, String stopId) async {
    try {
      final snapshot = await _database
          .child('$basePath/$agency/stops/$stopId')
          .get();
      
      if (!snapshot.exists) {
        print('Stop $stopId not found for agency $agency');
        return null;
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return StopModel.fromJson(stopId, data);
    } catch (e) {
      print('❌ Error fetching stop $stopId: $e');
      return null;
    }
  }

  // Nearby stops with dynamic filtering
  Future<List<StopModel>> getNearbyStops(double lat, double lon, {double radiusKm = 1.0}) async {
    try {
      final allStops = await getStops();
      
      final nearbyStops = allStops.where((stop) {
        if (!stop.isValidCoordinates) return false;
        final distance = stop.distanceTo(lat, lon);
        return distance <= radiusKm;
      }).toList();
      
      // Sort by distance
      nearbyStops.sort((a, b) => a.distanceTo(lat, lon).compareTo(b.distanceTo(lat, lon)));
      
      print('✅ Found ${nearbyStops.length} stops within ${radiusKm}km');
      return nearbyStops;
    } catch (e) {
      print('❌ Error getting nearby stops: $e');
      return [];
    }
  }

  // Dynamic trip loading
  Future<List<TripModel>> getTripsForRoute(String agency, String routeId) async {
    try {
      final snapshot = await _database
          .child('$basePath/$agency/schedules/$routeId')
          .get();
      
      if (!snapshot.exists) {
        print('No trips found for route $routeId');
        return [];
      }

      List<TripModel> trips = [];
      final data = snapshot.value as Map<dynamic, dynamic>?;
      
      if (data != null) {
        for (var tripEntry in data.entries) {
          try {
            final tripData = Map<String, dynamic>.from(tripEntry.value);
            trips.add(TripModel.fromJson(tripEntry.key, tripData));
          } catch (e) {
            print('Error parsing trip ${tripEntry.key}: $e');
          }
        }
      }
      
      print('✅ Loaded ${trips.length} trips for route $routeId');
      return trips;
    } catch (e) {
      print('❌ Error fetching trips for route $routeId: $e');
      return [];
    }
  }

  // Dynamic stop times with real-time calculations
  Future<List<StopTimeModel>> getStopTimesForTrip(String agency, String routeId, String tripId) async {
    try {
      final snapshot = await _database
          .child('$basePath/$agency/schedules/$routeId/$tripId/stop_times')
          .get();
      
      if (!snapshot.exists) {
        print('No stop times found for trip $tripId');
        return [];
      }

      List<StopTimeModel> stopTimes = [];
      final data = snapshot.value;
      
      if (data is List) {
        for (int i = 0; i < data.length; i++) {
          if (data[i] != null) {
            try {
              final stopTime = Map<String, dynamic>.from(data[i]);
              stopTimes.add(StopTimeModel.fromJson(stopTime));
            } catch (e) {
              print('Error parsing stop time at index $i: $e');
            }
          }
        }
      } else if (data is Map) {
        final mapData = data as Map<dynamic, dynamic>;
        for (var entry in mapData.entries) {
          try {
            final stopTime = Map<String, dynamic>.from(entry.value);
            stopTimes.add(StopTimeModel.fromJson(stopTime));
          } catch (e) {
            print('Error parsing stop time ${entry.key}: $e');
          }
        }
      }
      
      // Sort by stop sequence
      stopTimes.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
      
      print('✅ Loaded ${stopTimes.length} stop times for trip $tripId');
      return stopTimes;
    } catch (e) {
      print('❌ Error fetching stop times for trip $tripId: $e');
      return [];
    }
  }

  // Dynamic fare loading
  Future<List<FareModel>> getFares({String? agency}) async {
    try {
      String path = agency != null ? '$basePath/$agency/fares' : '$basePath';
      final snapshot = await _database.child(path).get();
      
      if (!snapshot.exists) {
        print('No fares data found at path: $path');
        return [];
      }

      List<FareModel> fares = [];
      
      if (agency != null) {
        // Single agency
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var entry in data.entries) {
            try {
              final fareData = Map<String, dynamic>.from(entry.value);
              fares.add(FareModel.fromJson(entry.key, fareData));
            } catch (e) {
              print('Error parsing fare ${entry.key}: $e');
            }
          }
        }
      } else {
        // All agencies
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var agencyEntry in data.entries) {
            final agencyData = agencyEntry.value as Map<dynamic, dynamic>?;
            if (agencyData != null && agencyData.containsKey('fares')) {
              final faresData = agencyData['fares'] as Map<dynamic, dynamic>;
              for (var fareEntry in faresData.entries) {
                try {
                  final fareData = Map<String, dynamic>.from(fareEntry.value);
                  fares.add(FareModel.fromJson(fareEntry.key, fareData));
                } catch (e) {
                  print('Error parsing fare ${fareEntry.key}: $e');
                }
              }
            }
          }
        }
      }
      
      print('✅ Loaded ${fares.length} fares from Firebase');
      return fares;
    } catch (e) {
      print('❌ Error fetching fares: $e');
      return [];
    }
  }

  // Dynamic search with real-time filtering
  Future<List<RouteModel>> searchRoutes(String query) async {
    try {
      final allRoutes = await getRoutes();
      final lowerQuery = query.toLowerCase();
      
      final results = allRoutes.where((route) {
        return route.routeName.toLowerCase().contains(lowerQuery) ||
               route.routeShortName.toLowerCase().contains(lowerQuery) ||
               route.routeLongName.toLowerCase().contains(lowerQuery) ||
               route.description.toLowerCase().contains(lowerQuery);
      }).toList();
      
      print('✅ Found ${results.length} routes matching "$query"');
      return results;
    } catch (e) {
      print('❌ Error searching routes: $e');
      return [];
    }
  }

  // Dynamic stop search
  Future<List<StopModel>> searchStops(String query) async {
    try {
      final allStops = await getStops();
      final lowerQuery = query.toLowerCase();
      
      final results = allStops.where((stop) {
        return stop.stopName.toLowerCase().contains(lowerQuery) ||
               stop.description.toLowerCase().contains(lowerQuery);
      }).toList();
      
      print('✅ Found ${results.length} stops matching "$query"');
      return results;
    } catch (e) {
      print('❌ Error searching stops: $e');
      return [];
    }
  }

  // Dynamic route stops loading
  Future<List<StopModel>> getStopsForRoute(String agency, String routeId) async {
    try {
      // Get all trips for the route
      final trips = await getTripsForRoute(agency, routeId);
      if (trips.isEmpty) {
        print('No trips found for route $routeId');
        return [];
      }
      
      // Get stop times for the first trip to get the stop sequence
      final stopTimes = await getStopTimesForTrip(agency, routeId, trips.first.tripId);
      if (stopTimes.isEmpty) {
        print('No stop times found for route $routeId');
        return [];
      }
      
      // Get all stops for the agency
      final allStops = await getStops(agency: agency);
      
      // Create a map for quick lookup
      final stopMap = {for (var stop in allStops) stop.stopId: stop};
      
      // Build ordered list of stops based on stop times
      List<StopModel> routeStops = [];
      for (var stopTime in stopTimes) {
        final stop = stopMap[stopTime.stopId];
        if (stop != null) {
          routeStops.add(stop);
        }
      }
      
      print('✅ Found ${routeStops.length} stops for route $routeId');
      return routeStops;
    } catch (e) {
      print('❌ Error fetching stops for route $routeId: $e');
      return [];
    }
  }

  // Real-time live arrivals simulation
  Future<List<StopTimeModel>> getLiveArrivals(String stopId) async {
    try {
      // This would connect to real-time feed in production
      // For now, we'll generate realistic predictions based on schedules
      final now = DateTime.now();
      final arrivals = <StopTimeModel>[];
      
      // Get all routes serving this stop
      final allRoutes = await getRoutes();
      
      for (var route in allRoutes.take(3)) { // Limit for demo
        final agency = route.isAMTS ? 'amts' : 'brts';
        final trips = await getTripsForRoute(agency, route.routeId);
        
        for (var trip in trips.take(2)) { // Limit trips per route
          final stopTimes = await getStopTimesForTrip(agency, route.routeId, trip.tripId);
          final relevantStopTime = stopTimes.where((st) => st.stopId == stopId).firstOrNull;
          
          if (relevantStopTime != null) {
            // Create realistic arrival time (next 30 minutes)
            final minutesToAdd = 5 + (arrivals.length * 8);
            final arrivalTime = now.add(Duration(minutes: minutesToAdd));
            
            arrivals.add(StopTimeModel(
              tripId: trip.tripId,
              arrivalTime: '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}:00',
              departureTime: '${arrivalTime.add(Duration(minutes: 1)).hour.toString().padLeft(2, '0')}:${arrivalTime.add(Duration(minutes: 1)).minute.toString().padLeft(2, '0')}:00',
              stopId: stopId,
              stopSequence: relevantStopTime.stopSequence,
              headsign: route.routeLongName,
              pickupType: 0,
              dropOffType: 0,
              shapeDistTraveled: 0.0,
              timepoint: 1,
            ));
          }
        }
      }
      
      // Sort by arrival time
      arrivals.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
      
      print('✅ Generated ${arrivals.length} live arrivals for stop $stopId');
      return arrivals.take(10).toList(); // Return next 10 arrivals
    } catch (e) {
      print('❌ Error getting live arrivals for stop $stopId: $e');
      return [];
    }
  }
} 