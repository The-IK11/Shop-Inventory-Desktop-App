import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import 'dart:async';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _notifications;
  static bool _isInitialized = false;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _notifications = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      );

      await _notifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for notifications
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      _isInitialized = false;
      _notifications = null;
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    if (_notifications == null) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _notifications!.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Show low stock notification
  static Future<void> showLowStockNotification({
    required String productName,
    required int currentQuantity,
    required int threshold,
  }) async {
    try {
      // Ensure notifications are initialized
      if (!_isInitialized || _notifications == null) {
        await initialize();
      }

      // Double check if notifications were successfully initialized
      if (!_isInitialized || _notifications == null) {
        debugPrint(
            'Notifications not available, skipping notification for $productName');
        return;
      }

      // Check if notifications are enabled in settings
      final notificationsEnabled =
          await SettingsService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        debugPrint('Notifications disabled in settings');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'low_stock_channel',
        'Low Stock Alerts',
        channelDescription: 'Notifications for low stock products',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        linux: linuxDetails,
      );

      const title = '⚠️ Low Stock Alert';
      final body =
          '$productName is running low! Only $currentQuantity items left (threshold: $threshold)';

      final notificationId = productName.hashCode;

      await _notifications!.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'low_stock:$productName:$currentQuantity',
      );
      debugPrint('Low stock notification sent for $productName');
    } catch (e) {
      debugPrint('Error sending low stock notification: $e');
    }
  }

  // Show out of stock notification
  static Future<void> showOutOfStockNotification({
    required String productName,
  }) async {
    try {
      // Ensure notifications are initialized
      if (!_isInitialized || _notifications == null) {
        await initialize();
      }

      // Double check if notifications were successfully initialized
      if (!_isInitialized || _notifications == null) {
        debugPrint(
            'Notifications not available, skipping notification for $productName');
        return;
      }

      // Check if notifications are enabled in settings
      final notificationsEnabled =
          await SettingsService.areNotificationsEnabled();
      if (!notificationsEnabled) {
        debugPrint('Notifications disabled in settings');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'out_of_stock_channel',
        'Out of Stock Alerts',
        channelDescription: 'Notifications for out of stock products',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        linux: linuxDetails,
      );

      const title = '🚨 Out of Stock Alert';
      final body = '$productName is completely out of stock!';

      final notificationId = productName.hashCode + 1000000;

      await _notifications!.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'out_of_stock:$productName',
      );
      debugPrint('Out of stock notification sent for $productName');
    } catch (e) {
      debugPrint('Error sending out of stock notification: $e');
    }
  }

  // Cancel notifications for a specific product
  static Future<void> cancelProductNotifications(String productName) async {
    try {
      if (!_isInitialized || _notifications == null) {
        await initialize();
      }

      if (_notifications != null) {
        final lowStockId = productName.hashCode;
        final outOfStockId = productName.hashCode + 1000000;
        await _notifications!.cancel(lowStockId);
        await _notifications!.cancel(outOfStockId);
      }
    } catch (e) {
      debugPrint('Error canceling notifications: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized || _notifications == null) {
        await initialize();
      }

      if (_notifications != null) {
        await _notifications!.cancelAll();
      }
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  // Check if notifications are supported
  static Future<bool> areNotificationsSupported() async {
    try {
      if (_notifications == null) return false;

      return _notifications!.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>() !=
              null ||
          _notifications!.resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>() !=
              null;
    } catch (e) {
      debugPrint('Error checking notification support: $e');
      return false;
    }
  }

  // Schedule recurring inventory summary notifications
  static Future<void> scheduleRecurringInventoryNotification() async {
    try {
      // Ensure proper initialization first
      if (!_isInitialized) {
        await initialize();
      }

      if (!_isInitialized || _notifications == null) {
        debugPrint('Notifications not available, skipping scheduling');
        return;
      }

      // Check if notifications are enabled
      final notificationsEnabled =
          await SettingsService.areNotificationsEnabled();
      if (!notificationsEnabled) return;

      final reminderInterval =
          await SettingsService.getNotificationReminderInterval();

      // Calculate the interval duration
      Duration intervalDuration;
      String intervalText;

      switch (reminderInterval) {
        case '15 Minutes':
          intervalDuration = const Duration(minutes: 15);
          intervalText = 'every 15 minutes';
          break;
        case '1 Hour':
          intervalDuration = const Duration(hours: 1);
          intervalText = 'hourly';
          break;
        case 'Daily':
          intervalDuration = const Duration(hours: 24);
          intervalText = 'daily';
          break;
        case 'Weekly':
          intervalDuration = const Duration(days: 7);
          intervalText = 'weekly';
          break;
        default:
          intervalDuration = const Duration(hours: 24);
          intervalText = 'daily';
      }

      // Schedule the first notification
      await _scheduleNextInventoryNotification(intervalDuration, intervalText);

      debugPrint('Scheduled inventory notifications $intervalText');
    } catch (e) {
      debugPrint('Error scheduling recurring notifications: $e');
    }
  }

  // Schedule the next inventory notification
  static Future<void> _scheduleNextInventoryNotification(
      Duration interval, String intervalText) async {
    try {
      // Use Timer to schedule the next notification
      Timer(interval, () => _sendInventorySummaryNotification());

      debugPrint(
          'Next inventory notification scheduled in ${interval.inMinutes} minutes');
    } catch (e) {
      debugPrint('Error scheduling next inventory notification: $e');
    }
  }

  // Send inventory summary notification with current stats
  static Future<void> _sendInventorySummaryNotification() async {
    try {
      final databaseService = DatabaseService();

      // Get current inventory stats
      final allProducts = await databaseService.getAllProducts();
      final lowStockProducts = await databaseService.getLowStockProducts();

      int stockInCount = 0;
      int stockOutCount = 0;

      for (var product in allProducts) {
        if (product.quantity > 0) {
          stockInCount++;
        } else {
          stockOutCount++;
        }
      }

      final lowStockCount = lowStockProducts.length;

      String summaryText = 'Stock In: $stockInCount products';
      if (stockOutCount > 0) {
        summaryText += ' • Stock Out: $stockOutCount products';
      }
      if (lowStockCount > 0) {
        summaryText += ' • Low Stock: $lowStockCount products';
      }

      const androidDetails = AndroidNotificationDetails(
        'inventory_summary',
        'Inventory Summary',
        channelDescription: 'Periodic inventory status updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications!.show(
        998, // Different ID for summary notifications
        'Inventory Summary',
        summaryText,
        notificationDetails,
        payload: 'inventory_summary',
      );

      // Schedule the next notification
      final reminderInterval =
          await SettingsService.getNotificationReminderInterval();
      Duration intervalDuration;

      switch (reminderInterval) {
        case '15 Minutes':
          intervalDuration = const Duration(minutes: 15);
          break;
        case '1 Hour':
          intervalDuration = const Duration(hours: 1);
          break;
        case 'Daily':
          intervalDuration = const Duration(hours: 24);
          break;
        case 'Weekly':
          intervalDuration = const Duration(days: 7);
          break;
        default:
          intervalDuration = const Duration(hours: 24);
      }

      Timer(intervalDuration, () => _sendInventorySummaryNotification());
    } catch (e) {
      debugPrint('Error sending inventory summary notification: $e');
    }
  }

  // Cancel all scheduled notifications
  static Future<void> cancelScheduledNotifications() async {
    try {
      // Ensure proper initialization first
      if (!_isInitialized) {
        await initialize();
      }

      if (_notifications != null && _isInitialized) {
        await _notifications!.cancelAll();
        debugPrint('Cancelled all scheduled notifications');
      } else {
        debugPrint('Notifications not available, skipping cancel');
      }
    } catch (e) {
      debugPrint('Error cancelling scheduled notifications: $e');
    }
  }

  // Send a test inventory summary notification immediately
  static Future<void> sendTestInventorySummary() async {
    try {
      await _sendInventorySummaryNotification();
      debugPrint('Test inventory summary notification sent');
    } catch (e) {
      debugPrint('Error sending test inventory summary: $e');
    }
  }
}
