import 'package:flutter/foundation.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/trip_model.dart';
import '../models/stop_time_model.dart';
import '../models/fare_model.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../constants/app_constants.dart';

class TransitProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  // State variables
  List<RouteModel> _routes = [];
  List<StopModel> _stops = [];
  List<StopModel> _nearbyStops = [];
  List<FareModel> _fares = [];
  List<StopModel> _routeStops = [];
  List<StopTimeModel> _routeSchedules = [];
  
  String _selectedAgency = '';
  RouteModel? _selectedRoute;
  StopModel? _selectedStop;
  
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String _error = '';
  
  // Search state
  String _searchQuery = '';
  List<RouteModel> _searchResults = [];
  List<StopModel> _stopSearchResults = [];

  // Getters
  List<RouteModel> get routes => _routes;
  List<StopModel> get stops => _stops;
  List<StopModel> get nearbyStops => _nearbyStops;
  List<FareModel> get fares => _fares;
  List<StopModel> get routeStops => _routeStops;
  List<StopTimeModel> get routeSchedules => _routeSchedules;
  
  String get selectedAgency => _selectedAgency;
  RouteModel? get selectedRoute => _selectedRoute;
  StopModel? get selectedStop => _selectedStop;
  
  bool get isLoading => _isLoading;
  bool get isLocationLoading => _isLocationLoading;
  String get error => _error;
  
  String get searchQuery => _searchQuery;
  List<RouteModel> get searchResults => _searchResults;
  List<StopModel> get stopSearchResults => _stopSearchResults;

  // Filtered routes by agency
  List<RouteModel> get amtsRoutes => 
      _routes.where((route) => route.isAMTS).toList();
  
  List<RouteModel> get brtsRoutes => 
      _routes.where((route) => route.isBRTS).toList();

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Initialize location service
      await _locationService.initialize();
      
      // Load initial data without limits
      await loadRoutes();
      await loadStops();
      await loadFares();
      await loadNearbyStops();
      
    } catch (e) {
      _setError('Failed to initialize app: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load all routes
  Future<void> loadRoutes({String? agency}) async {
    _setLoading(true);
    try {
      print('Loading routes for agency: ${agency ?? "all"}');
      _routes = await _firebaseService.getRoutes(agency: agency);
      print('Loaded ${_routes.length} routes');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load routes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load all stops
  Future<void> loadStops({String? agency}) async {
    _setLoading(true);
    try {
      print('Loading stops for agency: ${agency ?? "all"}');
      _stops = await _firebaseService.getStops(agency: agency);
      print('Loaded ${_stops.length} stops');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stops: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load fares
  Future<void> loadFares({String? agency}) async {
    try {
      print('Loading fares for agency: ${agency ?? "all"}');
      _fares = await _firebaseService.getFares(agency: agency);
      print('Loaded ${_fares.length} fares');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load fares: ${e.toString()}');
    }
  }

  // Load nearby stops based on current location
  Future<void> loadNearbyStops() async {
    _isLocationLoading = true;
    notifyListeners();
    
    try {
      print('Loading nearby stops');
      // COMMENTED OUT: Location-based filtering
      // final position = await _locationService.getLocationWithFallback();
      // 
      // if (position != null) {
      //   _nearbyStops = await _firebaseService.getNearbyStops(
      //     position.latitude,
      //     position.longitude,
      //     radiusKm: AppConstants.nearbyStopsRadius,
      //   );
      // } else {
      //   // Use default location if GPS unavailable
      //   final defaultPos = _locationService.getDefaultLocation();
      //   _nearbyStops = await _firebaseService.getNearbyStops(
      //     defaultPos.latitude,
      //     defaultPos.longitude,
      //     radiusKm: AppConstants.nearbyStopsRadius,
      //   );
      // }

      // If _stops is already populated, use it
      if (_stops.isNotEmpty) {
        _nearbyStops = _stops.take(30).toList();
      } else {
        // Otherwise load directly
        _nearbyStops = await _firebaseService.getStops();
      }
      
      print('Loaded ${_nearbyStops.length} nearby stops');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load nearby stops: ${e.toString()}');
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  // Select agency and load its data
  Future<void> selectAgency(String agency) async {
    print('Selecting agency: $agency (current: $_selectedAgency)');
    
    try {
      _setLoading(true);
      _selectedAgency = agency;
      _selectedRoute = null;
      _selectedStop = null;
      notifyListeners();
      
      // Load agency-specific data
      print('Loading data for agency: $agency');
      await loadRoutes(agency: agency);
      await loadStops(agency: agency);
      await loadFares(agency: agency);
      
      print('Agency data loaded successfully');
    } catch (e) {
      _setError('Failed to load agency data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Select route
  Future<void> selectRoute(RouteModel route) async {
    print('Selecting route: ${route.routeId} - ${route.routeName}');
    try {
      _setLoading(true);
      _selectedRoute = route;
      _selectedStop = null;
      notifyListeners();
      
      // Load route-specific data
      await _loadRouteStops(route);
      await _loadRouteSchedules(route);
      
      print('Route data loaded successfully');
    } catch (e) {
      _setError('Failed to load route data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load stops for selected route
  Future<void> _loadRouteStops(RouteModel route) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      print('Loading stops for route ${route.routeId} (agency: $agency)');
      _routeStops = await _firebaseService.getStopsForRoute(agency, route.routeId);
      print('Loaded ${_routeStops.length} stops for route ${route.routeId}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load route stops: ${e.toString()}');
    }
  }

  // Load schedules for selected route
  Future<void> _loadRouteSchedules(RouteModel route) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      print('Loading trips for route ${route.routeId} (agency: $agency)');
      final trips = await _firebaseService.getTripsForRoute(agency, route.routeId);
      
      if (trips.isNotEmpty) {
        // Get schedule for first trip as example
        print('Loading stop times for trip ${trips.first.tripId}');
        _routeSchedules = await _firebaseService.getStopTimesForTrip(
          agency,
          trips.first.tripId,
        );
        print('Loaded ${_routeSchedules.length} stop times');
      } else {
        _routeSchedules = [];
        print('No trips found for route ${route.routeId}');
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load route schedules: ${e.toString()}');
    }
  }

  // Select stop
  void selectStop(StopModel stop) {
    print('Selecting stop: ${stop.stopId} - ${stop.stopName}');
    _selectedStop = stop;
    notifyListeners();
  }

  // Search routes
  Future<void> searchRoutes(String query) async {
    _searchQuery = query;
    
    if (query.length < AppConstants.searchMinLength) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    try {
      print('Searching routes for: $query');
      _searchResults = await _firebaseService.searchRoutes(query);
      print('Found ${_searchResults.length} matching routes');
      notifyListeners();
    } catch (e) {
      _setError('Search failed: ${e.toString()}');
    }
  }

  // Search stops
  Future<void> searchStops(String query) async {
    _searchQuery = query;
    
    if (query.length < AppConstants.searchMinLength) {
      _stopSearchResults = [];
      notifyListeners();
      return;
    }
    
    try {
      print('Searching stops for: $query');
      _stopSearchResults = await _firebaseService.searchStops(query);
      print('Found ${_stopSearchResults.length} matching stops');
      notifyListeners();
    } catch (e) {
      _setError('Stop search failed: ${e.toString()}');
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _stopSearchResults = [];
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  // Get trips for selected route
  Future<List<TripModel>> getTripsForRoute(RouteModel route) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      print('Getting trips for route ${route.routeId} (agency: $agency)');
      final trips = await _firebaseService.getTripsForRoute(agency, route.routeId);
      print('Found ${trips.length} trips');
      return trips;
    } catch (e) {
      _setError('Failed to load trips: ${e.toString()}');
      return [];
    }
  }

  // Get stop times for trip
  Future<List<StopTimeModel>> getStopTimesForTrip(
    RouteModel route,
    TripModel trip,
  ) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      print('Getting stop times for trip ${trip.tripId} (agency: $agency)');
      final stopTimes = await _firebaseService.getStopTimesForTrip(
        agency,
        trip.tripId,
      );
      print('Found ${stopTimes.length} stop times');
      return stopTimes;
    } catch (e) {
      _setError('Failed to load schedule: ${e.toString()}');
      return [];
    }
  }

  // Get stops for a specific route
  Future<List<StopModel>> getStopsForRoute(RouteModel route) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      print('Loading stops for route ${route.routeId} (agency: $agency)');
      return await _firebaseService.getStopsForRoute(agency, route.routeId);
    } catch (e) {
      _setError('Failed to load stops for route: ${e.toString()}');
      return [];
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    print('ERROR: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = '';
    notifyListeners();
  }

  // Clear all selections
  void clearSelections() {
    _selectedAgency = '';
    _selectedRoute = null;
    _selectedStop = null;
    notifyListeners();
  }

  // Get agency display name
  String getAgencyDisplayName(String agency) {
    switch (agency) {
      case AppConstants.amtsAgency:
        return AppConstants.amtsFullName;
      case AppConstants.brtsAgency:
        return AppConstants.brtsFullName;
      default:
        return agency.toUpperCase();
    }
  }
} 