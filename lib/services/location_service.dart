import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isLocationServiceEnabled = false;
  bool _hasLocationPermission = false;
  
  // Testing mode - set to true to always use Ahmedabad coordinates
  static const bool _testingMode = true; // Set to false for production
  static const bool _useAhmedabadFallback = true; // Always fallback to Ahmedabad

  Position? get currentPosition => _currentPosition;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isTestingMode => _testingMode;

  /// Initialize location service and check permissions
  Future<bool> initialize() async {
    try {
      if (_testingMode) {
        print('🧪 TESTING MODE: Using Ahmedabad as default location');
        _currentPosition = getDefaultAhmedabadLocation();
        _isLocationServiceEnabled = true;
        _hasLocationPermission = true;
        return true;
      }

      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!_isLocationServiceEnabled) {
        print('📍 Location service disabled, using Ahmedabad fallback');
        if (_useAhmedabadFallback) {
          _currentPosition = getDefaultAhmedabadLocation();
          return true;
        }
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      _hasLocationPermission = permission == LocationPermission.always ||
                              permission == LocationPermission.whileInUse;

      if (_hasLocationPermission) {
        await getCurrentLocation();
      } else if (_useAhmedabadFallback) {
        print('📍 Location permission denied, using Ahmedabad fallback');
        _currentPosition = getDefaultAhmedabadLocation();
        return true;
      }

      return _hasLocationPermission || _useAhmedabadFallback;
    } catch (e) {
      print('❌ Error initializing location service: $e');
      if (_useAhmedabadFallback) {
        print('📍 Using Ahmedabad fallback due to error');
        _currentPosition = getDefaultAhmedabadLocation();
        return true;
      }
      return false;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (_testingMode) {
        print('🧪 TESTING MODE: Returning Ahmedabad coordinates');
        _currentPosition = getDefaultAhmedabadLocation();
        return _currentPosition;
      }

      if (!_isLocationServiceEnabled || !_hasLocationPermission) {
        await initialize();
      }

      if (!_hasLocationPermission) {
        if (_useAhmedabadFallback) {
          print('📍 No permission, using Ahmedabad fallback');
          _currentPosition = getDefaultAhmedabadLocation();
          return _currentPosition;
        }
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if location is within reasonable range of India
      if (_currentPosition != null && !_isLocationInIndia(_currentPosition!)) {
        print('📍 Location outside India, using Ahmedabad fallback');
        _currentPosition = getDefaultAhmedabadLocation();
      }

      return _currentPosition;
    } catch (e) {
      print('❌ Error getting current location: $e');
      if (_useAhmedabadFallback) {
        print('📍 Using Ahmedabad fallback due to error');
        _currentPosition = getDefaultAhmedabadLocation();
        return _currentPosition;
      }
      return null;
    }
  }

  /// Get location with timeout and fallback
  Future<Position?> getLocationWithFallback() async {
    try {
      if (_testingMode) {
        print('🧪 TESTING MODE: Returning Ahmedabad coordinates');
        _currentPosition = getDefaultAhmedabadLocation();
        return _currentPosition;
      }

      Position? position = await getCurrentLocation();
      
      if (position == null) {
        // Fallback to last known position
        position = await Geolocator.getLastKnownPosition();
        
        if (position != null) {
          // Check if last known position is in India
          if (!_isLocationInIndia(position)) {
            print('📍 Last known location outside India, using Ahmedabad fallback');
            position = getDefaultAhmedabadLocation();
          }
          _currentPosition = position;
        } else if (_useAhmedabadFallback) {
          print('📍 No last known position, using Ahmedabad fallback');
          position = getDefaultAhmedabadLocation();
          _currentPosition = position;
        }
      }

      return position;
    } catch (e) {
      print('❌ Error getting location with fallback: $e');
      if (_useAhmedabadFallback) {
        print('📍 Using Ahmedabad fallback due to error');
        _currentPosition = getDefaultAhmedabadLocation();
        return _currentPosition;
      }
      return null;
    }
  }

  /// Get default Ahmedabad location - always available for testing
  Position getDefaultAhmedabadLocation() {
    return Position(
      latitude: AppConstants.defaultLatitude,  // Ahmedabad coordinates
      longitude: AppConstants.defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: 10.0, // Simulate reasonable accuracy
      altitude: 53.0, // Average elevation of Ahmedabad
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Legacy method for backward compatibility
  Position getDefaultLocation() => getDefaultAhmedabadLocation();

  /// Check if location is within India (rough bounds)
  bool _isLocationInIndia(Position position) {
    const double indiaMinLat = 6.0;   // Southern tip
    const double indiaMaxLat = 38.0;  // Northern border
    const double indiaMinLon = 68.0;  // Western border
    const double indiaMaxLon = 98.0;  // Eastern border

    return position.latitude >= indiaMinLat &&
           position.latitude <= indiaMaxLat &&
           position.longitude >= indiaMinLon &&
           position.longitude <= indiaMaxLon;
  }

  /// Get a specific test location within Ahmedabad
  Position getTestLocationInAhmedabad(String location) {
    switch (location.toLowerCase()) {
      case 'maninagar':
        return Position(
          latitude: 23.0225, longitude: 72.5714,
          timestamp: DateTime.now(), accuracy: 10.0,
          altitude: 53.0, heading: 0, speed: 0,
          speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
        );
      case 'paldi':
        return Position(
          latitude: 23.0225, longitude: 72.5514,
          timestamp: DateTime.now(), accuracy: 10.0,
          altitude: 53.0, heading: 0, speed: 0,
          speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
        );
      case 'vastrapur':
        return Position(
          latitude: 23.0395, longitude: 72.5264,
          timestamp: DateTime.now(), accuracy: 10.0,
          altitude: 53.0, heading: 0, speed: 0,
          speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
        );
      case 'sg_highway':
        return Position(
          latitude: 23.0295, longitude: 72.5464,
          timestamp: DateTime.now(), accuracy: 10.0,
          altitude: 53.0, heading: 0, speed: 0,
          speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
        );
      default:
        return getDefaultAhmedabadLocation();
    }
  }

  /// Set test location manually for testing
  void setTestLocation(Position position) {
    print('🧪 Setting test location: ${position.latitude}, ${position.longitude}');
    _currentPosition = position;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(startLat, startLon, endLat, endLon) / 1000;
  }

  /// Check if location permissions are granted
  Future<bool> checkLocationPermission() async {
    try {
      if (_testingMode) return true;
      
      final permission = await Permission.location.status;
      _hasLocationPermission = permission.isGranted;
      return _hasLocationPermission;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return _testingMode; // Return true in testing mode
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      if (_testingMode) return true;
      
      final permission = await Permission.location.request();
      _hasLocationPermission = permission.isGranted;
      return _hasLocationPermission;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return _testingMode; // Return true in testing mode
    }
  }

  /// Open app settings for permission
  Future<void> openAppSettings() async {
    if (!_testingMode) {
      await openAppSettings();
    }
  }

  /// Check if location services are enabled
  Future<bool> checkLocationService() async {
    try {
      if (_testingMode) return true;
      
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      return _isLocationServiceEnabled;
    } catch (e) {
      print('❌ Error checking location service: $e');
      return _testingMode; // Return true in testing mode
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    if (!_testingMode) {
      await Geolocator.openLocationSettings();
    }
  }

  /// Get location stream for real-time updates
  Stream<Position> getLocationStream() {
    if (_testingMode) {
      // Return a stream that emits Ahmedabad location periodically
      return Stream.periodic(
        const Duration(seconds: 5),
        (_) => getDefaultAhmedabadLocation(),
      );
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Get location status summary
  Future<LocationStatus> getLocationStatus() async {
    final serviceEnabled = await checkLocationService();
    final permissionGranted = await checkLocationPermission();
    final hasLocation = _currentPosition != null;

    return LocationStatus(
      serviceEnabled: serviceEnabled,
      permissionGranted: permissionGranted,
      hasLocation: hasLocation,
      currentPosition: _currentPosition,
      isTestingMode: _testingMode,
    );
  }

  /// Clear cached location
  void clearLocation() {
    _currentPosition = null;
  }

  /// Get testing info
  String getTestingInfo() {
    if (_testingMode) {
      return '🧪 TESTING MODE ACTIVE\n'
             '📍 Using Ahmedabad coordinates\n'
             '🚌 Perfect for testing transit routes';
    } else if (_useAhmedabadFallback) {
      return '📍 Ahmedabad fallback enabled\n'
             '🚌 Will use Ahmedabad if GPS fails';
    } else {
      return '📱 Production mode - GPS required';
    }
  }
}

/// Location status data class
class LocationStatus {
  final bool serviceEnabled;
  final bool permissionGranted;
  final bool hasLocation;
  final Position? currentPosition;
  final bool isTestingMode;

  const LocationStatus({
    required this.serviceEnabled,
    required this.permissionGranted,
    required this.hasLocation,
    this.currentPosition,
    this.isTestingMode = false,
  });

  bool get isFullyEnabled => serviceEnabled && permissionGranted && hasLocation;
  
  String get statusMessage {
    if (isTestingMode) {
      return '🧪 Testing Mode - Using Ahmedabad location';
    } else if (!serviceEnabled) {
      return AppConstants.errorLocationService;
    } else if (!permissionGranted) {
      return AppConstants.errorLocationPermission;
    } else if (!hasLocation) {
      return 'Getting your location...';
    } else {
      return AppConstants.successLocationUpdated;
    }
  }
} 