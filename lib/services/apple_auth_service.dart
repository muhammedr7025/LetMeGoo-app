import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:letmegoo/services/device_service.dart';

class AppleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Key to store Apple user IDs in Firebase user metadata
  static const String _appleUserIdKey = 'appleUserId';

  /// Generates a cryptographically secure random nonce or password
  static String generateSecureString([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Custom Apple Sign-In that creates a Firebase user with email authentication
  static Future<UserCredential?> signInWithApple() async {
    try {
      // Step 1: Authenticate with Apple
      final rawNonce = generateSecureString();
      final nonce = sha256ofString(rawNonce);

      if (kDebugMode) {
        print('Starting Apple authentication flow');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (kDebugMode) {
        print('Successfully authenticated with Apple');
        print(
          'Apple User ID: ${appleCredential.userIdentifier ?? "Not provided"}',
        );
        print('Email: ${appleCredential.email ?? "Not provided"}');
        print(
          'Name: ${appleCredential.givenName ?? ""} ${appleCredential.familyName ?? ""}',
        );
      }

      // Get unique identifier from Apple - this is crucial for subsequent sign-ins
      final String appleUserId =
          appleCredential.userIdentifier ?? generateSecureString(20);

      // For the email, use provided email or create a consistent one from the Apple ID
      final String email =
          appleCredential.email ??
          'apple_${appleUserId.substring(0, 8)}@example.com';

      // Create a stable password based on the Apple user ID (same for every sign-in)
      final String password =
          'Apple_${sha256ofString(appleUserId).substring(0, 16)}';

      if (kDebugMode) {
        print('Using email: $email for Firebase authentication');
      }

      // First try signing in (in case user already exists)
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (kDebugMode) {
          print('Successfully signed in existing user with email/password');
        }

        // Register device after successful login
        await _registerDeviceAfterLogin();

        return userCredential;
      } catch (signInError) {
        if (kDebugMode) {
          print('Sign-in failed, creating new user: $signInError');
        }

        // Create a new user since sign-in failed
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update user profile
        final user = userCredential.user;
        if (user != null) {
          // Set display name if provided
          final displayName = _getDisplayNameFromAppleCredential(
            appleCredential,
          );
          if (displayName.isNotEmpty) {
            await user.updateDisplayName(displayName);
            if (kDebugMode) {
              print('Updated user display name to: $displayName');
            }
          }
        }

        // Register device after successful registration
        await _registerDeviceAfterLogin();

        if (kDebugMode) {
          print('Successfully created new user with email/password');
        }

        return userCredential;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        if (kDebugMode) {
          print('User canceled Apple Sign In');
        }
        return null;
      }

      if (kDebugMode) {
        print('Apple authorization error: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error during Apple Sign In: $e');
      }
      return null;
    }
  }

  /// Get display name from Apple credential
  static String _getDisplayNameFromAppleCredential(
    AuthorizationCredentialAppleID credential,
  ) {
    final parts =
        [
          credential.givenName,
          credential.familyName,
        ].where((part) => part != null && part.isNotEmpty).toList();

    return parts.isEmpty ? '' : parts.join(' ');
  }

  /// Register device for push notifications
  static Future<void> _registerDeviceAfterLogin() async {
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
  }
}
