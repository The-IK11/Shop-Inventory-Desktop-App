import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();

  print('Current settings:');
  print('Shop Name: ${prefs.getString('shop_name') ?? 'DEFAULT'}');
  print(
      'Low Stock Threshold: ${prefs.getInt('low_stock_threshold') ?? 'DEFAULT (10)'}');
  print(
      'Is Dark Theme: ${prefs.getBool('is_dark_theme') ?? 'DEFAULT (false)'}');
  print(
      'Notifications: ${prefs.getBool('notifications_enabled') ?? 'DEFAULT (true)'}');
  print(
      'Categories: ${prefs.getStringList('categories') ?? 'DEFAULT (empty)'}');
}
