import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/transit_provider.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/stop_time_model.dart';
import '../constants/app_constants.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({super.key});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        final route = provider.selectedRoute;
        
        if (route == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route Details')),
            body: const Center(child: Text('No route selected')),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 250,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      route.routeShortName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image based on agency
                        Image.asset(
                          route.isAMTS 
                              ? AppConstants.amtsImagePath 
                              : AppConstants.brtsImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: route.isAMTS
                                      ? [const Color(0xFF007BFF), const Color(0xFF0056B3)]
                                      : [const Color(0xFFFF6B35), const Color(0xFFE55A2B)],
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
                          bottom: 80,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: route.isAMTS 
                                      ? Colors.blue.withOpacity(0.8)
                                      : Colors.orange.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  route.isAMTS ? 'AMTS' : 'BRTS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                route.routeLongName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                        Tab(text: 'Stops'),
                        Tab(text: 'Schedule'),
                        Tab(text: 'Map'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Stops Tab
                _buildStopsTab(provider),
                
                // Schedule Tab
                _buildScheduleTab(provider),
                
                // Map Tab
                _buildMapTab(provider),
              ],
            ),
          ),
          bottomSheet: _buildFareInfoSheet(provider, route),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Share route
            },
            icon: const Icon(Icons.share),
            label: const Text('Share Route'),
            backgroundColor: const Color(0xFF28A745),
          ),
        );
      },
    );
  }

  Widget _buildStopsTab(TransitProvider provider) {
    final stops = provider.routeStops;
    
    if (stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.noRouteImagePath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.bus_alert,
                  size: 80,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'No stops found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This route has no stops available',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stops.length,
      itemBuilder: (context, index) {
        final stop = stops[index];
        final isFirst = index == 0;
        final isLast = index == stops.length - 1;
        
        return _RouteStopCard(
          stop: stop,
          isFirst: isFirst,
          isLast: isLast,
          onTap: () {
            provider.selectStop(stop);
            Navigator.pushNamed(context, '/stop-detail');
          },
        );
      },
    );
  }

  Widget _buildScheduleTab(TransitProvider provider) {
    final schedules = provider.routeSchedules;
    
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.loadingImagePath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.schedule,
                  size: 80,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'No schedule available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule information is not available for this route',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _ScheduleCard(schedule: schedule);
      },
    );
  }

  Widget _buildMapTab(TransitProvider provider) {
    final route = provider.selectedRoute;
    final stops = provider.routeStops;
    
    if (stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.routeSystemImagePath,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.map,
                  size: 80,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Map not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No location data available for this route',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate bounds for all stops
    final validStops = stops.where((stop) => stop.isValidCoordinates).toList();
    if (validStops.isEmpty) {
      return const Center(child: Text('No valid coordinates for stops'));
    }

    final bounds = LatLngBounds.fromPoints(
      validStops.map((stop) => LatLng(stop.stopLat, stop.stopLon)).toList(),
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        bounds: bounds,
        boundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(50)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gothilo',
        ),
        MarkerLayer(
          markers: validStops.map((stop) {
            return Marker(
              point: LatLng(stop.stopLat, stop.stopLon),
              child: Container(
                decoration: BoxDecoration(
                  color: route?.isAMTS == true ? Colors.blue : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            );
          }).toList(),
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: validStops.map((stop) => LatLng(stop.stopLat, stop.stopLon)).toList(),
              color: route?.isAMTS == true ? Colors.blue : Colors.orange,
              strokeWidth: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFareInfoSheet(TransitProvider provider, RouteModel route) {
    final fares = provider.fares.where((fare) => 
        fare.agencyId.isEmpty || 
        fare.agencyId.toLowerCase() == route.agency.toLowerCase()).toList();
    
    if (fares.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no fares
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Fare Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Show more detailed fare information
                  _showFareDetailsDialog(context, fares);
                },
                child: const Text('More Info'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: fares.take(2).map((fare) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${fare.formattedPrice} (${fare.paymentMethodDisplay})',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  void _showFareDetailsDialog(BuildContext context, List<dynamic> fares) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fare Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fares.map((fare) {
              return ListTile(
                title: Text(fare.formattedPrice),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fare.paymentMethodDisplay),
                    Text(fare.transfersDisplay),
                  ],
                ),
                leading: const Icon(Icons.confirmation_number_outlined),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _RouteStopCard extends StatelessWidget {
  final StopModel stop;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _RouteStopCard({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Timeline indicator
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isFirst || isLast ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 20,
                      color: Colors.grey[300],
                    ),
                ],
              ),
            ),
            
            // Stop details
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(left: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.stopName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stop.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stop.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isFirst)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Start',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isLast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'End',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final StopTimeModel schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                schedule.formattedArrivalTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Stop details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stop ${schedule.stopSequence}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Departure: ${schedule.formattedDepartureTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Pickup/Dropoff indicators
            Column(
              children: [
                if (schedule.pickupType == AppConstants.pickupDropoffRegular)
                  Icon(
                    Icons.person_add,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                if (schedule.dropOffType == AppConstants.pickupDropoffRegular)
                  Icon(
                    Icons.person_remove,
                    color: Colors.red.shade600,
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 