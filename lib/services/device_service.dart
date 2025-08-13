import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceService {
  static const String baseUrl = 'https://api.letmegoo.com/api';
  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Register device for push notifications
  static Future<Map<String, dynamic>?> registerDevice() async {
    try {
      // Get Firebase user and token
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No Firebase user found');
      }

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final fcmToken = await _getFCMToken();
      final pushStatus = await _getPushNotificationStatus();

      final requestBody = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'device_model': deviceInfo['model'] ?? 'Unknown',
        'os_version': deviceInfo['version'] ?? 'Unknown',
        'app_version': packageInfo.version,
        'language_code': _getLanguageCode(),
        'push_enabled': pushStatus,
        'device_token': fcmToken ?? '',
      };

      print('Device registration payload: $requestBody');

      final response = await http
          .post(
            Uri.parse('$baseUrl/device/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode(requestBody),
          )
          .timeout(timeoutDuration);

      print('Device registration response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Device registration failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Device registration error: $e');
      rethrow;
    }
  }

  /// Get device information based on platform
  static Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return {
          'model': androidInfo.model,
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return {'model': iosInfo.model, 'version': iosInfo.systemVersion};
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {'model': 'Unknown', 'version': 'Unknown'};
  }

  /// Get FCM token for push notifications
  static Future<String?> _getFCMToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission first
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Check push notification permission status
  static Future<String> _getPushNotificationStatus() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return 'ENABLED';
        case AuthorizationStatus.denied:
          return 'DISABLED';
        default:
          return 'UNKNOWN';
      }
    } catch (e) {
      print('Error checking push notification status: $e');
      return 'UNKNOWN';
    }
  }

  /// Get language code from locale
  static String _getLanguageCode() {
    try {
      final locale = Platform.localeName;
      return locale.split('_')[0].toLowerCase();
    } catch (e) {
      return 'en'; // Default to English
    }
  }

  /// Update device token when FCM token refreshes
  static Future<void> updateDeviceToken(String newToken) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) return;

      final response = await http
          .patch(
            Uri.parse('$baseUrl/device/update-token'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: json.encode({'device_token': newToken}),
          )
          .timeout(timeoutDuration);

      print('Device token update response: ${response.statusCode}');
    } catch (e) {
      print('Error updating device token: $e');
    }
  }

  /// Unregister device (call on logout)
  static Future<void> unregisterDevice() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) return;

      final response = await http
          .delete(
            Uri.parse('$baseUrl/device/unregister'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(timeoutDuration);

      print('Device unregister response: ${response.statusCode}');
    } catch (e) {
      print('Error unregistering device: $e');
    }
  }

  // Add this method to your existing DeviceService class
  static Future<Map<String, dynamic>?> checkDeviceRegistration() async {
    try {
      // Get Firebase user and token
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No Firebase user found');
      }

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // Get FCM token to use as device identifier
      final fcmToken = await _getFCMToken();
      if (fcmToken == null) {
        throw Exception('Failed to get FCM token');
      }

      print('Checking device registration with token: $fcmToken');

      final response = await http
          .get(
            Uri.parse('$baseUrl/device/get/$fcmToken'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(timeoutDuration);

      print('Device check response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Device is registered
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // Device not found/not registered
        return null;
      } else {
        throw Exception(
          'Device check failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Device check error: $e');
      // Return null if check fails - we'll treat it as not registered
      return null;
    }
  }

  /// Check if device is registered and register if not
  static Future<bool> ensureDeviceRegistered() async {
    try {
      // First check if device is already registered
      final deviceData = await checkDeviceRegistration();

      if (deviceData != null) {
        print('Device already registered: ${deviceData['id']}');
        return true;
      }

      print('Device not registered, registering now...');

      // Device not registered, register it
      final registrationResult = await registerDevice();

      if (registrationResult != null) {
        print(
          'Device registered successfully: ${registrationResult['id'] ?? 'unknown'}',
        );
        return true;
      }

      return false;
    } catch (e) {
      print('Error ensuring device registration: $e');
      return false;
    }
  }
}
