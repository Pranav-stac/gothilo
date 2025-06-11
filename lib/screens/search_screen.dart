import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/transit_provider.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../constants/app_constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _speechEnabled = false;
  bool _isListening = false;
  String _searchType = 'all'; // all, routes, stops
  String _selectedAgency = 'all'; // all, amts, brts
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initSpeech();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _loadRecentSearches() {
    // Load from shared preferences
    _recentSearches = [
      'AMTS Route 1',
      'Paldi Bus Stop',
      'BRTS Station',
      'Maninagar',
      'Route 101',
    ];
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            if (result.finalResult) {
              _performSearch(result.recognizedWords);
            }
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    final provider = Provider.of<TransitProvider>(context, listen: false);
    
    // Add to recent searches
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    }
    
    // Perform search based on type
    switch (_searchType) {
      case 'routes':
        provider.searchRoutes(query);
        break;
      case 'stops':
        provider.searchStops(query);
        break;
      default:
        provider.searchRoutes(query);
        provider.searchStops(query);
    }
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
                  'Search Transit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppConstants.generalImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
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
                    Tab(text: 'All'),
                    Tab(text: 'Routes'),
                    Tab(text: 'Stops'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar with Voice
                    Card(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search routes, stops, or destinations...',
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              onChanged: _performSearch,
                              onSubmitted: _performSearch,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              onPressed: _speechEnabled
                                  ? (_isListening ? _stopListening : _startListening)
                                  : null,
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening 
                                    ? Colors.red 
                                    : (_speechEnabled ? Colors.blue : Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: 'All',
                            isSelected: _searchType == 'all',
                            onSelected: () {
                              setState(() {
                                _searchType = 'all';
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'Routes',
                            isSelected: _searchType == 'routes',
                            onSelected: () {
                              setState(() {
                                _searchType = 'routes';
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'Stops',
                            isSelected: _searchType == 'stops',
                            onSelected: () {
                              setState(() {
                                _searchType = 'stops';
                              });
                              _performSearch(_searchController.text);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Agency Filter
                    Row(
                      children: [
                        Expanded(
                          child: _FilterChip(
                            label: 'All Agencies',
                            isSelected: _selectedAgency == 'all',
                            onSelected: () {
                              setState(() {
                                _selectedAgency = 'all';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'AMTS',
                            isSelected: _selectedAgency == 'amts',
                            color: Colors.blue,
                            onSelected: () {
                              setState(() {
                                _selectedAgency = 'amts';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterChip(
                            label: 'BRTS',
                            isSelected: _selectedAgency == 'brts',
                            color: Colors.orange,
                            onSelected: () {
                              setState(() {
                                _selectedAgency = 'brts';
                              });
                            },
                          ),
                        ),
                      ],
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
            // All Results
            _buildAllResultsTab(),
            
            // Routes Only
            _buildRoutesTab(),
            
            // Stops Only
            _buildStopsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllResultsTab() {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        if (_searchController.text.isEmpty) {
          return _buildRecentSearches();
        }
        
        final routes = _filterByAgency(provider.searchResults);
        final stops = _filterStopsByAgency(provider.stopSearchResults);
        
        if (routes.isEmpty && stops.isEmpty) {
          return _buildNoResults();
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (routes.isNotEmpty) ...[
              _SectionHeader(
                title: 'Routes',
                count: routes.length,
                icon: Icons.route,
              ),
              ...routes.take(5).map((route) => _RouteCard(
                route: route,
                onTap: () {
                  provider.selectRoute(route);
                  Navigator.pushNamed(context, '/route-detail');
                },
              )),
              if (routes.length > 5)
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  child: Text('View all ${routes.length} routes'),
                ),
              const SizedBox(height: 16),
            ],
            
            if (stops.isNotEmpty) ...[
              _SectionHeader(
                title: 'Stops',
                count: stops.length,
                icon: Icons.location_on,
              ),
              ...stops.take(5).map((stop) => _StopCard(
                stop: stop,
                onTap: () {
                  provider.selectStop(stop);
                  Navigator.pushNamed(context, '/stop-detail');
                },
              )),
              if (stops.length > 5)
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(2);
                  },
                  child: Text('View all ${stops.length} stops'),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoutesTab() {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        if (_searchController.text.isEmpty) {
          return _buildPopularRoutes();
        }
        
        final routes = _filterByAgency(provider.searchResults);
        
        if (routes.isEmpty) {
          return _buildNoResults();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
            return _RouteCard(
              route: route,
              onTap: () {
                provider.selectRoute(route);
                Navigator.pushNamed(context, '/route-detail');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStopsTab() {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        if (_searchController.text.isEmpty) {
          return _buildNearbyStops();
        }
        
        final stops = _filterStopsByAgency(provider.stopSearchResults);
        
        if (stops.isEmpty) {
          return _buildNoResults();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stops.length,
          itemBuilder: (context, index) {
            final stop = stops[index];
            return _StopCard(
              stop: stop,
              onTap: () {
                provider.selectStop(stop);
                Navigator.pushNamed(context, '/stop-detail');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(
          title: 'Recent Searches',
          icon: Icons.history,
        ),
        if (_recentSearches.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No recent searches',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._recentSearches.map((search) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _recentSearches.remove(search);
                });
              },
            ),
            onTap: () {
              _searchController.text = search;
              _performSearch(search);
            },
          )),
      ],
    );
  }

  Widget _buildPopularRoutes() {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        final popularRoutes = provider.routes.take(10).toList();
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: 'Popular Routes',
              icon: Icons.trending_up,
            ),
            ...popularRoutes.map((route) => _RouteCard(
              route: route,
              onTap: () {
                provider.selectRoute(route);
                Navigator.pushNamed(context, '/route-detail');
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildNearbyStops() {
    return Consumer<TransitProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: 'Nearby Stops',
              icon: Icons.near_me,
            ),
            ...provider.nearbyStops.take(10).map((stop) => _StopCard(
              stop: stop,
              onTap: () {
                provider.selectStop(stop);
                Navigator.pushNamed(context, '/stop-detail');
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildNoResults() {
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
                Icons.search_off,
                size: 80,
                color: Colors.grey,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<RouteModel> _filterByAgency(List<RouteModel> routes) {
    if (_selectedAgency == 'all') return routes;
    return routes.where((route) {
      switch (_selectedAgency) {
        case 'amts':
          return route.isAMTS;
        case 'brts':
          return route.isBRTS;
        default:
          return true;
      }
    }).toList();
  }

  List<StopModel> _filterStopsByAgency(List<StopModel> stops) {
    // For now, return all stops as we don't have agency info in stops
    return stops;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: (color ?? Colors.blue).withOpacity(0.2),
      checkmarkColor: color ?? Colors.blue,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: route.isAMTS ? Colors.blue : Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              route.routeShortName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(route.routeName),
        subtitle: Text(route.agencyFullName),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final StopModel stop;
  final VoidCallback onTap;

  const _StopCard({
    required this.stop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
          ),
        ),
        title: Text(stop.stopName),
        subtitle: Text(stop.locationTypeDisplay),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 