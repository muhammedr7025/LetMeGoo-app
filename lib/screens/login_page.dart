import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/models/user_model.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';
import 'package:letmegoo/screens/welcome_page.dart';
import 'package:letmegoo/widgets/main_app.dart';
import 'package:letmegoo/widgets/commonbutton.dart';
import 'package:letmegoo/services/google_auth_service.dart';
import 'package:letmegoo/services/email_auth_service.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/models/login_method.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool _isSignUp = false; // Toggle between sign in and sign up
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // Sign in with Google
      final UserCredential? userCredential =
          await GoogleAuthService.signInWithGoogle();

      if (userCredential == null) {
        // User canceled sign-in
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to get user information');
      }

      _showSnackBar('Google sign-in successful!', isError: false);

      // Check if user profile is complete via API
      try {
        final userData = await AuthService.authenticateUser();

        if (userData != null) {
          // Parse user data using UserModel (same as splash screen)
          final UserModel userModel = UserModel.fromJson(userData);

          // Apply the same validation logic as splash screen
          if (userModel.fullname != "Unknown User" &&
              userModel.phoneNumber != null) {
            // User has complete profile, navigate to main app
            _navigateToMainApp();
          } else {
            // User needs to complete profile, navigate to user details
            _navigateToUserDetails();
          }
        } else {
          // User doesn't exist in backend, navigate to welcome/user details
          _navigateToWelcome();
        }
      } catch (e) {
        // API call failed, but Google login succeeded
        // Navigate to welcome page to complete setup
        _navigateToWelcome();
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _showSnackBar('Sign-in failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

Future<void> _handleEmailAuth() async {
  if (!_validateEmailForm()) return;

  setState(() {
    _isEmailLoading = true;
  });

  try {
    UserCredential? userCredential;

    if (_isSignUp) {
      // Sign up with email and password
      userCredential = await EmailAuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential != null) {
        _showSnackBar('Account created successfully!', isError: false);
        // Send email verification
        await EmailAuthService.sendEmailVerification();
        _showSnackBar(
          'Verification email sent. Please check your inbox.',
          isError: false,
        );
      }
    } else {
      // Sign in with email and password
      userCredential = await EmailAuthService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential != null) {
        _showSnackBar('Email sign-in successful!', isError: false);
      }
    }

    if (userCredential == null) {
      _showSnackBar(
        _isSignUp ? 'Failed to create account' : 'Failed to sign in',
        isError: true,
      );
      return;
    }

    // FIXED: Add the missing API authentication check for email login
    // This is the same logic used for Google login
    try {
      print('🔍 Checking user profile via API...');
      final userData = await AuthService.authenticateUser();

      if (userData != null) {
        print('✅ User found in backend');
        // Parse user data using UserModel (same as splash screen)
        final UserModel userModel = UserModel.fromJson(userData);
        print('📊 User data: ${userModel.fullname}, Phone: ${userModel.phoneNumber}');

        // Apply the same validation logic as splash screen
        if (userModel.fullname != "Unknown User" && 
            userModel.fullname!.isNotEmpty &&
            userModel.phoneNumber != null && 
            userModel.phoneNumber!.isNotEmpty) {
          // User has complete profile, navigate to main app
          print('🎯 Profile complete, navigating to main app');
          _navigateToMainApp();
        } else {
          // User needs to complete profile, navigate to user details
          print('📝 Profile incomplete, navigating to user details');
          _navigateToUserDetails();
        }
      } else {
        // User doesn't exist in backend, navigate to welcome/user details
        print('❌ User not found in backend, navigating to welcome');
        _navigateToWelcome();
      }
    } catch (e) {
      print('💥 API call failed: $e');
      // API call failed, but email login succeeded
      // Navigate to welcome page to complete setup
      _navigateToWelcome();
    }

  } on FirebaseAuthException catch (e) {
    print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
    _showSnackBar(EmailAuthService.getErrorMessage(e), isError: true);
  } catch (e) {
    print('💥 General Error: $e');
    _showSnackBar(
      '${_isSignUp ? 'Sign up' : 'Sign in'} failed: ${e.toString()}',
      isError: true,
    );
  } finally {
    setState(() {
      _isEmailLoading = false;
    });
  }
}

  bool _validateEmailForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address', isError: true);
      return false;
    }

    if (!EmailAuthService.isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return false;
    }

    if (password.isEmpty) {
      _showSnackBar('Please enter your password', isError: true);
      return false;
    }

    if (!EmailAuthService.isValidPassword(password)) {
      _showSnackBar(EmailAuthService.getPasswordRequirements(), isError: true);
      return false;
    }

    if (_isSignUp) {
      final confirmPassword = _confirmPasswordController.text;
      if (confirmPassword.isEmpty) {
        _showSnackBar('Please confirm your password', isError: true);
        return false;
      }

      if (password != confirmPassword) {
        _showSnackBar('Passwords do not match', isError: true);
        return false;
      }
    }

    return true;
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address', isError: true);
      return;
    }

    if (!EmailAuthService.isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    final success = await EmailAuthService.sendPasswordResetEmail(email);

    if (success) {
      _showSnackBar(
        'Password reset email sent. Please check your inbox.',
        isError: false,
      );
    } else {
      _showSnackBar('Failed to send password reset email', isError: true);
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'account-exists-with-different-credential':
        errorMessage = 'Account exists with different sign-in method';
        break;
      case 'invalid-credential':
        errorMessage = 'Invalid credentials';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Google sign-in is not enabled';
        break;
      case 'user-disabled':
        errorMessage = 'This account has been disabled';
        break;
      case 'user-not-found':
        errorMessage = 'No account found with this email';
        break;
      case 'wrong-password':
        errorMessage = 'Incorrect password';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many attempts. Please try again later.';
        break;
      default:
        errorMessage = e.message ?? 'An unknown error occurred';
    }
    _showSnackBar(errorMessage, isError: true);
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToMainApp() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainApp()));
  }

  void _navigateToUserDetails() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => const UserDetailRegPage(loginMethod: LoginMethod.google),
      ),
    );
  }

  void _navigateToWelcome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive breakpoints
    final bool isLargeScreen = screenWidth > 1200;
    final bool isTablet = screenWidth > 600 && screenWidth <= 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.08),

                // Logo
                Container(
                  width:
                      screenWidth *
                      (isLargeScreen
                          ? 0.15
                          : isTablet
                          ? 0.25
                          : 0.4),
                  height:
                      screenWidth *
                      (isLargeScreen
                          ? 0.15
                          : isTablet
                          ? 0.25
                          : 0.4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage(AppImages.logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Title
                Text(
                  _isSignUp ? "Create Account" : "Welcome Back!",
                  style: AppFonts.bold13(color: AppColors.primary).copyWith(
                    fontSize:
                        screenWidth *
                        (isLargeScreen
                            ? 0.025
                            : isTablet
                            ? 0.035
                            : 0.055),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.015),

                // Subtitle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    _isSignUp
                        ? "Create your account to get started"
                        : "Sign in to your account to continue",
                    style: AppFonts.regular13(
                      color: AppColors.textSecondary,
                    ).copyWith(
                      fontSize:
                          screenWidth *
                          (isLargeScreen
                              ? 0.014
                              : isTablet
                              ? 0.025
                              : 0.035),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Email Form
                Container(
                  width:
                      screenWidth *
                      (isLargeScreen
                          ? 0.4
                          : isTablet
                          ? 0.6
                          : 0.9),
                  child: Column(
                    children: [
                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isEmailLoading,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isEmailLoading,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      // Confirm Password (only for sign up)
                      if (_isSignUp) ...[
                        SizedBox(height: screenHeight * 0.02),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          enabled: !_isEmailLoading,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Confirm your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],

                      SizedBox(height: screenHeight * 0.01),

                      // Forgot Password (only for sign in)
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            child: Text(
                              'Forgot Password?',
                              style: AppFonts.regular13(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: screenHeight * 0.02),

                      // Email Auth Button
                      CommonButton(
                        text: _isSignUp ? "Create Account" : "Sign In",
                        onTap: () => _handleEmailAuth(),
                        isLoading: _isEmailLoading,
                        isEnabled: !_isEmailLoading,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Toggle Sign In/Sign Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp
                                ? "Already have an account? "
                                : "Don't have an account? ",
                            style: AppFonts.regular13(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                // Clear form when switching
                                _emailController.clear();
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                              });
                            },
                            child: Text(
                              _isSignUp ? "Sign In" : "Sign Up",
                              style: AppFonts.bold16(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: AppFonts.regular13(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Google Login Button
                      GestureDetector(
                        onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                        child: Container(
                          width: double.infinity,
                          height: screenHeight * 0.07,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  _isGoogleLoading
                                      ? AppColors.textSecondary.withOpacity(0.3)
                                      : AppColors.textSecondary,
                              width: 1,
                            ),
                            color:
                                _isGoogleLoading
                                    ? AppColors.textSecondary.withOpacity(0.1)
                                    : AppColors.background,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isGoogleLoading) ...[
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Signing in with Google...",
                                  style: AppFonts.semiBold14(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ] else ...[
                                Image.asset(
                                  AppImages
                                      .googleLogo, // Add Google icon to assets
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Continue with Google",
                                  style: AppFonts.semiBold14(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
