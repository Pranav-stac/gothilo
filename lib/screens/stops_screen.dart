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
    
    // Ensure stops are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransitProvider>(context, listen: false);
      if (provider.stops.isEmpty) {
        provider.loadStops();
      }
      if (provider.nearbyStops.isEmpty) {
        provider.loadNearbyStops();
      }
    });
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
      appBar: AppBar(
        title: const Text('Stops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<TransitProvider>(context, listen: false);
              provider.loadStops();
              provider.loadNearbyStops();
            },
          ),
        ],
      ),
      body: Consumer<TransitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || provider.isLocationLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading stops...'),
                ],
              ),
            );
          }
          
          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadStops();
                      provider.loadNearbyStops();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Show nearby stops if available, otherwise show all stops
          final stopsToShow = provider.nearbyStops.isNotEmpty 
              ? provider.nearbyStops 
              : provider.stops;
          
          if (stopsToShow.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No stops found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try refreshing or check your connection',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadStops();
                      provider.loadNearbyStops();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  provider.nearbyStops.isNotEmpty ? 'Nearby Stops' : 'All Stops',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padding,
                    vertical: 8,
                  ),
                  itemCount: stopsToShow.length,
                  itemBuilder: (context, index) {
                    return _buildStopCard(stopsToShow[index], provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStopCard(StopModel stop, TransitProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.directions_bus,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          stop.stopName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          stop.description.isNotEmpty 
              ? stop.description 
              : 'Stop ID: ${stop.stopId}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          provider.selectStop(stop);
          Navigator.pushNamed(context, '/stop-detail');
        },
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