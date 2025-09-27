import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/main_screen.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database service for desktop platforms
  await DatabaseService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Start scheduled notifications if enabled
  final notificationsEnabled = await SettingsService.areNotificationsEnabled();
  if (notificationsEnabled) {
    await NotificationService.scheduleRecurringInventoryNotification();
  }

  // Recalculate all product statuses to ensure consistency
  final databaseService = DatabaseService();
  await databaseService.recalculateAllStatuses();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _appTitle = 'Shop Inventory';
  bool _isDarkTheme = false;
  Timer? _themeCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
    // Start a timer to check for theme changes every 500ms
    _themeCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkThemeChanges();
    });
  }

  @override
  void dispose() {
    _themeCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppSettings() async {
    final shopName = await SettingsService.getShopName();
    final isDarkTheme = await SettingsService.isDarkTheme();

    setState(() {
      _appTitle = shopName;
      _isDarkTheme = isDarkTheme;
    });
  }

  Future<void> _checkThemeChanges() async {
    final isDarkTheme = await SettingsService.isDarkTheme();
    if (_isDarkTheme != isDarkTheme) {
      setState(() {
        _isDarkTheme = isDarkTheme;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: _isDarkTheme ? _buildDarkTheme() : _buildLightTheme(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A90E2),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A90E2),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }
}
