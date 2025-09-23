import 'package:flutter/material.dart';
import 'stock_in_screen.dart';
import 'dashboard_screen.dart';
import 'stock_out_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Start with Stock In screen

  List<Widget> get _screens => [
        DashboardScreen(onNavigate: _navigateToScreen),
        const StockInScreen(),
        const StockOutScreen(),
        const ReportsScreen(),
        const SettingsScreen(),
      ];

  void _navigateToScreen(int index) {
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
            color: const Color(0xFFF5F5F5),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  color: const Color(0xFF4A90E2),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Inventory',
                        style: TextStyle(
                          color: Colors.white,
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
                                ? const Color(0xFF4A90E2)
                                : Colors.grey[600],
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF4A90E2)
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor:
                              const Color(0xFF4A90E2).withOpacity(0.1),
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
