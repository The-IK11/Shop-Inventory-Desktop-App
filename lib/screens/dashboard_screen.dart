import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/add_product_dialog.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;

  // Statistics data
  int _totalStockInCount = 0;
  int _stockOutCount = 0;
  int _lowStockCount = 0;
  int _totalCategoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all products
      final allProducts = await _databaseService.getAllProducts();

      // Get stock out products (quantity = 0)
      final stockOutProducts =
          allProducts.where((product) => product.quantity == 0).toList();

      // Get low stock products
      final lowStockProducts = await _databaseService.getLowStockProducts();

      // Get unique categories
      final categories = allProducts.map((product) => product.category).toSet();

      // Calculate total stock in count (products with quantity > 0)
      final stockInProducts =
          allProducts.where((product) => product.quantity > 0).toList();

      setState(() {
        _totalStockInCount = stockInProducts.length;
        _stockOutCount = stockOutProducts.length;
        _lowStockCount = lowStockProducts.length;
        _totalCategoryCount = categories.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: _loadDashboardData,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Loading or Statistics Cards
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildStatisticsCards(),

              const SizedBox(height: 32),

              // Additional dashboard content can be added here
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),

        // First row of cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Stock In',
                count: _totalStockInCount,
                icon: Icons.inventory_2,
                color: Colors.green,
                subtitle: 'Products available',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Stock Out',
                count: _stockOutCount,
                icon: Icons.remove_shopping_cart,
                color: Colors.red,
                subtitle: 'Out of stock',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Second row of cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Low Stock',
                count: _lowStockCount,
                icon: Icons.warning,
                color: Colors.orange,
                subtitle: 'Need restocking',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Total Categories',
                count: _totalCategoryCount,
                icon: Icons.category,
                color: Colors.blue,
                subtitle: 'Product categories',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Count
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'View Stock In',
                      icon: Icons.inventory,
                      color: Colors.green,
                      onTap: () => _navigateToStockIn(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'View Stock Out',
                      icon: Icons.remove_shopping_cart,
                      color: Colors.red,
                      onTap: () => _navigateToStockOut(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'View Reports',
                      icon: Icons.analytics,
                      color: Colors.blue,
                      onTap: () => _navigateToReports(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      title: 'Add Product',
                      icon: Icons.add_box,
                      color: Colors.orange,
                      onTap: () => _showAddProductDialog(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStockIn() {
    // Use the callback function if available, otherwise use simple navigation
    if (widget.onNavigate != null) {
      widget.onNavigate!(1); // Stock In screen index
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StockInScreen()),
      );
    }
  }

  void _navigateToStockOut() {
    // Use the callback function if available, otherwise use simple navigation
    if (widget.onNavigate != null) {
      widget.onNavigate!(2); // Stock Out screen index
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StockOutScreen()),
      );
    }
  }

  void _navigateToReports() {
    // Use the callback function if available, otherwise use simple navigation
    if (widget.onNavigate != null) {
      widget.onNavigate!(3); // Reports screen index
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ReportsScreen()),
      );
    }
  }

  void _showAddProductDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddProductDialog(),
    );

    if (result == true) {
      // Refresh dashboard data after adding a product
      _loadDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
