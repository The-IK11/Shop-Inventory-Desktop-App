import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _shopNameKey = 'shop_name';
  static const String _themeKey = 'is_dark_theme';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _lowStockThresholdKey = 'low_stock_threshold';
  static const String _categoriesKey = 'categories';
  static const String _notificationReminderKey =
      'notification_reminder_interval';

  static const String defaultShopName = 'Shop Inventory';
  static const int defaultLowStockThreshold = 10;
  static const String defaultNotificationReminder = 'Daily';

  // Shop Name
  static Future<String> getShopName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_shopNameKey) ?? defaultShopName;
  }

  static Future<void> setShopName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shopNameKey, name);
  }

  // Theme
  static Future<bool> isDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  static Future<void> setDarkTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  // Notifications
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  // Low Stock Threshold
  static Future<int> getLowStockThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lowStockThresholdKey) ?? defaultLowStockThreshold;
  }

  static Future<void> setLowStockThreshold(int threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lowStockThresholdKey, threshold);
  }

  // Categories
  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey) ?? [];
  }

  static Future<void> setCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }

  static Future<void> addCategory(String category) async {
    final categories = await getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await setCategories(categories);
    }
  }

  static Future<void> removeCategory(String category) async {
    final categories = await getCategories();
    categories.remove(category);
    await setCategories(categories);
  }

  // Notification Reminder Interval
  static Future<String> getNotificationReminderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notificationReminderKey) ??
        defaultNotificationReminder;
  }

  static Future<void> setNotificationReminderInterval(String interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationReminderKey, interval);
  }
}
