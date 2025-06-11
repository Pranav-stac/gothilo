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
      
      // Load initial data
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
    try {
      _routes = await _firebaseService.getRoutesForService('bus', agency ?? 'ahmedabad');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load routes: ${e.toString()}');
    }
  }

  // Load all stops
  Future<void> loadStops({String? agency}) async {
    try {
      _stops = await _firebaseService.getStopsForService('bus', agency ?? 'ahmedabad');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load stops: ${e.toString()}');
    }
  }

  // Load fares
  Future<void> loadFares({String? agency}) async {
    try {
      _fares = await _firebaseService.getFares(agency: agency);
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
      final position = await _locationService.getLocationWithFallback();
      
      if (position != null) {
        _nearbyStops = await _firebaseService.getNearbyStops(
          position.latitude,
          position.longitude,
          radiusKm: AppConstants.nearbyStopsRadius,
        );
      } else {
        // Use default location if GPS unavailable
        final defaultPos = _locationService.getDefaultLocation();
        _nearbyStops = await _firebaseService.getNearbyStops(
          defaultPos.latitude,
          defaultPos.longitude,
          radiusKm: AppConstants.nearbyStopsRadius,
        );
      }
      
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
    if (_selectedAgency != agency) {
      _selectedAgency = agency;
      _selectedRoute = null;
      _selectedStop = null;
      notifyListeners();
      
      // Load agency-specific data
      await loadRoutes(agency: agency);
      await loadStops(agency: agency);
      await loadFares(agency: agency);
    }
  }

  // Select route
  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    _selectedStop = null;
    notifyListeners();
    
    // Load route-specific data
    _loadRouteStops(route);
    _loadRouteSchedules(route);
  }

  // Load stops for selected route
  Future<void> _loadRouteStops(RouteModel route) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      _routeStops = await _firebaseService.getStopsForRoute(agency, route.routeId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load route stops: ${e.toString()}');
    }
  }

  // Load schedules for selected route
  Future<void> _loadRouteSchedules(RouteModel route) async {
    try {
      final agency = route.isAMTS ? AppConstants.amtsAgency : AppConstants.brtsAgency;
      final trips = await _firebaseService.getTripsForRoute(agency, route.routeId);
      
      if (trips.isNotEmpty) {
        // Get schedule for first trip as example
        _routeSchedules = await _firebaseService.getStopTimesForTrip(
          agency,
          route.routeId,
          trips.first.tripId,
        );
      } else {
        _routeSchedules = [];
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load route schedules: ${e.toString()}');
    }
  }

  // Select stop
  void selectStop(StopModel stop) {
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
      _searchResults = await _firebaseService.searchRoutes(query);
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
      _stopSearchResults = await _firebaseService.searchStops(query);
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
      return await _firebaseService.getTripsForRoute(agency, route.routeId);
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
      return await _firebaseService.getStopTimesForTrip(
        agency,
        route.routeId,
        trip.tripId,
      );
    } catch (e) {
      _setError('Failed to load schedule: ${e.toString()}');
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