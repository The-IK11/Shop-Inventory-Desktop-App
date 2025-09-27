import 'package:flutter/material.dart';
import 'dart:async';
import 'stock_in_screen.dart';
import 'dashboard_screen.dart';
import 'stock_out_screen.dart';
import 'reports_screen.dart';
import 'soldout_history_screen.dart';
import 'settings_screen.dart';
import '../services/settings_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Start with Stock In screen
  String _shopName = 'Shop Inventory'; // Default name
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadShopName();
    // Refresh shop name every 2 seconds to catch changes from settings
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadShopName();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh shop name when dependencies change
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    try {
      final shopName = await SettingsService.getShopName();
      setState(() {
        _shopName = shopName;
      });
    } catch (e) {
      // Keep default name if error occurs
      setState(() {
        _shopName = 'Shop Inventory';
      });
    }
  }

  List<Widget> get _screens => [
        DashboardScreen(onNavigate: _navigateToScreen),
        const StockInScreen(),
        const StockOutScreen(),
        const ReportsScreen(),
        const SoldoutHistoryScreen(),
        const SettingsScreen(),
      ];

  void _navigateToScreen(int index) {
    // Refresh shop name when leaving settings
    if (_selectedIndex == 5 && index != 5) {
      // Leaving settings screen
      _loadShopName();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.arrow_downward,
      label: 'Stock In',
      route: '/stock-in',
    ),
    NavigationItem(
      icon: Icons.arrow_upward,
      label: 'Stock Out',
      route: '/stock-out',
    ),
    NavigationItem(
      icon: Icons.assessment,
      label: 'Reports',
      route: '/reports',
    ),
    NavigationItem(
      icon: Icons.history,
      label: 'Soldout History',
      route: '/soldout-history',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  color: Theme.of(context).colorScheme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shopName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = index == _selectedIndex;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.white,
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
