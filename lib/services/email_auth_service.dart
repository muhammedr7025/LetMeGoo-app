import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:letmegoo/services/device_service.dart';

class EmailAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign up with email and password
  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Email Sign Up: Creating account for $email');
      }

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        print(
          'Email Sign Up: Account created successfully -> ${userCredential.user?.email}',
        );
      }

      // Register device after successful signup
      try {
        await DeviceService.registerDevice();
        if (kDebugMode) {
          print('Device registered successfully for push notifications');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Device registration failed: $e');
        }
        // Don't fail the signup process if device registration fails
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: [${e.code}] ${e.message}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('An unexpected error occurred during email sign up: $e');
      }
      return null;
    }
  }

  /// Sign in with email and password
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Email Sign In: Signing in $email');
      }

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        print(
          'Email Sign In: User successfully signed in -> ${userCredential.user?.email}',
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
        print('An unexpected error occurred during email sign in: $e');
      }
      return null;
    }
  }

  /// Send password reset email
  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      if (kDebugMode) {
        print('Password Reset: Sending reset email to $email');
      }

      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        print('Password Reset: Email sent successfully');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Password Reset Error: [${e.code}] ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('An unexpected error occurred during password reset: $e');
      }
      return false;
    }
  }

  /// Send email verification
  static Future<bool> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('Email Verification: No user found');
        }
        return false;
      }

      if (kDebugMode) {
        print(
          'Email Verification: Sending verification email to ${user.email}',
        );
      }

      await user.sendEmailVerification();

      if (kDebugMode) {
        print('Email Verification: Verification email sent successfully');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Email Verification Error: [${e.code}] ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('An unexpected error occurred during email verification: $e');
      }
      return false;
    }
  }

  /// Check if current user's email is verified
  static bool isEmailVerified() {
    final User? user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Reload user to get updated email verification status
  static Future<void> reloadUser() async {
    try {
      final User? user = _auth.currentUser;
      await user?.reload();
    } catch (e) {
      if (kDebugMode) {
        print('Error reloading user: $e');
      }
    }
  }

  /// Sign out from Firebase
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('Signing out from Firebase...');
      }

      // Unregister device before signing out
      try {
        await DeviceService.unregisterDevice();
        if (kDebugMode) {
          print('Device unregistered successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Device unregister failed: $e');
        }
      }

      await _auth.signOut();
      if (kDebugMode) {
        print('Sign out successful.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
    }
  }

  /// Get error message from FirebaseAuthException
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    // At least 6 characters long
    return password.length >= 6;
  }

  /// Get detailed password requirements
  static String getPasswordRequirements() {
    return 'Password must be at least 6 characters long';
  }

  /// Returns the current Firebase user, if one is authenticated
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// A stream that notifies about changes to the user's sign-in state
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Checks if a user is currently signed in to Firebase
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
