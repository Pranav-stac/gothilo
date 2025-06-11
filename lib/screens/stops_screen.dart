import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/transit_provider.dart';
import '../models/stop_model.dart';
import '../constants/app_constants.dart';
import '../services/location_service.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  bool _isLocationLoading = false;
  String _locationError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNearbyStops();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyStops() async {
    setState(() {
      _isLocationLoading = true;
      _locationError = '';
    });

    try {
      final position = await _locationService.getLocationWithFallback();
      if (mounted && position != null) {
        final provider = Provider.of<TransitProvider>(context, listen: false);
        await provider.loadNearbyStops();
      } else {
        setState(() {
          _locationError = 'Unable to get location';
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Location error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TransitProvider>(
        builder: (context, provider, child) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Bus Stops',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image from assets
                        Image.asset(
                          AppConstants.brtsImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF28A745), Color(0xFF20C997)],
                                ),
                              ),
                            );
                          },
                        ),
                        // Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 60,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${provider.nearbyStops.length} stops found',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Nearby'),
                        Tab(text: 'All Stops'),
                        Tab(text: 'Favorites'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        Card(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search bus stops...',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: Icon(Icons.mic),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            onChanged: (query) {
                              provider.searchStops(query);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Location Actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLocationLoading ? null : _loadNearbyStops,
                                icon: _isLocationLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.my_location),
                                label: Text(_isLocationLoading
                                    ? 'Finding...'
                                    : 'Find Nearby'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF28A745),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Open map view
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('Map View'),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_locationError.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationError,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Nearby Stops
                _buildStopsList(provider.nearbyStops, provider, 'nearby'),
                
                // All Stops
                _buildStopsList(
                  provider.searchQuery.isNotEmpty
                      ? provider.stopSearchResults
                      : provider.stops,
                  provider,
                  'all',
                ),
                
                // Favorites (placeholder)
                _buildFavoritesTab(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStopsList(List<StopModel> stops, TransitProvider provider, String type) {
    if (stops.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: () => _loadNearbyStops(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stops.length,
        itemBuilder: (context, index) {
          final stop = stops[index];
          final distance = type == 'nearby' 
              ? _calculateDistance(stop)
              : null;
          
          return _StopCard(
            stop: stop,
            distance: distance,
            onTap: () {
              provider.selectStop(stop);
              Navigator.pushNamed(context, '/stop-detail');
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    String imagePath;
    
    switch (type) {
      case 'nearby':
        title = 'No nearby stops found';
        subtitle = 'Try refreshing your location or increase search radius';
        imagePath = AppConstants.noRouteImagePath;
        break;
      case 'all':
        title = 'No stops found';
        subtitle = 'Try adjusting your search criteria';
        imagePath = AppConstants.noInternetImagePath;
        break;
      default:
        title = 'No favorites yet';
        subtitle = 'Add stops to favorites for quick access';
        imagePath = AppConstants.loadingImagePath;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey[400],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNearbyStops,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConstants.featureImagePath,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.favorite_outline,
                size: 80,
                color: Colors.grey,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'No favorite stops yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the star icon on any stop to add it to favorites',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  double? _calculateDistance(StopModel stop) {
    final position = _locationService.currentPosition;
    if (position != null && stop.isValidCoordinates) {
      return stop.distanceTo(position.latitude, position.longitude);
    }
    return null;
  }
}

class _StopCard extends StatelessWidget {
  final StopModel stop;
  final double? distance;
  final VoidCallback onTap;

  const _StopCard({
    required this.stop,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Stop icon with zone color
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getZoneColor(stop.zone).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_bus_filled,
                  color: _getZoneColor(stop.zone),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Stop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.stopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    if (stop.description.isNotEmpty)
                      Text(
                        stop.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stop.locationTypeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (stop.zone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getZoneColor(stop.zone).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Zone ${stop.zone}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getZoneColor(stop.zone),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Distance and actions
              Column(
                children: [
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${distance!.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  IconButton(
                    onPressed: () {
                      // Add to favorites
                    },
                    icon: const Icon(Icons.favorite_border),
                    iconSize: 20,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getZoneColor(String zone) {
    switch (zone.toLowerCase()) {
      case 'a':
        return Colors.red;
      case 'b':
        return Colors.blue;
      case 'c':
        return Colors.green;
      case 'd':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 