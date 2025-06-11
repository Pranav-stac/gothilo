class AppConstants {
  // App Information
  static const String appName = 'Gothilo';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Comprehensive public transit app for Ahmedabad';

  // Transit Agencies
  static const String amtsAgency = 'amts';
  static const String brtsAgency = 'brts';
  
  static const String amtsFullName = 'Ahmedabad Municipal Transport Service';
  static const String brtsFullName = 'Bus Rapid Transit System (Janmarg)';

  // Firebase Database Paths
  static const String firebaseBasePath = 'india/gujarat/ahmedabad/services/bus';
  
  // Location Settings
  static const double defaultLatitude = 23.0225;
  static const double defaultLongitude = 72.5714;
  static const double nearbyStopsRadius = 1.0; // km
  
  // UI Constants
  static const double borderRadius = 12.0;
  static const double padding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Colors
  static const String amtsColor = '007BFF';
  static const String brtsColor = 'FF6B35';
  static const String defaultRouteColor = '000000';
  
  // API & Service Constants
  static const int connectionTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // Cache Settings
  static const int cacheExpiryHours = 24;
  static const String cacheKeyPrefix = 'gothilo_';
  
  // Route Types (GTFS Standard)
  static const int routeTypeBus = 3;
  static const int routeTypeRail = 1;
  static const int routeTypeMetro = 1;
  
  // Stop Location Types
  static const int locationTypeStop = 0;
  static const int locationTypeStation = 1;
  static const int locationTypeStationEntrance = 2;
  
  // Pickup/Drop-off Types
  static const int pickupDropoffRegular = 0;
  static const int pickupDropoffNone = 1;
  static const int pickupDropoffPhone = 2;
  static const int pickupDropoffCoordinate = 3;
  
  // Time Formats
  static const String timeFormat24 = 'HH:mm';
  static const String timeFormat12 = 'h:mm a';
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, h:mm a';
  
  // Search & Pagination
  static const int searchMinLength = 2;
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 100;
  
  // Map Settings
  static const double defaultZoom = 12.0;
  static const double stopZoom = 15.0;
  static const double routeZoom = 13.0;
  
  // Error Messages
  static const String errorNoInternet = 'Please check your internet connection';
  static const String errorLocationPermission = 'Location permission is required';
  static const String errorLocationService = 'Location services are disabled';
  static const String errorDataNotFound = 'No data found';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  
  // Success Messages
  static const String successLocationUpdated = 'Location updated successfully';
  static const String successDataLoaded = 'Data loaded successfully';
  
  // Asset Paths
  static const String assetsImagesPath = 'assets/images/';
  static const String logoPath = '${assetsImagesPath}Gothilo.png';
  static const String amtsImagePath = '${assetsImagesPath}amts.jpeg';
  static const String brtsImagePath = '${assetsImagesPath}public_transportation_in_ahmedabad.jpeg';
  static const String loadingImagePath = '${assetsImagesPath}loading.png';
  static const String noInternetImagePath = '${assetsImagesPath}no_internet.png';
  static const String noRouteImagePath = '${assetsImagesPath}no_route_found.png';
  static const String featureImagePath = '${assetsImagesPath}feature.jpeg';
  static const String generalImagePath = '${assetsImagesPath}general.jpeg';
  static const String routeSystemImagePath = '${assetsImagesPath}route_system.jpeg';
  static const String metroImagePath = '${assetsImagesPath}metro.jpeg';
  
  // Share Text Templates
  static const String shareRouteTemplate = 'Check out this route on Gothilo: {routeName} - {routeDescription}';
  static const String shareStopTemplate = 'Meet me at this bus stop: {stopName} - Found on Gothilo app';
  static const String shareAppTemplate = 'Download Gothilo app for Ahmedabad public transport info!';
} 