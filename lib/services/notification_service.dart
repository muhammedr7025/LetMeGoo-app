// lib/services/notification_service.dart - Enhanced version with navigation

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:letmegoo/services/device_service.dart';
import 'package:letmegoo/screens/home_page.dart';
import 'package:letmegoo/widgets/main_app.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _pendingToken;
  static GlobalKey<NavigatorState>? _navigatorKey;

  // Set the navigator key from main.dart
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      // Request permissions first
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Notification permission status: ${settings.authorizationStatus}');

      // Only proceed if authorized
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get initial token but don't update yet
        final token = await _messaging.getToken();
        if (token != null) {
          print('Initial FCM token retrieved: ${token.substring(0, 10)}...');
          _pendingToken = token;
        }

        // Set up token refresh listener
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          print('Token refreshed');
          _handleTokenRefresh(newToken);
        });

        // Set up message handlers
        _setupMessageHandlers();

        // Listen for auth state changes to update token when user logs in
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user != null && _pendingToken != null) {
            print('User authenticated, updating pending token');
            DeviceService.updateDeviceToken(_pendingToken!);
            _pendingToken = null; // Clear after updating
          }
        });
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      // Don't throw - let app continue without notifications
    }
  }

  static void _handleTokenRefresh(String newToken) async {
    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, update immediately
      await DeviceService.updateDeviceToken(newToken);
    } else {
      // User not logged in, store for later
      _pendingToken = newToken;
      print(
        'Token refresh received but user not authenticated, storing for later',
      );
    }
  }

  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      // Handle foreground notifications here
      _handleForegroundMessage(message);
    });

    // Handle background messages (when notification is tapped)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app: ${message.notification?.title}');
      // Handle notification tap here
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification
    _checkInitialMessage();
  }

  static Future<void> _checkInitialMessage() async {
    // Get any messages which caused the application to open from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print(
        'App opened from notification: ${initialMessage.notification?.title}',
      );
      // Delay navigation to ensure app is fully loaded
      Future.delayed(const Duration(milliseconds: 1000), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Handle the message when app is in foreground
    if (message.notification != null) {
      print('Notification Title: ${message.notification!.title}');
      print('Notification Body: ${message.notification!.body}');
    }

    // Handle data payload
    if (message.data.isNotEmpty) {
      print('Message data: ${message.data}');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Handling notification tap...');

    // Always navigate to homepage when notification is tapped
    _navigateToHomePage();

    // Handle specific data if needed
    if (message.data.isNotEmpty) {
      print('Message data: ${message.data}');

      // You can add specific navigation logic here based on data
      final String? type = message.data['type'];
      final String? reportId = message.data['report_id'];

      switch (type) {
        case 'report_status':
          // Could navigate to specific report if needed
          print('Report notification: $reportId');
          break;
        case 'vehicle_reported':
          // Could navigate to specific vehicle report
          print('Vehicle reported: $reportId');
          break;
        default:
          // Default behavior - just go to homepage
          break;
      }
    }
  }

  static void _navigateToHomePage() {
    print('🏠 Navigating to homepage...');

    if (_navigatorKey?.currentContext != null) {
      final BuildContext context = _navigatorKey!.currentContext!;

      // Navigate to HomePage - replace current route with homepage
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (context) => HomePage(
                onNavigate: (index) {
                  // Handle navigation if needed
                  print('Homepage navigation: $index');
                },
                onAddPressed: () {
                  // Handle add button if needed
                  print('Homepage add pressed');
                },
              ),
        ),
        (route) => false, // Remove all previous routes
      );

      print('✅ Navigation to homepage completed');
    } else {
      print('❌ Navigator context not available');

      // Fallback: Try to navigate using a global approach
      _navigateToMainApp();
    }
  }

  static void _navigateToMainApp() {
    print('🔄 Fallback: Navigating to MainApp...');

    if (_navigatorKey?.currentContext != null) {
      final BuildContext context = _navigatorKey!.currentContext!;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainApp()),
        (route) => false,
      );

      print('✅ Navigation to MainApp completed');
    }
  }

  // Method to manually trigger navigation to homepage (for testing)
  static void navigateToHomePage() {
    _navigateToHomePage();
  }
}
