import 'package:firebase_database/firebase_database.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/trip_model.dart';
import '../models/stop_time_model.dart';
import '../models/fare_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal() {
    // Disable persistence completely to reduce memory usage
    FirebaseDatabase.instance.setPersistenceEnabled(false);
    
    // Disable keep synced for ALL references to prevent background syncing
    _database.keepSynced(false);
    
    // Set minimum cache size (1MB minimum required by Firebase)
    try {
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(1000000); // 1MB minimum
    } catch (e) {
      print('Error setting cache size: $e');
    }
  }

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static const String basePath = 'in/gujarat/ahmedabad/services/bus';
  
  // Data limits to prevent OOM but allow enough matches
  static const int MAX_ROUTES = 20;
  static const int MAX_STOPS = 20;
  static const int MAX_TRIPS = 5;
  static const int MAX_STOP_TIMES = 20;
  static const int MAX_FARES = 10;

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

  // Get route keys only (lightweight operation)
  Future<List<String>> getRouteKeys(String agency) async {
    try {
      // Try multiple possible paths for routes
      final possiblePaths = [
        '$basePath/$agency/routes',
        'in/gujarat/ahmedabad/services/bus/$agency/routes',
        'india/gujarat/ahmedabad/services/bus/$agency/routes',
        '$basePath/$agency/data/routes',
      ];
      
      List<String> routeKeys = [];
      
      // Try each path until we find routes
      for (final path in possiblePaths) {
        print('Trying to find routes at path: $path');
        
        try {
          final snapshot = await _database
              .child(path)
              .get();
          
          if (snapshot.exists && snapshot.value != null) {
            if (snapshot.value is Map) {
              final data = snapshot.value as Map<dynamic, dynamic>;
              routeKeys = data.keys.map((k) => k.toString()).toList();
              print('Found ${routeKeys.length} route keys at path: $path');
              
              if (routeKeys.isNotEmpty) {
                return routeKeys;
              }
            }
          }
        } catch (e) {
          print('Error checking path $path: $e');
        }
      }
      
      print('No route keys found in any of the tried paths');
      return [];
    } catch (e) {
      print('Error fetching route keys: $e');
      return [];
    }
  }

  // Find best matching route ID
  String findBestMatchingRouteId(String requestedId, List<String> availableIds) {
    if (availableIds.isEmpty) return requestedId;
    
    // Exact match
    if (availableIds.contains(requestedId)) {
      return requestedId;
    }
    
    // Case-insensitive match
    final lowerRequestedId = requestedId.toLowerCase();
    for (final id in availableIds) {
      if (id.toLowerCase() == lowerRequestedId) {
        return id;
      }
    }
    
    // Alphanumeric match (ignore special characters)
    final cleanRequestedId = requestedId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    for (final id in availableIds) {
      final cleanId = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      if (cleanId == cleanRequestedId) {
        return id;
      }
    }
    
    // Partial match
    for (final id in availableIds) {
      final cleanId = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      if (cleanId.contains(cleanRequestedId) || cleanRequestedId.contains(cleanId)) {
        return id;
      }
    }
    
    return requestedId;
  }

  // Routes - with pagination to avoid memory issues
  Future<List<RouteModel>> getRoutes({String? agency}) async {
    try {
      // Try multiple possible paths for routes
      final possiblePaths = [
        '$basePath/${agency ?? 'amts'}/routes',
        'in/gujarat/ahmedabad/services/bus/${agency ?? 'amts'}/routes',
        'india/gujarat/ahmedabad/services/bus/${agency ?? 'amts'}/routes',
        '$basePath/${agency ?? 'amts'}/data/routes',
      ];
      
      List<RouteModel> routes = [];
      String successPath = '';
      
      // Try each path until we find routes
      for (final path in possiblePaths) {
        print('Trying to load routes from path: $path');
        
        try {
          final snapshot = await _database
              .child(path)
              .limitToFirst(MAX_ROUTES)
              .get();
          
          if (snapshot.exists && snapshot.value != null) {
            if (snapshot.value is Map) {
              final data = snapshot.value as Map<dynamic, dynamic>;
              
              // Process each route
              for (var entry in data.entries.take(MAX_ROUTES)) {
                try {
                  final routeId = entry.key.toString();
                  final routeData = Map<String, dynamic>.from(entry.value as Map);
                  routeData['agency'] = agency ?? 'amts';
                  routes.add(RouteModel.fromJson(routeId, routeData));
                } catch (e) {
                  print('Error parsing route ${entry.key}: $e');
                }
              }
              
              if (routes.isNotEmpty) {
                successPath = path;
                break;
              }
            }
          }
        } catch (e) {
          print('Error loading routes from path $path: $e');
        }
      }
      
      if (routes.isEmpty) {
        print('No routes found in any of the tried paths');
      } else {
        print('✅ Loaded ${routes.length} routes from Firebase at path: $successPath');
      }
      
      return routes;
    } catch (e) {
      print('❌ Error fetching routes: $e');
      return [];
    }
  }

  // Single route - fetch just one route by ID
  Future<RouteModel?> getRoute(String agency, String routeId) async {
    try {
      // First get all route keys to find the best match
      final routeKeys = await getRouteKeys(agency);
      final matchedRouteId = findBestMatchingRouteId(routeId, routeKeys);
      
      if (matchedRouteId != routeId) {
        print('Using matched route ID: $matchedRouteId instead of $routeId');
      }
      
      final snapshot = await _database
          .child('$basePath/$agency/routes/$matchedRouteId')
          .get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('Route $matchedRouteId not found for agency $agency');
        return null;
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['agency'] = agency; // Ensure agency is set
      return RouteModel.fromJson(matchedRouteId, data);
    } catch (e) {
      print('❌ Error fetching route $routeId: $e');
      return null;
    }
  }

  // Get stop keys only (lightweight operation)
  Future<List<String>> getStopKeys(String agency) async {
    try {
      // Try multiple possible paths for stops
      final possiblePaths = [
        '$basePath/$agency/stops',
        'in/gujarat/ahmedabad/services/bus/$agency/stops',
        'india/gujarat/ahmedabad/services/bus/$agency/stops',
        '$basePath/$agency/data/stops',
      ];
      
      List<String> stopKeys = [];
      
      // Try each path until we find stops
      for (final path in possiblePaths) {
        print('Trying to find stops at path: $path');
        
        try {
          final snapshot = await _database
              .child(path)
              .get();
          
          if (snapshot.exists && snapshot.value != null) {
            if (snapshot.value is Map) {
              final data = snapshot.value as Map<dynamic, dynamic>;
              stopKeys = data.keys.map((k) => k.toString()).toList();
              print('Found ${stopKeys.length} stop keys at path: $path');
              
              if (stopKeys.isNotEmpty) {
                return stopKeys;
              }
            }
          }
        } catch (e) {
          print('Error checking path $path: $e');
        }
      }
      
      print('No stop keys found in any of the tried paths');
      return [];
    } catch (e) {
      print('Error fetching stop keys: $e');
      return [];
    }
  }

  // Get stops - with pagination to avoid memory issues
  Future<List<StopModel>> getStops({String? agency}) async {
    try {
      // Try multiple possible paths for stops
      final possiblePaths = [
        '$basePath/${agency ?? 'amts'}/stops',
        'in/gujarat/ahmedabad/services/bus/${agency ?? 'amts'}/stops',
        'india/gujarat/ahmedabad/services/bus/${agency ?? 'amts'}/stops',
        '$basePath/${agency ?? 'amts'}/data/stops',
      ];
      
      List<StopModel> stops = [];
      String successPath = '';
      
      // Try each path until we find stops
      for (final path in possiblePaths) {
        print('Trying to load stops from path: $path');
        
        try {
          final snapshot = await _database
              .child(path)
              .limitToFirst(MAX_STOPS)
              .get();
          
          if (snapshot.exists && snapshot.value != null) {
            if (snapshot.value is Map) {
              final data = snapshot.value as Map<dynamic, dynamic>;
              
              // Process each stop
              for (var entry in data.entries.take(MAX_STOPS)) {
                try {
                  final stopId = entry.key.toString();
                  final stopData = Map<String, dynamic>.from(entry.value as Map);
                  stops.add(StopModel.fromJson(stopId, stopData));
                } catch (e) {
                  print('Error parsing stop ${entry.key}: $e');
                }
              }
              
              if (stops.isNotEmpty) {
                successPath = path;
                break;
              }
            }
          }
        } catch (e) {
          print('Error loading stops from path $path: $e');
        }
      }
      
      if (stops.isEmpty) {
        print('No stops found in any of the tried paths');
      } else {
        print('✅ Loaded ${stops.length} stops from Firebase at path: $successPath');
      }
      
      return stops;
    } catch (e) {
      print('❌ Error fetching stops: $e');
      return [];
    }
  }

  // Get nearby stops with pagination
  Future<List<StopModel>> getNearbyStops(
    double latitude, 
    double longitude, 
    {double radiusKm = 2.0}
  ) async {
    try {
      // For now, just return a limited set of stops
      // In a real implementation, we would filter by distance
      return getStops();
    } catch (e) {
      print('❌ Error fetching nearby stops: $e');
      return [];
    }
  }

  // Get stops for a specific route with pagination
  Future<List<StopModel>> getStopsForRoute(String agency, String routeId) async {
    try {
      // First get all route keys to find the best match
      final routeKeys = await getRouteKeys(agency);
      final matchedRouteId = findBestMatchingRouteId(routeId, routeKeys);
      
      if (matchedRouteId != routeId) {
        print('Using matched route ID: $matchedRouteId instead of $routeId');
      }
      
      // First check if the route has stops directly in its data
      final routeSnapshot = await _database
          .child('$basePath/$agency/routes/$matchedRouteId')
          .get();
      
      if (routeSnapshot.exists && routeSnapshot.value != null) {
        final routeData = routeSnapshot.value as Map<dynamic, dynamic>;
        
        // Check if there's a "stops" field in the route data
        if (routeData.containsKey('stops') && routeData['stops'] != null) {
          List<StopModel> stops = [];
          try {
            final stopsData = routeData['stops'] as Map<dynamic, dynamic>;
            final stopIds = stopsData.keys.take(MAX_STOPS).toList();
            
            // Fetch each stop individually
            for (var stopId in stopIds) {
              try {
                final stopSnapshot = await _database
                    .child('$basePath/$agency/stops/$stopId')
                    .get();
                
                if (stopSnapshot.exists && stopSnapshot.value != null) {
                  final stopData = Map<String, dynamic>.from(stopSnapshot.value as Map);
                  stops.add(StopModel.fromJson(stopId, stopData));
                }
              } catch (e) {
                print('Error fetching stop $stopId: $e');
              }
            }
            
            if (stops.isNotEmpty) {
              print('Found ${stops.length} stops directly in route data');
              return stops;
            }
          } catch (e) {
            print('Error parsing stops from route data: $e');
          }
        }
      }
      
      // If no stops in route data, try to get trips for this route
      final trips = await getTripsForRoute(agency, matchedRouteId);
      
      if (trips.isEmpty) {
        print('No trips found for route $matchedRouteId');
        return [];
      }
      
      // Get the first trip's stop times
      final firstTrip = trips.first;
      final stopTimes = await getStopTimesForTrip(agency, firstTrip.tripId);
      
      if (stopTimes.isEmpty) {
        print('No stop times found for trip ${firstTrip.tripId}');
        return [];
      }
      
      // Collect stop IDs from stop times (with limits)
      final allStopIds = stopTimes.map((st) => st.stopId).toSet().toList();
      final stopIds = allStopIds.take(MAX_STOPS).toList();
      
      // Get stop details for each ID
      List<StopModel> stops = [];
      for (var stopId in stopIds) {
        try {
          final stopSnapshot = await _database
              .child('$basePath/$agency/stops/$stopId')
              .get();
          
          if (stopSnapshot.exists && stopSnapshot.value != null) {
            final stopData = Map<String, dynamic>.from(stopSnapshot.value as Map);
            stops.add(StopModel.fromJson(stopId, stopData));
          }
        } catch (e) {
          print('Error fetching stop $stopId: $e');
        }
      }
      
      print('Found ${stops.length} stops from trip stop times');
      return stops;
    } catch (e) {
      print('❌ Error fetching stops for route $routeId: $e');
      return [];
    }
  }

  // Get trip keys for a route (lightweight operation)
  Future<List<String>> getTripKeysForRoute(String agency, String routeId) async {
    try {
      // Search in schedules/WEEKDAY/trips
      final snapshot = await _database
          .child('$basePath/$agency/schedules/WEEKDAY/trips')
          .orderByChild('route_id')
          .equalTo(routeId)
          .get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }
      
      List<String> tripKeys = [];
      if (snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        tripKeys = data.keys.map((k) => k.toString()).toList();
      }
      
      return tripKeys;
    } catch (e) {
      print('Error fetching trip keys: $e');
      return [];
    }
  }

  // Get all trip keys (lightweight operation)
  Future<List<String>> getAllTripKeys(String agency) async {
    try {
      final snapshot = await _database
          .child('$basePath/$agency/schedules/WEEKDAY/trips')
          .get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }
      
      List<String> tripKeys = [];
      if (snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        tripKeys = data.keys.map((k) => k.toString()).toList();
      }
      
      return tripKeys;
    } catch (e) {
      print('Error fetching all trip keys: $e');
      return [];
    }
  }

  // Get trips for a specific route with pagination
  Future<List<TripModel>> getTripsForRoute(String agency, String routeId) async {
    try {
      print('Searching for trips with route_id: "$routeId"');
      
      // First try to get trip keys for this route (using index)
      List<String> tripKeys = await getTripKeysForRoute(agency, routeId);
      
      // If no keys found with index, try manual search
      if (tripKeys.isEmpty) {
        print('No trip keys found with index, trying manual search');
        
        // Get all trip keys
        final allTripKeys = await getAllTripKeys(agency);
        
        // Take a sample of keys to search through
        final keysToSearch = allTripKeys.take(200).toList();
        
        // Search through each trip
        for (final tripKey in keysToSearch) {
          try {
            final snapshot = await _database
                .child('$basePath/$agency/schedules/WEEKDAY/trips/$tripKey')
                .get();
            
            if (snapshot.exists && snapshot.value != null) {
              final tripData = Map<String, dynamic>.from(snapshot.value as Map);
              final tripRouteId = tripData['route_id']?.toString() ?? '';
              
              // Print for debugging
              if (tripKeys.isEmpty && tripRouteId.isNotEmpty) {
                print('Sample trip route ID: "$tripRouteId"');
              }
              
              // Try different matching strategies
              if (tripRouteId == routeId ||
                  tripRouteId.trim().toLowerCase() == routeId.trim().toLowerCase() ||
                  tripRouteId.contains(routeId) ||
                  routeId.contains(tripRouteId)) {
                tripKeys.add(tripKey);
              }
              
              // Stop after finding a few matches
              if (tripKeys.length >= MAX_TRIPS) {
                break;
              }
            }
          } catch (e) {
            print('Error checking trip $tripKey: $e');
          }
        }
      }
      
      // Limit the number of trips to fetch
      final keysToFetch = tripKeys.take(MAX_TRIPS).toList();
      
      List<TripModel> trips = [];
      
      // Fetch each trip individually
      for (final tripKey in keysToFetch) {
        try {
          final snapshot = await _database
              .child('$basePath/$agency/schedules/WEEKDAY/trips/$tripKey')
              .get();
          
          if (snapshot.exists && snapshot.value != null) {
            final tripData = Map<String, dynamic>.from(snapshot.value as Map);
            trips.add(TripModel.fromJson(tripKey, tripData));
          }
        } catch (e) {
          print('Error fetching trip $tripKey: $e');
        }
      }
      
      print('Found ${trips.length} trips for route $routeId');
      return trips;
    } catch (e) {
      print('❌ Error fetching trips for route $routeId: $e');
      return [];
    }
  }

  // Get stop times for a specific trip with pagination
  Future<List<StopTimeModel>> getStopTimesForTrip(
    String agency, 
    String tripId
  ) async {
    try {
      final snapshot = await _database
          .child('$basePath/$agency/schedules/WEEKDAY/trips/$tripId/stop_times')
          .get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('No stop times found for trip $tripId');
        return [];
      }
      
      List<StopTimeModel> stopTimes = [];
      
      try {
        if (snapshot.value is List) {
          final data = snapshot.value as List<dynamic>;
          
          // Take a limited number of stop times
          final limit = MAX_STOP_TIMES;
          final count = data.length > limit ? limit : data.length;
          
          for (var i = 0; i < count; i++) {
            if (data[i] == null) continue;
            
            try {
              final stopTimeData = Map<String, dynamic>.from(data[i]);
              stopTimes.add(StopTimeModel.fromJson(stopTimeData));
            } catch (e) {
              print('Error parsing stop time at index $i: $e');
            }
          }
        } else if (snapshot.value is Map) {
          final mapData = snapshot.value as Map<dynamic, dynamic>;
          
          // Take a limited number of stop times
          final keys = mapData.keys.take(MAX_STOP_TIMES).toList();
          
          for (var key in keys) {
            try {
              final stopTimeData = Map<String, dynamic>.from(mapData[key]);
              stopTimes.add(StopTimeModel.fromJson(stopTimeData));
            } catch (e) {
              print('Error parsing stop time $key: $e');
            }
          }
        }
      } catch (e) {
        print('Error parsing stop times data: $e');
      }
      
      // Sort by stop sequence
      stopTimes.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
      
      print('Found ${stopTimes.length} stop times for trip $tripId');
      return stopTimes;
    } catch (e) {
      print('❌ Error fetching stop times for trip $tripId: $e');
      return [];
    }
  }

  // Get fares with pagination
  Future<List<FareModel>> getFares({String? agency}) async {
    try {
      String path;
      if (agency != null) {
        path = '$basePath/$agency/fares';
      } else {
        // Just get AMTS fares to reduce data load
        path = '$basePath/amts/fares';
      }
      
      final snapshot = await _database.child(path)
          .limitToFirst(MAX_FARES)
          .get();
      
      if (!snapshot.exists || snapshot.value == null) {
        print('No fares data found');
        return [];
      }

      List<FareModel> fares = [];
      
      try {
        if (snapshot.value is Map) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          int count = 0;
          
          for (var entry in data.entries) {
            if (count >= MAX_FARES) break;
            
            try {
              final fareData = Map<String, dynamic>.from(entry.value);
              fares.add(FareModel.fromJson(entry.key, fareData));
              count++;
            } catch (e) {
              print('Error parsing fare ${entry.key}: $e');
            }
          }
        } else if (snapshot.value is List) {
          final data = snapshot.value as List<dynamic>;
          int count = 0;
          
          for (int i = 0; i < data.length && count < MAX_FARES; i++) {
            if (data[i] == null) continue;
            
            try {
              final fareData = Map<String, dynamic>.from(data[i]);
              fares.add(FareModel.fromJson(i.toString(), fareData));
              count++;
            } catch (e) {
              print('Error parsing fare at index $i: $e');
            }
          }
        }
      } catch (e) {
        print('Error parsing fares data: $e');
      }
      
      print('Found ${fares.length} fares');
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
      }).take(MAX_ROUTES).toList();
      
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
      }).take(MAX_STOPS).toList();
      
      print('✅ Found ${results.length} stops matching "$query"');
      return results;
    } catch (e) {
      print('❌ Error searching stops: $e');
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
          final stopTimes = await getStopTimesForTrip(agency, trip.tripId);
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

  Future<List<Map<String, dynamic>>> getLiveArrivalsForStop(String stopId) async {
    try {
      // This would be implemented with real-time data
      // For now, just return empty
      return [];
    } catch (e) {
      print('❌ Error getting live arrivals for stop $stopId: $e');
      return [];
    }
  }
} 