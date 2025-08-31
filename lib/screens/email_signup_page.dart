import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/models/login_method.dart';
import 'package:letmegoo/screens/email_login_page.dart';
import 'package:letmegoo/screens/privacy_policy_page.dart';
import 'package:letmegoo/screens/terms_and_condition_page.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';
import 'package:letmegoo/services/device_service.dart';
import 'dart:async';

// Updated EmailSignupPage with OTP verification
class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
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
          'Sign Up',
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
                    // Logo
                    Center(
                      child: Container(
                        width: screenWidth < 400 ? 80 : 100,
                        height: screenWidth < 400 ? 80 : 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight < 700 ? 24 : 32),

                    // Header Text
                    Text(
                      'Create Your Account',
                      style: AppFonts.bold24().copyWith(
                        fontSize:
                            screenWidth < 400 ? 22.0 : (isTablet ? 28.0 : 24.0),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: screenHeight < 700 ? 6 : 8),
                    Text(
                      'Join LetMeGoo to report incidents and help your community',
                      style: AppFonts.regular16().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: fontSize,
                      ),
                    ),

                    SizedBox(height: screenHeight < 700 ? 24 : 32),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      style: AppFonts.regular16().copyWith(fontSize: fontSize),
                      decoration: _buildInputDecoration(
                        'Full Name *',
                        Icons.person_outline,
                        fontSize,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight < 700 ? 16 : 20),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: AppFonts.regular16().copyWith(fontSize: fontSize),
                      decoration: _buildInputDecoration(
                        'Email Address *',
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

                    SizedBox(height: screenHeight < 700 ? 16 : 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppFonts.regular16().copyWith(fontSize: fontSize),
                      decoration: _buildInputDecoration(
                        'Password *',
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
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight < 700 ? 16 : 20),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: AppFonts.regular16().copyWith(fontSize: fontSize),
                      decoration: _buildInputDecoration(
                        'Confirm Password *',
                        Icons.lock_outline,
                        fontSize,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed:
                              () => setState(
                                () =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                              ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight < 700 ? 20 : 24),

                    // Terms and Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged:
                              (value) => setState(
                                () => _agreeToTerms = value ?? false,
                              ),
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () => setState(
                                  () => _agreeToTerms = !_agreeToTerms,
                                ),
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: AppFonts.regular14().copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: fontSize - 2,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: AppFonts.regular14().copyWith(
                                      color: AppColors.textAccent,
                                      fontSize: fontSize - 2,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const TermsAndConditionsPage(),
                                              ),
                                            );
                                          },
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: AppFonts.regular14().copyWith(
                                      color: AppColors.textAccent,
                                      fontSize: fontSize - 2,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const PrivacyPolicyPage(),
                                              ),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ),

                            // Don't forget to import gesture recognizer at the top of your file:
                            // import 'package:flutter/gestures.dart';
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight < 700 ? 24 : 32),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading || !_agreeToTerms ? null : _signUp,
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
                                  'Create Account',
                                  style: AppFonts.semiBold16().copyWith(
                                    color: AppColors.white,
                                    fontSize: fontSize,
                                  ),
                                ),
                      ),
                    ),

                    SizedBox(height: screenHeight < 700 ? 20 : 24),

                    // Login Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmailLoginPage(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: AppFonts.regular14().copyWith(
                              color: AppColors.textSecondary,
                              fontSize: fontSize - 2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user account but don't sign them in yet
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Update display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Sign out the user immediately after creation
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        _showSnackBar(
          'Account created! Please check your email for verification.',
          isError: false,
        );

        // Navigate to email verification page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => EmailVerificationPage(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                  name: _nameController.text.trim(),
                ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);
      if (mounted) {
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Registration failed. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email registration is currently disabled.';
      default:
        return 'Registration failed. Please try again.';
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

// Email Verification Page
class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String password;
  final String name;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
    _checkEmailVerification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 60; // 60 seconds cooldown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _checkEmailVerification() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user?.emailVerified == true) {
        timer.cancel();
        if (mounted) {
          await _completeRegistration();
        }
      }
    });
  }

  Future<void> _completeRegistration() async {
    try {
      // Register device for push notifications
      await DeviceService.registerDevice();

      _showSnackBar('Email verified successfully!', isError: false);

      // Navigate to UserDetailRegPage for new users to complete profile
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => UserDetailRegPage(loginMethod: LoginMethod.email),
        ),
      );
    } catch (e) {
      _showSnackBar(
        'Email verified! Please complete your profile.',
        isError: false,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => UserDetailRegPage(loginMethod: LoginMethod.email),
        ),
      );
    }
  }

  Future<void> _resendVerification() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    try {
      // Sign in temporarily to resend verification
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );

      await userCredential.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      _showSnackBar('Verification email sent!', isError: false);
      _startResendCooldown();
    } catch (e) {
      _showSnackBar('Failed to resend verification email', isError: true);
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _checkVerificationManually() async {
    setState(() => _isLoading = true);

    try {
      // Sign in to check verification status
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );

      await userCredential.user?.reload();

      if (userCredential.user?.emailVerified == true) {
        await _completeRegistration();
      } else {
        _showSnackBar(
          'Email not verified yet. Please check your inbox.',
          isError: true,
        );
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      _showSnackBar('Failed to check verification status', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
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
          'Verify Email',
          style: AppFonts.semiBold18().copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: 24,
          ),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.05),

                  // Email icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 32),

                  Text(
                    'Check Your Email',
                    style: AppFonts.bold24().copyWith(
                      fontSize:
                          screenWidth < 400 ? 24.0 : (isTablet ? 32.0 : 28.0),
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16),

                  Text(
                    'We\'ve sent a verification link to:',
                    style: AppFonts.regular16().copyWith(
                      color: AppColors.textSecondary,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8),

                  Text(
                    widget.email,
                    style: AppFonts.semiBold16().copyWith(
                      color: AppColors.primary,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Click the link in your email to verify your account',
                                style: AppFonts.regular14().copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: fontSize - 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This page will automatically redirect once verified',
                          style: AppFonts.regular13().copyWith(
                            color: AppColors.textSecondary,
                            fontSize: fontSize - 3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),

                  // Check verification button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkVerificationManually,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                'I\'ve Verified My Email',
                                style: AppFonts.semiBold16().copyWith(
                                  color: AppColors.white,
                                  fontSize: fontSize,
                                ),
                              ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Resend button
                  TextButton(
                    onPressed:
                        _resendCooldown > 0 || _isResending
                            ? null
                            : _resendVerification,
                    child:
                        _isResending
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textAccent,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sending...',
                                  style: AppFonts.regular14().copyWith(
                                    color: AppColors.textAccent,
                                    fontSize: fontSize - 2,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              _resendCooldown > 0
                                  ? 'Resend in ${_resendCooldown}s'
                                  : 'Resend Verification Email',
                              style: AppFonts.regular14().copyWith(
                                color:
                                    _resendCooldown > 0
                                        ? AppColors.textSecondary
                                        : AppColors.textAccent,
                                fontSize: fontSize - 2,
                              ),
                            ),
                  ),

                  SizedBox(height: 40),

                  // Help text
                  Text(
                    'Didn\'t receive the email? Check your spam folder or try a different email address.',
                    style: AppFonts.regular13().copyWith(
                      color: AppColors.textSecondary,
                      fontSize: fontSize - 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
