import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../models/route_model.dart';
import '../constants/app_constants.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Ensure routes are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransitProvider>(context, listen: false);
      if (provider.routes.isEmpty) {
        provider.loadRoutes();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'AMTS'),
            Tab(text: 'BRTS'),
          ],
        ),
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
                    onPressed: () => provider.loadRoutes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // AMTS Routes
              _buildRoutesList(provider.amtsRoutes, provider),
              
              // BRTS Routes
              _buildRoutesList(provider.brtsRoutes, provider),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildRoutesList(List<RouteModel> routes, TransitProvider provider) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.route_outlined,
              size: 64,
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
              'Try refreshing or check your connection',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadRoutes(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padding),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
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
            subtitle: Text(route.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              provider.selectRoute(route);
              Navigator.pushNamed(context, '/route-detail');
            },
          ),
        );
      },
    );
  }
} 