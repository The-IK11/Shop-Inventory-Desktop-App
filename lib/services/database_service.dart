import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import 'settings_service.dart';
import 'notification_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'products';

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
      version: 1,
      onCreate: _createDatabase,
    );
  }

  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        status TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Insert some sample data
    await _insertSampleData(db);
  }

  // Insert sample data for testing
  Future<void> _insertSampleData(Database db) async {
    final sampleProducts = [
      {
        'name': 'Makina dorman pss',
        'category': 'Makina',
        'quantity': 10,
        'status': 'Low Stock',
        'lastUpdated': DateTime(2024, 4, 24).toIso8601String(),
      },
      {
        'name': 'Makina italy mab asii',
        'category': 'Steel',
        'quantity': 500,
        'status': 'In Stock',
        'lastUpdated': DateTime(2024, 4, 23).toIso8601String(),
      },
      {
        'name': 'Steel 4c pss',
        'category': 'Steel',
        'quantity': 100,
        'status': 'In Stock',
        'lastUpdated': DateTime(2024, 4, 22).toIso8601String(),
      },
      {
        'name': 'Steel 4c black',
        'category': 'Other',
        'quantity': 0,
        'status': 'Out of Stock',
        'lastUpdated': DateTime(2024, 4, 21).toIso8601String(),
      },
      {
        'name': 'All dorman pss',
        'category': 'Makina',
        'quantity': 200,
        'status': 'In Stock',
        'lastUpdated': DateTime(2024, 4, 20).toIso8601String(),
      },
      {
        'name': 'Keilon dorman pss',
        'category': 'Steel',
        'quantity': 0,
        'status': 'Out of Stock',
        'lastUpdated': DateTime(2024, 4, 20).toIso8601String(),
      },
      {
        'name': 'Hapja dorman pss',
        'category': 'Other',
        'quantity': 5,
        'status': 'Low Stock',
        'lastUpdated': DateTime(2024, 4, 20).toIso8601String(),
      },
      {
        'name': 'Premium Steel Rod',
        'category': 'Steel',
        'quantity': 0,
        'status': 'Out of Stock',
        'lastUpdated': DateTime(2024, 4, 19).toIso8601String(),
      },
    ];

    for (var product in sampleProducts) {
      await db.insert(_tableName, product);
    }
  }

  // Insert a new product
  Future<int> insertProduct(Product product) async {
    final db = await database;
    final result = await db.insert(_tableName, product.toMap());

    // Check if the new product should trigger a notification
    final threshold = await SettingsService.getLowStockThreshold();
    await _checkAndSendNotifications(
        product.name, threshold + 1, product.quantity, threshold);

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
        final threshold = await SettingsService.getLowStockThreshold();
        await _checkAndSendNotifications(
            product.name, oldProduct.quantity, product.quantity, threshold);
      }
    }

    return result;
  }

  // Update product quantity
  Future<int> updateProductQuantity(int id, int newQuantity) async {
    final db = await database;
    final threshold = await SettingsService.getLowStockThreshold();

    // Get the product details for notifications
    final productList = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (productList.isEmpty) return 0;

    final product = Product.fromMap(productList.first);
    final oldQuantity = product.quantity;

    // Automatically update status based on quantity
    String newStatus;
    if (newQuantity <= 0) {
      newStatus = 'Out of Stock';
    } else if (newQuantity <= threshold) {
      newStatus = 'Low Stock';
    } else {
      newStatus = 'In Stock';
    }

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

    // Send notifications based on the new status
    await _checkAndSendNotifications(
        product.name, oldQuantity, newQuantity, threshold);

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

  // Get low stock products (quantity <= 10)
  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final threshold = await SettingsService.getLowStockThreshold();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'quantity <= ?',
      whereArgs: [threshold],
      orderBy: 'quantity ASC',
    );

    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Recalculate all product statuses based on current quantity
  Future<void> recalculateAllStatuses() async {
    final db = await database;
    final products = await getAllProducts();
    final threshold = await SettingsService.getLowStockThreshold();

    for (final product in products) {
      String newStatus;
      if (product.quantity <= 0) {
        newStatus = 'Out of Stock';
      } else if (product.quantity <= threshold) {
        newStatus = 'Low Stock';
      } else {
        newStatus = 'In Stock';
      }

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

  // Close database
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
