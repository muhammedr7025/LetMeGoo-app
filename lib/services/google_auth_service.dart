import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:letmegoo/services/device_service.dart';

class GoogleAuthService {
  // Use a singleton pattern for the GoogleSignIn instance
  // This avoids issues with re-creating the instance.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional: If you need to request additional scopes
    scopes: ['email'],
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initiates the Google Sign-In flow and authenticates with Firebase.
  ///
  /// Returns a [UserCredential] if successful, otherwise returns null.
  /// Handles user cancellation gracefully by returning null without throwing an error.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Existing Google sign-in code...
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (kDebugMode) {
          print('Google Sign In: User cancelled the sign-in process.');
        }
        return null;
      }

      if (kDebugMode) {
        print('Google Sign In: User signed in -> ${googleUser.email}');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (kDebugMode) {
        print('Google Auth: Obtained access and ID tokens.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('Google Auth: Created Firebase credential.');
      }

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (kDebugMode) {
        print(
          'Firebase Auth: User successfully signed in -> ${userCredential.user?.email}',
        );
      }

      // Register device after successful login
      try {
        await DeviceService.registerDevice();
        if (kDebugMode) {
          print('Device registered successfully for push notifications');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Device registration failed: $e');
        }
        // Don't fail the login process if device registration fails
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: [${e.code}] ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('An unexpected error occurred during Google Sign In: $e');
      }
      return null;
    }
  }

  /// Signs the user out from both Firebase and Google.
  /// Signs the user out from both Firebase and Google with enhanced error handling
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('🚪 Starting sign out process...');
      }

      // Step 1: Call logout API (if not already called)
      try {
        // Note: This will be called from AuthService.logout()
        // so we don't need to call it again here to avoid duplication
        if (kDebugMode) {
          print('📡 Logout API call handled by AuthService');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Logout API call skipped or failed: $e');
        }
      }

      // Step 2: Unregister device before signing out
      try {
        await DeviceService.unregisterDevice();
        if (kDebugMode) {
          print('📱 Device unregistered successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Device unregister failed: $e');
        }
        // Don't fail the logout process if device unregistration fails
      }

      // Step 3: Sign out from Firebase and Google simultaneously
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);

      if (kDebugMode) {
        print('✅ Sign out successful from Firebase and Google');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during sign out: $e');
      }

      // Try individual signouts as fallback
      try {
        await _auth.signOut();
        if (kDebugMode) {
          print('✅ Firebase sign out successful (fallback)');
        }
      } catch (firebaseError) {
        if (kDebugMode) {
          print('❌ Firebase sign out failed: $firebaseError');
        }
      }

      try {
        await _googleSignIn.signOut();
        if (kDebugMode) {
          print('✅ Google sign out successful (fallback)');
        }
      } catch (googleError) {
        if (kDebugMode) {
          print('❌ Google sign out failed: $googleError');
        }
      }

      // Re-throw the error so caller knows something went wrong
      throw e;
    }
  }

  /// Alternative signOut method that includes API logout call
  /// Use this if you want to handle the full logout process from GoogleAuthService
  static Future<void> signOutWithAPI() async {
    try {
      if (kDebugMode) {
        print('🚪 Starting complete sign out process with API...');
      }

      // Step 1: Call logout API
      await _callLogoutAPI();

      // Step 2: Unregister device
      try {
        await DeviceService.unregisterDevice();
        if (kDebugMode) {
          print('📱 Device unregistered successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Device unregister failed: $e');
        }
      }

      // Step 3: Sign out from Firebase and Google
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);

      if (kDebugMode) {
        print('✅ Complete sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during complete sign out: $e');
      }

      // Fallback: try local signout even if API fails
      try {
        await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
        if (kDebugMode) {
          print('✅ Local sign out successful (fallback)');
        }
      } catch (localError) {
        if (kDebugMode) {
          print('❌ Local sign out also failed: $localError');
        }
        throw localError;
      }
    }
  }

  /// Helper method to call logout API
  static Future<void> _callLogoutAPI() async {
    // Import necessary packages at the top of the file
    // import 'package:firebase_messaging/firebase_messaging.dart';
    // import 'package:http/http.dart' as http;
    // import 'dart:convert';

    try {
      // Get Firebase user and token
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        if (kDebugMode) {
          print('No Firebase user found, skipping logout API call');
        }
        return;
      }

      final String? idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        if (kDebugMode) {
          print('Failed to get ID token, skipping logout API call');
        }
        return;
      }

      // Get device ID (FCM token)
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final String? deviceId = await messaging.getToken();

      if (deviceId == null) {
        if (kDebugMode) {
          print('Failed to get device ID, skipping logout API call');
        }
        return;
      }

      if (kDebugMode) {
        print(
          '🚪 Calling logout API with device_id: ${deviceId.substring(0, 10)}...',
        );
      }

      // Make the API call
      final response = await http
          .post(
            Uri.parse('https://api.letmegoo.com/api/user/logout'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': 'Bearer $idToken',
            },
            body: 'device_id=$deviceId',
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('📤 Logout API response: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          print('✅ Logout API call successful');
        }
      } else {
        if (kDebugMode) {
          print(
            '⚠️ Logout API returned: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout API error: $e');
      }
      // Don't throw - continue with local logout
    }
  }

  /// Returns the current Firebase user, if one is authenticated.
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// A stream that notifies about changes to the user's sign-in state.
  ///
  /// This is the recommended way to listen for authentication changes in your UI.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Checks if a user is currently signed in to Firebase.
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
