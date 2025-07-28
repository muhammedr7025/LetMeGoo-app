// lib/services/notification_test_helper.dart
// Create this file to test notification functionality

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:letmegoo/services/notification_service.dart';

class NotificationTestHelper {
  
  /// Test method to simulate notification tap
  static void simulateNotificationTap() {
    print('🧪 Simulating notification tap...');
    
    // Create a mock RemoteMessage for testing
    final Map<String, dynamic> mockData = {
      'type': 'test',
      'message': 'Test notification',
    };
    
    // Simulate the notification tap handling
    NotificationService.navigateToHomePage();
  }

  /// Get current FCM token for testing
  static Future<void> printFCMToken() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      print('🔑 Current FCM Token: $token');
      
      // You can use this token to send test notifications from Firebase Console
      print('📝 Copy this token to Firebase Console > Cloud Messaging > Send test message');
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Check notification permissions
  static Future<void> checkNotificationPermissions() async {
    try {
      final NotificationSettings settings = 
          await FirebaseMessaging.instance.getNotificationSettings();
      
      print('🔔 Notification Permission Status: ${settings.authorizationStatus}');
      print('📱 Alert Setting: ${settings.alert}');
      print('🔊 Sound Setting: ${settings.sound}');
      print('🔴 Badge Setting: ${settings.badge}');
    } catch (e) {
      print('❌ Error checking permissions: $e');
    }
  }
}

// Add this to any screen for testing (like in a debug button)
/*
ElevatedButton(
  onPressed: () {
    NotificationTestHelper.simulateNotificationTap();
  },
  child: Text('Test Notification Navigation'),
),

ElevatedButton(
  onPressed: () {
    NotificationTestHelper.printFCMToken();
  },  
  child: Text('Print FCM Token'),
),
*/