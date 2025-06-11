import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transit_provider.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../constants/app_constants.dart';
import '../services/location_service.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _tripType = 'depart_at'; // depart_at, arrive_by
  String _routePreference = 'fastest'; // fastest, cheapest, shortest, least_transfers
  bool _accessibleOnly = false;
  
  List<TripPlan> _tripPlans = [];
  bool _isPlanning = false;
  StopModel? _fromStop;
  StopModel? _toStop;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _planTrip() async {
    if (_fromStop == null || _toStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both origin and destination')),
      );
      return;
    }

    setState(() {
      _isPlanning = true;
      _tripPlans = [];
    });

    try {
      // Simulate trip planning with different options
      await Future.delayed(const Duration(seconds: 2));
      
      _tripPlans = _generateTripPlans(_fromStop!, _toStop!);
      
      setState(() {
        _isPlanning = false;
      });
    } catch (e) {
      setState(() {
        _isPlanning = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip planning failed: $e')),
      );
    }
  }

  List<TripPlan> _generateTripPlans(StopModel from, StopModel to) {
    final plans = <TripPlan>[];
    final now = DateTime.now();
    
    // Direct AMTS route
    plans.add(TripPlan(
      id: '1',
      duration: const Duration(minutes: 35),
      walkingDistance: 0.3,
      totalFare: 15.0,
      transferCount: 0,
      legs: [
        TripLeg(
          mode: 'WALK',
          from: 'Current Location',
          to: from.stopName,
          startTime: now,
          endTime: now.add(const Duration(minutes: 5)),
          route: null,
          distance: 0.3,
        ),
        TripLeg(
          mode: 'BUS',
          from: from.stopName,
          to: to.stopName,
          startTime: now.add(const Duration(minutes: 5)),
          endTime: now.add(const Duration(minutes: 30)),
          route: RouteModel(
            routeId: 'amts_101',
            routeName: 'AMTS Route 101',
            routeShortName: '101',
            routeLongName: 'Paldi to Maninagar',
            routeType: 3,
            agency: 'amts',
            color: '007BFF',
            textColor: 'FFFFFF',
            description: 'Direct route',
            direction: 'up',
            url: '',
          ),
          distance: 12.5,
        ),
        TripLeg(
          mode: 'WALK',
          from: to.stopName,
          to: 'Destination',
          startTime: now.add(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 35)),
          route: null,
          distance: 0.2,
        ),
      ],
    ));

    // AMTS + BRTS transfer
    plans.add(TripPlan(
      id: '2',
      duration: const Duration(minutes: 42),
      walkingDistance: 0.6,
      totalFare: 25.0,
      transferCount: 1,
      legs: [
        TripLeg(
          mode: 'WALK',
          from: 'Current Location',
          to: from.stopName,
          startTime: now,
          endTime: now.add(const Duration(minutes: 5)),
          route: null,
          distance: 0.3,
        ),
        TripLeg(
          mode: 'BUS',
          from: from.stopName,
          to: 'Transfer Station',
          startTime: now.add(const Duration(minutes: 5)),
          endTime: now.add(const Duration(minutes: 20)),
          route: RouteModel(
            routeId: 'amts_45',
            routeName: 'AMTS Route 45',
            routeShortName: '45',
            routeLongName: 'Feeder to BRTS',
            routeType: 3,
            agency: 'amts',
            color: '007BFF',
            textColor: 'FFFFFF',
            description: 'Feeder route',
            direction: 'up',
            url: '',
          ),
          distance: 8.2,
        ),
        TripLeg(
          mode: 'WALK',
          from: 'Transfer Station',
          to: 'BRTS Station',
          startTime: now.add(const Duration(minutes: 20)),
          endTime: now.add(const Duration(minutes: 25)),
          route: null,
          distance: 0.3,
        ),
        TripLeg(
          mode: 'BRT',
          from: 'BRTS Station',
          to: 'Destination BRTS',
          startTime: now.add(const Duration(minutes: 25)),
          endTime: now.add(const Duration(minutes: 37)),
          route: RouteModel(
            routeId: 'brts_b1',
            routeName: 'BRTS B1',
            routeShortName: 'B1',
            routeLongName: 'Rapid Transit Line',
            routeType: 3,
            agency: 'brts',
            color: 'FF6B35',
            textColor: 'FFFFFF',
            description: 'Rapid transit',
            direction: 'up',
            url: '',
          ),
          distance: 15.8,
        ),
        TripLeg(
          mode: 'WALK',
          from: 'Destination BRTS',
          to: 'Destination',
          startTime: now.add(const Duration(minutes: 37)),
          endTime: now.add(const Duration(minutes: 42)),
          route: null,
          distance: 0.3,
        ),
      ],
    ));

    // Express BRTS route
    plans.add(TripPlan(
      id: '3',
      duration: const Duration(minutes: 28),
      walkingDistance: 0.8,
      totalFare: 20.0,
      transferCount: 0,
      legs: [
        TripLeg(
          mode: 'WALK',
          from: 'Current Location',
          to: 'Nearest BRTS',
          startTime: now,
          endTime: now.add(const Duration(minutes: 8)),
          route: null,
          distance: 0.8,
        ),
        TripLeg(
          mode: 'BRT',
          from: 'Nearest BRTS',
          to: 'Destination BRTS',
          startTime: now.add(const Duration(minutes: 8)),
          endTime: now.add(const Duration(minutes: 25)),
          route: RouteModel(
            routeId: 'brts_express',
            routeName: 'BRTS Express',
            routeShortName: 'EXP',
            routeLongName: 'Express Service',
            routeType: 3,
            agency: 'brts',
            color: 'FF6B35',
            textColor: 'FFFFFF',
            description: 'Express service',
            direction: 'up',
            url: '',
          ),
          distance: 18.5,
        ),
        TripLeg(
          mode: 'WALK',
          from: 'Destination BRTS',
          to: 'Destination',
          startTime: now.add(const Duration(minutes: 25)),
          endTime: now.add(const Duration(minutes: 28)),
          route: null,
          distance: 0.2,
        ),
      ],
    ));

    // Sort based on preference
    switch (_routePreference) {
      case 'fastest':
        plans.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'cheapest':
        plans.sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case 'least_transfers':
        plans.sort((a, b) => a.transferCount.compareTo(b.transferCount));
        break;
    }

    return plans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Trip Planner',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppConstants.routeSystemImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                            ),
                          ),
                        );
                      },
                    ),
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
                    Tab(text: 'Plan Trip'),
                    Tab(text: 'Saved Trips'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPlanTripTab(),
            _buildSavedTripsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTripTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Origin and Destination
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // From field
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fromController,
                          decoration: const InputDecoration(
                            hintText: 'From (Origin)',
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.my_location),
                          ),
                          onTap: () => _selectLocation(true),
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // To field
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _toController,
                          decoration: const InputDecoration(
                            hintText: 'To (Destination)',
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.location_on),
                          ),
                          onTap: () => _selectLocation(false),
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Swap button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: _swapLocations,
                      icon: const Icon(Icons.swap_vert),
                      tooltip: 'Swap origin and destination',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date and Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'When',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Depart at'),
                          value: 'depart_at',
                          groupValue: _tripType,
                          onChanged: (value) {
                            setState(() {
                              _tripType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Arrive by'),
                          value: 'arrive_by',
                          groupValue: _tripType,
                          onChanged: (value) {
                            setState(() {
                              _tripType = value!;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    value: _routePreference,
                    decoration: const InputDecoration(
                      labelText: 'Optimize for',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'fastest', child: Text('Fastest Route')),
                      DropdownMenuItem(value: 'cheapest', child: Text('Cheapest Route')),
                      DropdownMenuItem(value: 'shortest', child: Text('Shortest Distance')),
                      DropdownMenuItem(value: 'least_transfers', child: Text('Least Transfers')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _routePreference = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  CheckboxListTile(
                    title: const Text('Accessible routes only'),
                    subtitle: const Text('Routes suitable for wheelchairs'),
                    value: _accessibleOnly,
                    onChanged: (value) {
                      setState(() {
                        _accessibleOnly = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Plan Trip Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPlanning ? null : _planTrip,
              icon: _isPlanning 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.directions),
              label: Text(_isPlanning ? 'Planning...' : 'Plan My Trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Trip Results
          if (_tripPlans.isNotEmpty) ...[
            const Text(
              'Trip Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ..._tripPlans.map((plan) => _TripPlanCard(
              plan: plan,
              onTap: () => _showTripDetails(plan),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedTripsTab() {
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
                Icons.bookmark_outline,
                size: 80,
                color: Colors.grey,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'No saved trips yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your frequent trips for quick planning',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation(bool isFrom) async {
    // Show location picker dialog
    final result = await showDialog<StopModel>(
      context: context,
      builder: (context) => _LocationPickerDialog(isFrom: isFrom),
    );
    
    if (result != null) {
      setState(() {
        if (isFrom) {
          _fromStop = result;
          _fromController.text = result.stopName;
        } else {
          _toStop = result;
          _toController.text = result.stopName;
        }
      });
    }
  }

  void _swapLocations() {
    setState(() {
      final tempStop = _fromStop;
      final tempText = _fromController.text;
      
      _fromStop = _toStop;
      _fromController.text = _toController.text;
      
      _toStop = tempStop;
      _toController.text = tempText;
    });
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _showTripDetails(TripPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TripDetailsSheet(plan: plan),
    );
  }
}

// Data Models
class TripPlan {
  final String id;
  final Duration duration;
  final double walkingDistance;
  final double totalFare;
  final int transferCount;
  final List<TripLeg> legs;

  TripPlan({
    required this.id,
    required this.duration,
    required this.walkingDistance,
    required this.totalFare,
    required this.transferCount,
    required this.legs,
  });
}

class TripLeg {
  final String mode; // WALK, BUS, BRT
  final String from;
  final String to;
  final DateTime startTime;
  final DateTime endTime;
  final RouteModel? route;
  final double distance;

  TripLeg({
    required this.mode,
    required this.from,
    required this.to,
    required this.startTime,
    required this.endTime,
    required this.route,
    required this.distance,
  });
}

// UI Components
class _TripPlanCard extends StatelessWidget {
  final TripPlan plan;
  final VoidCallback onTap;

  const _TripPlanCard({
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.duration.inMinutes} min',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${plan.totalFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  if (plan.transferCount > 0) ...[
                    Icon(
                      Icons.transfer_within_a_station,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${plan.transferCount} transfer${plan.transferCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.walkingDistance.toStringAsFixed(1)} km walk',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Route preview
              Row(
                children: plan.legs.map((leg) {
                  final isLast = leg == plan.legs.last;
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getLegColor(leg.mode).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            leg.mode,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getLegColor(leg.mode),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isLast) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLegColor(String mode) {
    switch (mode) {
      case 'WALK':
        return Colors.grey;
      case 'BUS':
        return Colors.blue;
      case 'BRT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _LocationPickerDialog extends StatefulWidget {
  final bool isFrom;

  const _LocationPickerDialog({required this.isFrom});

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<StopModel> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.isFrom ? 'Select Origin' : 'Select Destination',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for a location...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchLocations,
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Consumer<TransitProvider>(
                builder: (context, provider, child) {
                  final stops = _searchController.text.isEmpty
                      ? provider.nearbyStops.take(10).toList()
                      : _searchResults;
                  
                  return ListView.builder(
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(stop.stopName),
                        subtitle: Text(stop.locationTypeDisplay),
                        onTap: () => Navigator.pop(context, stop),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchLocations(String query) {
    final provider = Provider.of<TransitProvider>(context, listen: false);
    setState(() {
      _searchResults = provider.stops
          .where((stop) => stop.stopName.toLowerCase().contains(query.toLowerCase()))
          .take(20)
          .toList();
    });
  }
}

class _TripDetailsSheet extends StatelessWidget {
  final TripPlan plan;

  const _TripDetailsSheet({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Trip Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Trip summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blue),
                      const SizedBox(height: 4),
                      Text('${plan.duration.inMinutes} min'),
                      const Text('Duration', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.currency_rupee, color: Colors.green),
                      const SizedBox(height: 4),
                      Text('₹${plan.totalFare.toStringAsFixed(0)}'),
                      const Text('Total Fare', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.transfer_within_a_station, color: Colors.orange),
                      const SizedBox(height: 4),
                      Text('${plan.transferCount}'),
                      const Text('Transfers', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.directions_walk, color: Colors.grey),
                      const SizedBox(height: 4),
                      Text('${plan.walkingDistance.toStringAsFixed(1)} km'),
                      const Text('Walking', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Step by Step',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView.builder(
              itemCount: plan.legs.length,
              itemBuilder: (context, index) {
                final leg = plan.legs[index];
                final isLast = index == plan.legs.length - 1;
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getLegColor(leg.mode),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getLegIcon(leg.mode),
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('HH:mm').format(leg.startTime)} - ${DateFormat('HH:mm').format(leg.endTime)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${leg.from} → ${leg.to}'),
                          if (leg.route != null)
                            Text(
                              leg.route!.routeShortName,
                              style: TextStyle(
                                color: leg.route!.isAMTS ? Colors.blue : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Save trip
                  },
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save Trip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start navigation
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLegColor(String mode) {
    switch (mode) {
      case 'WALK':
        return Colors.grey;
      case 'BUS':
        return Colors.blue;
      case 'BRT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getLegIcon(String mode) {
    switch (mode) {
      case 'WALK':
        return Icons.directions_walk;
      case 'BUS':
        return Icons.directions_bus;
      case 'BRT':
        return Icons.train;
      default:
        return Icons.help;
    }
  }
} 