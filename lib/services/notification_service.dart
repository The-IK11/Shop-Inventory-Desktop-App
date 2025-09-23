import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

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
}
