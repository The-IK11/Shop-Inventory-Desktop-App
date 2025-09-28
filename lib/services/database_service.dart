import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale_history.dart';
import 'notification_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'products';
  static const String _salesTableName = 'sale_history';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Initialize database factory for desktop platforms
  static Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize the ffi loader for desktop platforms
      sqfliteFfiInit();
      // Set the database factory for sqflite
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Ensure initialization is complete
    await initialize();
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'shop_inventory.db');

    return await openDatabase(
      path,
      version: 3, // Increased version for lowStockThreshold column
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        status TEXT NOT NULL,
        lastUpdated TEXT NOT NULL,
        lowStockThreshold INTEGER
      )
    ''');

    // Create sales history table
    await db.execute('''
      CREATE TABLE $_salesTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productName TEXT NOT NULL,
        category TEXT NOT NULL,
        quantitySold INTEGER NOT NULL,
        saleDate TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add sales history table in version 2
      await db.execute('''
        CREATE TABLE $_salesTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productName TEXT NOT NULL,
          category TEXT NOT NULL,
          quantitySold INTEGER NOT NULL,
          saleDate TEXT NOT NULL,
          notes TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add lowStockThreshold column in version 3
      await db.execute('''
        ALTER TABLE $_tableName ADD COLUMN lowStockThreshold INTEGER
      ''');
    }
  }

  // Insert a new product
  Future<int> insertProduct(Product product) async {
    final db = await database;
    final result = await db.insert(_tableName, product.toMap());

    // Check if the new product should trigger a notification using individual threshold
    final effectiveThreshold = getEffectiveThreshold(product);
    await _checkAndSendNotifications(product.name, effectiveThreshold + 1,
        product.quantity, effectiveThreshold);

    return result;
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'lastUpdated DESC',
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Search products by name
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'lastUpdated DESC',
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'lastUpdated DESC',
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Get products by status
  Future<List<Product>> getProductsByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'lastUpdated DESC',
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Update a product
  Future<int> updateProduct(Product product) async {
    final db = await database;

    // Get the old product details for notifications
    final oldProductList = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [product.id],
    );

    final result = await db.update(
      _tableName,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    // Check if quantity changed and send notifications if needed
    if (oldProductList.isNotEmpty) {
      final oldProduct = Product.fromMap(oldProductList.first);
      if (oldProduct.quantity != product.quantity) {
        final threshold = getEffectiveThreshold(product);
        await _checkAndSendNotifications(
            product.name, oldProduct.quantity, product.quantity, threshold);
      }
    }

    return result;
  }

  // Update product quantity
  Future<int> updateProductQuantity(int id, int newQuantity) async {
    final db = await database;

    // Get the product details for notifications
    final productList = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (productList.isEmpty) return 0;

    final product = Product.fromMap(productList.first);
    final oldQuantity = product.quantity;
    final effectiveThreshold = getEffectiveThreshold(product);

    // Automatically update status based on quantity and individual threshold
    final newStatus =
        getProductStatus(newQuantity, customThreshold: effectiveThreshold);

    final result = await db.update(
      _tableName,
      {
        'quantity': newQuantity,
        'status': newStatus,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Send notifications based on the new status using individual threshold
    await _checkAndSendNotifications(
        product.name, oldQuantity, newQuantity, effectiveThreshold);

    return result;
  }

  // Update product status
  Future<int> updateProductStatus(int id, String newStatus) async {
    final db = await database;
    return await db.update(
      _tableName,
      {
        'status': newStatus,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a product
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get product count
  Future<int> getProductCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get total quantity of all products
  Future<int> getTotalQuantity() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(quantity) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get low stock products (uses individual thresholds)
  Future<List<Product>> getLowStockProducts() async {
    // Get all products and check them individually using their own thresholds
    final allProducts = await getAllProducts();
    final lowStockProducts = <Product>[];

    for (final product in allProducts) {
      // Only check products that have individual low stock thresholds set
      if (product.lowStockThreshold != null) {
        if (product.quantity <= product.lowStockThreshold! &&
            product.quantity > 0) {
          lowStockProducts.add(product);
        }
      }
    }

    // Sort by quantity ascending
    lowStockProducts.sort((a, b) => a.quantity.compareTo(b.quantity));

    return lowStockProducts;
  }

  // Get effective low stock threshold for a product (individual or default 10)
  int getEffectiveThreshold(Product product) {
    return product.lowStockThreshold ?? 10; // Default to 10 if not set
  }

  // Get status based on quantity and individual threshold
  String getProductStatus(int quantity, {int? customThreshold}) {
    if (quantity <= 0) {
      return 'Out of Stock';
    } else if (customThreshold != null && quantity <= customThreshold) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  // Recalculate all product statuses based on current quantity and individual thresholds
  Future<void> recalculateAllStatuses() async {
    final db = await database;
    final products = await getAllProducts();

    for (final product in products) {
      final threshold = getEffectiveThreshold(product);
      final newStatus =
          getProductStatus(product.quantity, customThreshold: threshold);

      if (newStatus != product.status) {
        await db.update(
          _tableName,
          {
            'status': newStatus,
            'lastUpdated': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [product.id],
        );
      }
    }
  }

  // Helper method to check and send notifications
  Future<void> _checkAndSendNotifications(String productName, int oldQuantity,
      int newQuantity, int threshold) async {
    try {
      // Send notification if product just became out of stock
      if (oldQuantity > 0 && newQuantity <= 0) {
        await NotificationService.showOutOfStockNotification(
          productName: productName,
        );
      }
      // Send notification if product just became low stock
      else if (oldQuantity > threshold &&
          newQuantity <= threshold &&
          newQuantity > 0) {
        await NotificationService.showLowStockNotification(
          productName: productName,
          currentQuantity: newQuantity,
          threshold: threshold,
        );
      }
      // Cancel notifications if product is back in stock
      else if (oldQuantity <= threshold && newQuantity > threshold) {
        await NotificationService.cancelProductNotifications(productName);
      }
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error sending notification: $e');
    }
  }

  // SALES HISTORY METHODS

  // Record a sale when quantity is reduced
  Future<int> recordSale({
    required String productName,
    required String category,
    required int quantitySold,
    String notes = '',
  }) async {
    try {
      final db = await database;
      final saleHistory = SaleHistory(
        productName: productName,
        category: category,
        quantitySold: quantitySold,
        saleDate: DateTime.now(),
        notes: notes,
      );

      return await db.insert(_salesTableName, saleHistory.toMap());
    } catch (e) {
      debugPrint('Error recording sale: $e');
      return 0; // Return 0 if insertion fails
    }
  }

  // Get all sales history
  Future<List<SaleHistory>> getAllSalesHistory() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _salesTableName,
        orderBy: 'saleDate DESC',
      );

      return List.generate(maps.length, (i) {
        return SaleHistory.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error getting sales history: $e');
      return []; // Return empty list if table doesn't exist yet
    }
  }

  // Get sales history for a specific date
  Future<List<SaleHistory>> getSalesHistoryByDate(DateTime date) async {
    final db = await database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      _salesTableName,
      where: 'saleDate >= ? AND saleDate < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'saleDate DESC',
    );

    return List.generate(maps.length, (i) {
      return SaleHistory.fromMap(maps[i]);
    });
  }

  // Get sales history grouped by date and product (consolidated)
  Future<Map<String, Map<String, SaleHistory>>>
      getSalesHistoryGroupedByDateAndProduct() async {
    try {
      final allSales = await getAllSalesHistory();
      final Map<String, Map<String, SaleHistory>> groupedSales = {};

      for (final sale in allSales) {
        final dateKey = sale.formattedDate;
        final productKey = '${sale.productName}_${sale.category}';

        if (!groupedSales.containsKey(dateKey)) {
          groupedSales[dateKey] = {};
        }

        if (!groupedSales[dateKey]!.containsKey(productKey)) {
          // First entry for this product on this date
          groupedSales[dateKey]![productKey] = sale;
        } else {
          // Combine with existing entry for this product on this date
          final existing = groupedSales[dateKey]![productKey]!;
          groupedSales[dateKey]![productKey] = existing.copyWith(
            quantitySold: existing.quantitySold + sale.quantitySold,
          );
        }
      }

      return groupedSales;
    } catch (e) {
      debugPrint('Error grouping sales history: $e');
      return {}; // Return empty map if there's an error
    }
  }

  // Delete sales history except for today
  Future<int> deleteOldSalesHistory() async {
    final db = await database;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return await db.delete(
      _salesTableName,
      where: 'saleDate < ?',
      whereArgs: [startOfToday.toIso8601String()],
    );
  }

  // Delete specific sale history record
  Future<int> deleteSaleHistory(int id) async {
    final db = await database;
    return await db.delete(
      _salesTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total sales count for today
  Future<int> getTodaySalesCount() async {
    final todaySales = await getSalesHistoryByDate(DateTime.now());
    return todaySales.fold<int>(0, (sum, sale) => sum + sale.quantitySold);
  }

  // Get total sales count for a specific date
  Future<int> getSalesCountByDate(DateTime date) async {
    final dateSales = await getSalesHistoryByDate(date);
    return dateSales.fold<int>(0, (sum, sale) => sum + sale.quantitySold);
  }

  // Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
