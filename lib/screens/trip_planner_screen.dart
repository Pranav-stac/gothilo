import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../models/stop_model.dart';
import '../models/route_model.dart';
import '../constants/app_constants.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  StopModel? _fromStop;
  StopModel? _toStop;
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isSearching = false;
  bool _hasSearched = false;
  List<RouteModel> _foundRoutes = [];
  
  @override
  void initState() {
    super.initState();
    
    // Ensure stops are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransitProvider>(context, listen: false);
      if (provider.stops.isEmpty) {
        provider.loadStops();
      }
    });
  }
  
  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Trip'),
      ),
      body: Consumer<TransitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
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
                    onPressed: () => provider.loadStops(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Origin and Destination Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // From field
                        TextField(
                          controller: _fromController,
                          decoration: const InputDecoration(
                            labelText: 'From',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.trip_origin),
                          ),
                          readOnly: true,
                          onTap: () => _selectStop(true),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // To field
                        TextField(
                          controller: _toController,
                          decoration: const InputDecoration(
                            labelText: 'To',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.place),
                          ),
                          readOnly: true,
                          onTap: () => _selectStop(false),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Swap button
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _swapLocations,
                            icon: const Icon(Icons.swap_vert),
                            label: const Text('Swap'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Time selection card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Departure Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        InkWell(
                          onTap: _selectTimeDialog,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 16),
                                Text(
                                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Plan Trip Button
                ElevatedButton.icon(
                  onPressed: _isSearching ? null : () => _planTrip(provider),
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.directions),
                  label: Text(_isSearching ? 'Searching...' : 'Plan Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Results
                if (_hasSearched) ...[
                  const Text(
                    'Trip Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isSearching)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Finding the best routes...'),
                        ],
                      ),
                    )
                  else if (_foundRoutes.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.wrong_location,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No routes found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try selecting different stops or departure time',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _foundRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _foundRoutes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(int.parse('0xFF${route.color}')),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  route.routeShortName,
                                  style: TextStyle(
                                    color: Color(int.parse('0xFF${route.textColor}')),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              route.routeName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(route.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Departure: ${_selectedTime.format(context)} • Est. arrival: ${_getEstimatedArrival(route).format(context)}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Consumer<TransitProvider>(
                                  builder: (context, provider, child) {
                                    // Find fare for this route's agency
                                    final fare = provider.fares
                                        .where((f) => f.agencyId.isEmpty || 
                                                    f.agencyId.toLowerCase() == route.agency.toLowerCase())
                                        .firstOrNull;
                                    
                                    if (fare == null) {
                                      return const SizedBox.shrink();
                                    }
                                    
                                    return Row(
                                      children: [
                                        Icon(Icons.payments_outlined, 
                                          size: 14, 
                                          color: Colors.green[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Fare: ${fare.formattedPrice}',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              provider.selectRoute(route);
                              Navigator.pushNamed(context, '/route-detail');
                            },
                          ),
                        );
                      },
                    ),
                ]
                else if (_fromStop == null || _toStop == null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'How to Plan a Trip',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Select your origin stop\n'
                            '2. Select your destination stop\n'
                            '3. Choose your departure time\n'
                            '4. Tap "Plan Trip" to find routes',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _selectStop(bool isFrom) async {
    final provider = Provider.of<TransitProvider>(context, listen: false);
    
    if (provider.stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading stops... Please try again in a moment.'),
        ),
      );
      provider.loadStops();
      return;
    }
    
    // Show stop selection dialog
    final result = await showDialog<StopModel>(
      context: context,
      builder: (context) {
        final searchController = TextEditingController();
        List<StopModel> filteredStops = provider.stops;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isFrom ? 'Select Origin Stop' : 'Select Destination Stop'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search stops...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            filteredStops = provider.stops;
                          } else {
                            filteredStops = provider.stops
                                .where((stop) => stop.stopName
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredStops.length,
                        itemBuilder: (context, index) {
                          final stop = filteredStops[index];
                          return ListTile(
                            title: Text(stop.stopName),
                            subtitle: Text(stop.description.isNotEmpty 
                                ? stop.description 
                                : 'Stop ID: ${stop.stopId}'),
                            onTap: () {
                              Navigator.of(context).pop(stop);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
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
        
        // Reset search results when stops change
        _hasSearched = false;
        _foundRoutes = [];
      });
    }
  }
  
  void _swapLocations() {
    setState(() {
      final tempStop = _fromStop;
      _fromStop = _toStop;
      _toStop = tempStop;
      
      final tempText = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tempText;
      
      // Reset search results when stops change
      _hasSearched = false;
      _foundRoutes = [];
    });
  }
  
  void _selectTimeDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        
        // Reset search results when time changes
        _hasSearched = false;
        _foundRoutes = [];
      });
    }
  }
  
  void _planTrip(TransitProvider provider) async {
    if (_fromStop == null || _toStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both origin and destination stops'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _foundRoutes = [];
    });
    
    try {
      // Make sure routes are loaded
      if (provider.routes.isEmpty) {
        print('Loading routes first...');
        await provider.loadRoutes();
      }
      
      // Make sure fares are loaded
      if (provider.fares.isEmpty) {
        print('Loading fares...');
        await provider.loadFares();
      }
      
      // Find routes that might connect these stops
      final routes = await _findRoutesBetweenStops(provider, _fromStop!, _toStop!);
      
      setState(() {
        _isSearching = false;
        _foundRoutes = routes;
      });
    } catch (e) {
      print('Error planning trip: $e');
      setState(() {
        _isSearching = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error planning trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<List<RouteModel>> _findRoutesBetweenStops(
    TransitProvider provider,
    StopModel fromStop,
    StopModel toStop,
  ) async {
    List<RouteModel> result = [];
    
    // Calculate distance between stops
    final distance = fromStop.distanceTo(toStop.latitude, toStop.longitude);
    print('Distance between stops: ${distance.toStringAsFixed(2)} km');
    
    // For short distances (under 5km), just suggest the first 3 routes
    // This avoids excessive database queries
    if (distance < 5.0) {
      print('Short distance detected. Suggesting popular routes instead of querying database');
      // Take first 3 routes as suggestions
      if (provider.routes.isNotEmpty) {
        final suggestedRoutes = provider.routes.take(3).toList();
        return suggestedRoutes;
      }
    }
    
    // For longer distances, only check the first 5 routes to save resources
    final routesToCheck = provider.routes.take(5).toList();
    print('Checking ${routesToCheck.length} routes for longer distance trip');
    
    for (final route in routesToCheck) {
      try {
        // Simple name-based matching without loading all stops
        // This avoids expensive database queries for each route
        if (_isLikelyRouteMatch(route, fromStop, toStop)) {
          result.add(route);
        }
      } catch (e) {
        print('Error checking route ${route.routeId}: $e');
      }
    }
    
    // If no routes found, add some routes as suggestions
    if (result.isEmpty && provider.routes.isNotEmpty) {
      // Add up to 2 routes as suggestions
      final suggestedRoutes = provider.routes.take(2).toList();
      result.addAll(suggestedRoutes);
    }
    
    return result;
  }
  
  // Simple heuristic to check if a route is likely to connect two stops
  // This avoids expensive database queries
  bool _isLikelyRouteMatch(RouteModel route, StopModel fromStop, StopModel toStop) {
    // Check if route name or description contains stop names
    final routeText = '${route.routeName} ${route.description} ${route.routeLongName}'.toLowerCase();
    final fromStopName = fromStop.stopName.toLowerCase();
    final toStopName = toStop.stopName.toLowerCase();
    
    // Extract key parts of stop names (first word or two)
    final fromKeyPart = _getKeyPartOfName(fromStopName);
    final toKeyPart = _getKeyPartOfName(toStopName);
    
    // Route is likely to connect stops if its description contains parts of both stop names
    // or if it's a major route (indicated by short route number)
    bool isLikelyMatch = (routeText.contains(fromKeyPart) || routeText.contains(toKeyPart)) || 
                         (route.routeShortName.length <= 3);
    
    return isLikelyMatch;
  }
  
  // Extract key part of a stop name (first word or two)
  String _getKeyPartOfName(String name) {
    final parts = name.split(' ');
    if (parts.length <= 2) return name;
    return '${parts[0]} ${parts[1]}';
  }
  
  TimeOfDay _getEstimatedArrival(RouteModel route) {
    // Simple estimation: add 30-60 minutes based on route
    final int minutesToAdd = 30 + (route.routeId.hashCode % 30);
    final int totalMinutes = _selectedTime.hour * 60 + _selectedTime.minute + minutesToAdd;
    final int arrivalHour = (totalMinutes ~/ 60) % 24;
    final int arrivalMinute = totalMinutes % 60;
    return TimeOfDay(hour: arrivalHour, minute: arrivalMinute);
  }
} 