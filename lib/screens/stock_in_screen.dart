import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../widgets/add_product_dialog.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedFilter =
      'All'; // Filter options: All, Low Stock First, High Stock First

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _databaseService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
      // Reapply current filters after loading
      _filterProducts();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    List<Product> filtered = _products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();

    // Apply sorting filter
    _applySortFilter(filtered);
  }

  void _applySortFilter(List<Product> products) {
    setState(() {
      switch (_selectedFilter) {
        case 'Low Stock First':
          _filteredProducts = products
            ..sort((a, b) => a.quantity.compareTo(b.quantity));
          break;
        case 'High Stock First':
          _filteredProducts = products
            ..sort((a, b) => b.quantity.compareTo(a.quantity));
          break;
        default:
          _filteredProducts = products;
      }
    });
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterProducts();
  }

  Future<void> _showAddProductDialog() async {
    final result = await showDialog<Product>(
      context: context,
      builder: (context) => const AddProductDialog(handleInsertion: false),
    );

    if (result != null) {
      await _addProduct(result);
    }
  }

  Future<void> _addProduct(Product product) async {
    try {
      await _databaseService.insertProduct(product);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  Future<void> _updateQuantity(Product product, int change) async {
    final newQuantity = product.quantity + change;
    if (newQuantity < 0) return;

    try {
      await _databaseService.updateProductQuantity(product.id!, newQuantity);

      // Record sale history if quantity was reduced (change is negative)
      if (change < 0) {
        final quantitySold =
            change.abs(); // Convert negative change to positive quantity sold
        await _databaseService.recordSale(
          productName: product.name,
          category: product.category,
          quantitySold: quantitySold,
          notes: 'Stock reduced from inventory',
        );
      }

      // Update the product in our local lists without reloading everything
      setState(() {
        // Update in main products list
        final productIndex = _products.indexWhere((p) => p.id == product.id);
        if (productIndex != -1) {
          _products[productIndex] = _products[productIndex].copyWith(
            quantity: newQuantity,
            status: _getNewStatus(newQuantity, product),
            lastUpdated: DateTime.now(),
          );
        }

        // Update in filtered products list
        final filteredIndex =
            _filteredProducts.indexWhere((p) => p.id == product.id);
        if (filteredIndex != -1) {
          _filteredProducts[filteredIndex] =
              _filteredProducts[filteredIndex].copyWith(
            quantity: newQuantity,
            status: _getNewStatus(newQuantity, product),
            lastUpdated: DateTime.now(),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  // Helper method to determine status based on quantity
  String _getNewStatus(int quantity, Product product) {
    if (quantity <= 0) {
      return 'Out of Stock';
    } else if (quantity <= (product.lowStockThreshold ?? 10)) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteProduct(product.id!);

        // Remove the product from our local lists without reloading everything
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
          _filteredProducts.removeWhere((p) => p.id == product.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
    }
  }

  Future<void> _showProductUpdateDialog(Product product) async {
    final TextEditingController nameController =
        TextEditingController(text: product.name);
    final TextEditingController quantityController =
        TextEditingController(text: product.quantity.toString());
    final TextEditingController lowStockThresholdController =
        TextEditingController(
            text: (product.lowStockThreshold ?? 10).toString());
    String selectedCategory = product.category;
    String selectedStatus = product.status;

    // Load categories from settings instead of using hardcoded list
    final List<String> categories = await SettingsService.getCategories();

    // If categories is empty, add a default "Other" category
    if (categories.isEmpty) {
      categories.add('Other');
    }

    // If the product's category is not in the available categories, add it
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }

    final List<String> statuses = ['In Stock', 'Low Stock', 'Out of Stock'];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Update Product',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Product Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                    ),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                        value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Quantity Field with Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF4A90E2)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick quantity adjustment buttons
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            final currentValue =
                                int.tryParse(quantityController.text) ?? 0;
                            quantityController.text =
                                (currentValue + 10).toString();
                          },
                          icon:
                              const Icon(Icons.add_circle, color: Colors.green),
                          tooltip: '+10',
                        ),
                        IconButton(
                          onPressed: () {
                            final currentValue =
                                int.tryParse(quantityController.text) ?? 0;
                            final newValue = (currentValue - 10)
                                .clamp(0, double.infinity)
                                .toInt();
                            quantityController.text = newValue.toString();
                          },
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          tooltip: '-10',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                    ),
                  ),
                  items: statuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Low Stock Alert Field
                TextField(
                  controller: lowStockThresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Low Stock Alert (Optional)',
                    hintText: 'Default: 10',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final lowStockThreshold = int.tryParse(
                            lowStockThresholdController.text.trim());
                        final updatedData = {
                          'name': nameController.text.trim(),
                          'category': selectedCategory,
                          'quantity':
                              int.tryParse(quantityController.text) ?? 0,
                          'status': selectedStatus,
                          'lowStockThreshold': lowStockThreshold,
                        };
                        Navigator.of(context).pop(updatedData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update Product'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        final updatedProduct = product.copyWith(
          name: result['name'],
          category: result['category'],
          quantity: result['quantity'],
          status: result['status'],
          lowStockThreshold: result['lowStockThreshold'],
          lastUpdated: DateTime.now(),
        );

        await _databaseService.updateProduct(updatedProduct);

        // Update the product in our local lists without reloading everything
        setState(() {
          // Update in main products list
          final productIndex = _products.indexWhere((p) => p.id == product.id);
          if (productIndex != -1) {
            _products[productIndex] = updatedProduct;
          }

          // Update in filtered products list
          final filteredIndex =
              _filteredProducts.indexWhere((p) => p.id == product.id);
          if (filteredIndex != -1) {
            _filteredProducts[filteredIndex] = updatedProduct;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating product: $e')),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in stock':
        return Colors.green;
      case 'low stock':
        return Colors.orange;
      case 'out of stock':
        return Colors.red;
      default:
        return Colors.grey;
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
            width: double.infinity,
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
                const Text(
                  'Stock In',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Bar and Filter
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon:
                        const Icon(Icons.filter_list, color: Color(0xFF4A90E2)),
                    underline: Container(),
                    hint: const Text('Filter'),
                    items: ['All', 'Low Stock First', 'High Stock First']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _changeFilter(newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Product List
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Quantity',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Last Updated',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              //  color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 120), // Actions column
                      ],
                    ),
                  ),
                  // Table Content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredProducts.isEmpty
                            ? const Center(
                                child: Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  final isLowStock = product.quantity <=
                                      (product.lowStockThreshold ?? 10);

                                  return InkWell(
                                    onTap: () =>
                                        _showProductUpdateDialog(product),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLowStock
                                            ? Colors.red.shade50
                                            : null,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        borderRadius: isLowStock
                                            ? BorderRadius.circular(8)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                // Warning icon for low stock
                                                if (isLowStock) ...[
                                                  Icon(
                                                    Icons.warning,
                                                    color: Colors.red.shade300,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isLowStock
                                                          ? Colors.red.shade700
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              product.category,
                                              style: TextStyle(
                                                color: isLowStock
                                                    ? Colors.red.shade600
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              product.quantity.toString(),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: isLowStock
                                                    ? Colors.red.shade700
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                      _getNewStatus(
                                                          product.quantity,
                                                          product)),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getNewStatus(
                                                      product.quantity,
                                                      product),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              DateFormat('yyyy-MM-dd')
                                                  .format(product.lastUpdated),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isLowStock
                                                    ? Colors.red.shade600
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 120,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      _updateQuantity(
                                                          product, 1),
                                                  icon: const Icon(Icons.add,
                                                      color: Colors.green),
                                                  tooltip: 'Increase quantity',
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _updateQuantity(
                                                          product, -1),
                                                  icon: const Icon(Icons.remove,
                                                      color: Colors.orange),
                                                  tooltip: 'Decrease quantity',
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _deleteProduct(product),
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.red),
                                                  tooltip: 'Delete product',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
