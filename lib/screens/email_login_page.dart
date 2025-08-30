import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/models/user_model.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';
import 'package:letmegoo/screens/welcome_page.dart';
import 'package:letmegoo/widgets/main_app.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/services/device_service.dart';
import 'package:letmegoo/models/login_method.dart';

// Import the signup page
import 'package:letmegoo/screens/email_signup_page.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    final maxWidth =
        isLargeScreen
            ? 500.0
            : (isTablet ? screenWidth * 0.7 : screenWidth * 0.9);
    final fontSize = screenWidth < 400 ? 14.0 : 16.0;
    final buttonHeight = screenHeight < 700 ? 50.0 : 56.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign In',
          style: AppFonts.semiBold18().copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight < 700 ? 16 : 24,
          ),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight < 700 ? 20 : 40),

                    // Logo
                    Center(
                      child: Container(
                        width: screenWidth < 400 ? 100 : 120,
                        height: screenWidth < 400 ? 100 : 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight < 700 ? 32 : 48),

                    // Header Text
                    Text(
                      'Welcome Back',
                      style: AppFonts.bold24().copyWith(
                        fontSize:
                            screenWidth < 400 ? 24.0 : (isTablet ? 32.0 : 28.0),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: screenHeight < 700 ? 8 : 12),
                    Text(
                      'Sign in to continue reporting incidents',
                      style: AppFonts.regular16().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: fontSize,
                      ),
                    ),

                    SizedBox(height: screenHeight < 700 ? 32 : 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppFonts.regular16().copyWith(fontSize: fontSize),
                      decoration: _buildInputDecoration(
                        'Email Address',
                        Icons.email_outlined,
                        fontSize,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight < 700 ? 20 : 24),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppFonts.regular16().copyWith(fontSize: fontSize),
                      decoration: _buildInputDecoration(
                        'Password',
                        Icons.lock_outline,
                        fontSize,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed:
                              () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight < 700 ? 16 : 20),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged:
                                  (value) => setState(
                                    () => _rememberMe = value ?? false,
                                  ),
                              activeColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                              child: Text(
                                'Remember me',
                                style: AppFonts.regular14().copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: AppFonts.regular14().copyWith(
                              color: AppColors.textAccent,
                              fontSize: fontSize - 2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight < 700 ? 24 : 32),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Sign In',
                                  style: AppFonts.semiBold16().copyWith(
                                    color: AppColors.white,
                                    fontSize: fontSize,
                                  ),
                                ),
                      ),
                    ),

                    SizedBox(height: screenHeight < 700 ? 24 : 32),

                    // Sign Up Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmailSignupPage(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Don\'t have an account? ',
                            style: AppFonts.regular14().copyWith(
                              color: AppColors.textSecondary,
                              fontSize: fontSize - 2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: AppFonts.semiBold14().copyWith(
                                  color: AppColors.textAccent,
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String labelText,
    IconData prefixIcon,
    double fontSize, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppFonts.regular14().copyWith(
        color: AppColors.textSecondary,
        fontSize: fontSize - 2,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.textError, width: 2),
      ),
      filled: true,
      fillColor: AppColors.background,
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // For existing users (login), we don't require email verification
      // Only new signups require verification

      // Register device for push notifications
      await _registerDeviceAfterLogin();

      if (mounted) {
        _showSnackBar('Welcome back!', isError: false);

        // Check if user profile is complete
        await _checkUserProfileAndNavigate();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      if (mounted) {
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Sign in failed. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkUserProfileAndNavigate() async {
    try {
      final userData = await AuthService.authenticateUser();

      if (userData != null) {
        final UserModel userModel = UserModel.fromJson(userData);

        // Only check for essential fields - phone number is optional
        if (userModel.fullname != "Unknown User" &&
            userModel.fullname!.isNotEmpty) {
          // User has complete profile, navigate to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainApp()),
          );
        } else {
          // User needs to complete profile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) =>
                      const UserDetailRegPage(loginMethod: LoginMethod.email),
            ),
          );
        }
      } else {
        // User doesn't exist in backend, navigate to welcome
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    } catch (e) {
      // API call failed, navigate to welcome page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  Future<void> _registerDeviceAfterLogin() async {
    try {
      await DeviceService.registerDevice();
    } catch (e) {
      print('Device registration failed: $e');
    }
  }

  void _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email address first', isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showSnackBar(
        'Password reset email sent! Check your inbox.',
        isError: false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        default:
          errorMessage = 'Failed to send reset email. Please try again.';
      }
      _showSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showSnackBar(
        'Failed to send reset email. Please try again.',
        isError: true,
      );
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.regular14().copyWith(color: AppColors.white),
        ),
        backgroundColor: isError ? AppColors.textError : AppColors.textSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
