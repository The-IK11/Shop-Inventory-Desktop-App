import 'package:flutter/material.dart';
import '../models/sale_history.dart';
import '../services/database_service.dart';

class SoldoutHistoryScreen extends StatefulWidget {
  const SoldoutHistoryScreen({super.key});

  @override
  State<SoldoutHistoryScreen> createState() => _SoldoutHistoryScreenState();
}

class _SoldoutHistoryScreenState extends State<SoldoutHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, Map<String, SaleHistory>> _groupedSales = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesHistory();
  }

  Future<void> _loadSalesHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groupedSales =
          await _databaseService.getSalesHistoryGroupedByDateAndProduct();
      setState(() {
        _groupedSales = groupedSales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sales history: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Delete Previous Data'),
        content: const Text(
          'Are you sure you want to delete all sales history except today\'s data?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteOldHistory();
    }
  }

  Future<void> _deleteOldHistory() async {
    try {
      await _databaseService.deleteOldSalesHistory();
      await _loadSalesHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Previous sales history deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Soldout History',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _groupedSales.isNotEmpty
                      ? _showDeleteConfirmationDialog
                      : null,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Delete Previous All Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groupedSales.isEmpty
                    ? _buildEmptyState()
                    : _buildSalesHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Sales History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sales will appear here when you reduce stock quantities',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistoryList() {
    final sortedDates = _groupedSales.keys.toList()
      ..sort((a, b) {
        // Parse date strings to compare properly (newest first)
        final dateA = DateTime.tryParse(a.split('-').reversed.join('-')) ??
            DateTime.now();
        final dateB = DateTime.tryParse(b.split('-').reversed.join('-')) ??
            DateTime.now();
        return dateB.compareTo(dateA);
      });

    return RefreshIndicator(
      onRefresh: _loadSalesHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final salesMap = _groupedSales[date]!;
          final sales = salesMap.values.toList();
          final totalQuantity =
              sales.fold<int>(0, (sum, sale) => sum + sale.quantitySold);

          return _buildDateSection(date, sales, totalQuantity);
        },
      ),
    );
  }

  Widget _buildDateSection(
      String date, List<SaleHistory> sales, int totalQuantity) {
    final isToday = date ==
        DateTime.now().toString().split(' ')[0].split('-').reversed.join('-');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: isToday
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isToday ? 'Today ($date)' : date,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$totalQuantity items sold',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Sales Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              return _buildSaleItem(sales[index], index == sales.length - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItem(SaleHistory sale, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Product Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.productName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  sale.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Quantity Sold
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${sale.quantitySold}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
