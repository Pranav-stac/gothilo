import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transit_provider.dart';
import '../models/stop_model.dart';
import '../models/stop_time_model.dart';
import '../constants/app_constants.dart';

class StopDetailScreen extends StatefulWidget {
  const StopDetailScreen({super.key});

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<StopTimeModel> _liveArrivals = [];
  bool _isLoadingArrivals = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLiveArrivals();
    
    // Refresh arrivals every 30 seconds
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadLiveArrivals();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadLiveArrivals() async {
    setState(() {
      _isLoadingArrivals = true;
    });

    try {
      final provider = Provider.of<TransitProvider>(context, listen: false);
      final stop = provider.selectedStop;
      
      if (stop != null) {
        // Simulate live arrivals with current time + predictions
        _liveArrivals = _generateLiveArrivals(stop);
      }
    } catch (e) {
      print('Error loading live arrivals: $e');
    } finally {
      setState(() {
        _isLoadingArrivals = false;
      });
    }
  }

  List<StopTimeModel> _generateLiveArrivals(StopModel stop) {
    final now = DateTime.now();
    final arrivals = <StopTimeModel>[];
    
    // Generate sample arrivals for next 2 hours
    for (int i = 0; i < 8; i++) {
      final arrivalTime = now.add(Duration(minutes: 5 + (i * 15)));
      final departureTime = arrivalTime.add(const Duration(minutes: 1));
      
      arrivals.add(StopTimeModel(
        tripId: 'trip_${i + 1}',
        arrivalTime: '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}:00',
        departureTime: '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}:00',
        stopId: stop.stopId,
        stopSequence: i + 1,
        headsign: 'Live Arrival ${i + 1}',
        pickupType: 0,
        dropOffType: 0,
        shapeDistTraveled: 0.0,
        timepoint: 1,
      ));
    }
    
    return arrivals;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        final stop = provider.selectedStop;
        
        if (stop == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Stop Details')),
            body: const Center(child: Text('No stop selected')),
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
                      stop.stopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        Image.asset(
                          AppConstants.metroImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
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
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stop.locationTypeDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (stop.description.isNotEmpty)
                                Text(
                                  stop.description,
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
                        Tab(text: 'Live Arrivals'),
                        Tab(text: 'Routes'),
                        Tab(text: 'Info'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Live Arrivals Tab
                _buildLiveArrivalsTab(),
                
                // Routes Tab
                _buildRoutesTab(provider),
                
                // Info Tab
                _buildInfoTab(stop),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Add to favorites
            },
            icon: const Icon(Icons.favorite_border),
            label: const Text('Add to Favorites'),
            backgroundColor: const Color(0xFF6C63FF),
          ),
        );
      },
    );
  }

  Widget _buildLiveArrivalsTab() {
    return RefreshIndicator(
      onRefresh: _loadLiveArrivals,
      child: Column(
        children: [
          // Live status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.circle,
                    color: Color(0xFF4CAF50),
                    size: 8,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Live Arrivals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingArrivals)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Text(
                    'Updated ${DateFormat('HH:mm').format(DateTime.now())}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Arrivals list
          Expanded(
            child: _liveArrivals.isEmpty
                ? _buildEmptyArrivals()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _liveArrivals.length,
                    itemBuilder: (context, index) {
                      final arrival = _liveArrivals[index];
                      return _ArrivalCard(
                        arrival: arrival,
                        isNext: index == 0,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyArrivals() {
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
            'No arrivals scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for live arrival times',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesTab(TransitProvider provider) {
    // This would show routes that serve this stop
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
                Icons.route,
                size: 80,
                color: Colors.grey,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Routes serving this stop',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Route information will be displayed here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(StopModel stop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            title: 'Stop Information',
            children: [
              _InfoRow('Stop ID', stop.stopId),
              _InfoRow('Stop Name', stop.stopName),
              _InfoRow('Location Type', stop.locationTypeDisplay),
              if (stop.zone.isNotEmpty) _InfoRow('Zone', stop.zone),
              if (stop.description.isNotEmpty) 
                _InfoRow('Description', stop.description),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _InfoCard(
            title: 'Location',
            children: [
              _InfoRow('Latitude', stop.latitude.toStringAsFixed(6)),
              _InfoRow('Longitude', stop.longitude.toStringAsFixed(6)),
              if (stop.platformCode.isNotEmpty)
                _InfoRow('Platform', stop.platformCode),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open in maps
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Open in Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Share stop
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Stop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrivalCard extends StatelessWidget {
  final StopTimeModel arrival;
  final bool isNext;

  const _ArrivalCard({
    required this.arrival,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final arrivalDateTime = _parseTime(arrival.arrivalTime);
    final minutesUntil = arrivalDateTime.difference(now).inMinutes;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isNext ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isNext 
              ? Border.all(color: const Color(0xFF4CAF50), width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Route info
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isNext 
                      ? const Color(0xFF4CAF50) 
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: isNext ? Colors.white : Colors.blue.shade700,
                      size: 20,
                    ),
                    Text(
                      'Route',
                      style: TextStyle(
                        fontSize: 10,
                        color: isNext ? Colors.white : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Arrival info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip ${arrival.tripId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scheduled: ${arrival.formattedArrivalTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time until arrival
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTimeColor(minutesUntil).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatMinutesUntil(minutesUntil),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getTimeColor(minutesUntil),
                      ),
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEXT',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
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
      ),
    );
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _formatMinutesUntil(int minutes) {
    if (minutes <= 0) return 'Now';
    if (minutes == 1) return '1 min';
    if (minutes < 60) return '$minutes mins';
    
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) return '${hours}h';
    return '${hours}h ${remainingMins}m';
  }

  Color _getTimeColor(int minutes) {
    if (minutes <= 2) return Colors.red;
    if (minutes <= 5) return Colors.orange;
    if (minutes <= 10) return const Color(0xFF4CAF50);
    return Colors.blue;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 