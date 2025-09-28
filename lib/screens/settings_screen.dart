import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  String _shopName = SettingsService.defaultShopName;
  bool _isDarkTheme = false;
  bool _notificationsEnabled = true;
  String _notificationReminderInterval =
      SettingsService.defaultNotificationReminder;
  List<String> _categories = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shopName = await SettingsService.getShopName();
      final isDarkTheme = await SettingsService.isDarkTheme();
      final notificationsEnabled =
          await SettingsService.areNotificationsEnabled();
      final notificationReminderInterval =
          await SettingsService.getNotificationReminderInterval();
      final categories = await SettingsService.getCategories();

      setState(() {
        _shopName = shopName;
        _isDarkTheme = isDarkTheme;
        _notificationsEnabled = notificationsEnabled;
        _notificationReminderInterval = notificationReminderInterval;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App Settings Section
                  _buildSection(
                    title: 'App Settings',
                    children: [
                      _buildShopNameSetting(),
                      const SizedBox(height: 16),
                      _buildThemeSetting(),
                      const SizedBox(height: 16),
                      _buildNotificationSetting(),
                      if (_notificationsEnabled) ...[
                        const SizedBox(height: 8),
                        _buildNotificationReminderSetting(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Inventory Settings Section
                  _buildSection(
                    title: 'Inventory Settings',
                    children: [
                      _buildCategoryManagement(),
                    ],
                  ),
                  // const SizedBox(height: 32),

                  // // Notification Testing Section
                  // _buildSection(
                  //   title: 'Notification Testing',
                  //   children: [
                  //     _buildTestNotificationButton(),
                  //   ],
                  // ),
                  const SizedBox(height: 32),

                  // Data Management Section
                  _buildSection(
                    title: 'Data Management',
                    children: [
                      _buildResetDataButton(),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildShopNameSetting() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
      title: const Text('Shop Name'),
      subtitle: Text(_shopName),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: _editShopName,
      ),
    );
  }

  Widget _buildThemeSetting() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Theme'),
      subtitle: Text(_isDarkTheme ? 'Dark Theme' : 'Light Theme'),
      trailing: Switch(
        value: _isDarkTheme,
        onChanged: _toggleTheme,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationSetting() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _notificationsEnabled ? Icons.notifications : Icons.notifications_off,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Notifications'),
      subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
      trailing: Switch(
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationReminderSetting() {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.schedule,
            color: Theme.of(context).colorScheme.primary, size: 20),
        title: const Text('Reminder Frequency', style: TextStyle(fontSize: 14)),
        subtitle: Text(_notificationReminderInterval,
            style: const TextStyle(fontSize: 12)),
        trailing: DropdownButton<String>(
          value: _notificationReminderInterval,
          underline: Container(),
          items: const [
            DropdownMenuItem(value: '15 Minutes', child: Text('15 Minutes')),
            DropdownMenuItem(value: '1 Hour', child: Text('1 Hour')),
            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
          ],
          onChanged: _onNotificationReminderChanged,
        ),
      ),
    );
  }

  Widget _buildCategoryManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.category, color: Color(0xFF4A90E2)),
          title: const Text('Manage Categories'),
          subtitle: Text('${_categories.length} categories'),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCategory,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories
              .map((category) => _buildCategoryChip(category))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    return Chip(
      label: Text(category),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _removeCategory(category),
      backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
      deleteIconColor: Colors.red,
    );
  }

  Widget _buildResetDataButton() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Reset All Data'),
      subtitle: const Text('Delete all products and reset the database'),
      trailing: ElevatedButton(
        onPressed: _showResetConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Reset'),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.notifications_active,
              color: Theme.of(context).colorScheme.primary),
          title: const Text('Test Notifications'),
          subtitle:
              const Text('Send a test notification to verify functionality'),
          trailing: ElevatedButton(
            onPressed: _testNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Test'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.inventory,
                color: Theme.of(context).colorScheme.primary, size: 20),
            title: const Text('Test Inventory Summary',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Send inventory status notification',
                style: TextStyle(fontSize: 12)),
            trailing: ElevatedButton(
              onPressed: _testInventorySummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              child: const Text('Test Summary'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editShopName() async {
    final controller = TextEditingController(text: _shopName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shop Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Shop Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await SettingsService.setShopName(result);
      setState(() {
        _shopName = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop name updated successfully')),
        );
      }
    }
  }

  Future<void> _toggleTheme(bool value) async {
    await SettingsService.setDarkTheme(value);
    setState(() {
      _isDarkTheme = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${value ? 'dark' : 'light'} theme'),
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    await SettingsService.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      // Start scheduled notifications when enabled
      NotificationService.scheduleRecurringInventoryNotification();
    } else {
      // Cancel scheduled notifications when disabled
      NotificationService.cancelScheduledNotifications();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifications ${value ? 'enabled' : 'disabled'}'),
        ),
      );
    }
  }

  Future<void> _onNotificationReminderChanged(String? value) async {
    if (value != null && value != _notificationReminderInterval) {
      await SettingsService.setNotificationReminderInterval(value);
      setState(() {
        _notificationReminderInterval = value;
      });

      // Reschedule notifications with new interval
      if (_notificationsEnabled) {
        await NotificationService.cancelScheduledNotifications();
        await NotificationService.scheduleRecurringInventoryNotification();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder frequency set to $value'),
          ),
        );
      }
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && !_categories.contains(result)) {
      await SettingsService.addCategory(result);
      setState(() {
        _categories.add(result);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully')),
        );
      }
    }
  }

  Future<void> _removeCategory(String category) async {
    // Get all products with this category first
    final allProducts = await _databaseService.getAllProducts();
    final productsWithCategory =
        allProducts.where((product) => product.category == category).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove the "$category" category?'),
            if (productsWithCategory.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Warning: ${productsWithCategory.length} product(s) currently use this category. They will be moved to "Other" category.',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update all products that use this category to "Other"
        for (final product in productsWithCategory) {
          final updatedProduct = product.copyWith(category: 'Other');
          await _databaseService.updateProduct(updatedProduct);
        }

        // Ensure "Other" category exists if we moved products to it
        if (productsWithCategory.isNotEmpty && !_categories.contains('Other')) {
          await SettingsService.addCategory('Other');
        }

        // Remove the category from settings
        await SettingsService.removeCategory(category);

        // Update local state
        setState(() {
          _categories.remove(category);
          if (productsWithCategory.isNotEmpty &&
              !_categories.contains('Other')) {
            _categories.add('Other');
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                productsWithCategory.isNotEmpty
                    ? 'Category removed. ${productsWithCategory.length} product(s) moved to "Other" category.'
                    : 'Category removed successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing category: $e')),
          );
        }
      }
    }
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This action will permanently delete:'),
            SizedBox(height: 8),
            Text('• All product data'),
            Text('• All stock in/out records'),
            Text('• All categories'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetAllData();
    }
  }

  Future<void> _resetAllData() async {
    try {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting all data...'),
              ],
            ),
          ),
        );
      }

      // Delete all products from database
      final products = await _databaseService.getAllProducts();
      for (final product in products) {
        await _databaseService.deleteProduct(product.id!);
      }

      // Clear all categories (empty list)
      await SettingsService.setCategories([]);

      // Reload settings
      await _loadSettings();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('All data and categories have been reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting data: $e')),
        );
      }
    }
  }

  Future<void> _testNotifications() async {
    if (!_notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are disabled in settings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Send a test low stock notification
      await NotificationService.showLowStockNotification(
        productName: 'Test Product',
        currentQuantity: 3,
        threshold: 5, // Use a default value for testing
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testInventorySummary() async {
    if (!_notificationsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are disabled in settings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await NotificationService.sendTestInventorySummary();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inventory summary notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send inventory summary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
