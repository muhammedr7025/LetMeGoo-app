// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/models/login_method.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/services/device_service.dart'; // Add this import
import 'package:letmegoo/models/user_model.dart';
import 'package:letmegoo/screens/login_page.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';
import 'package:letmegoo/widgets/main_app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  String _loadingText = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _startSplashSequence() async {
    // Start logo animation
    await _logoController.forward();

    // Start text animation
    await _textController.forward();

    // Wait a bit for user to see the splash
    await Future.delayed(const Duration(milliseconds: 800));

    // Check authentication
    await _checkAuthenticationStatus();
  }

  void _updateLoadingText(String text) {
    if (mounted) {
      setState(() {
        _loadingText = text;
      });
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      _updateLoadingText('Checking authentication...');

      // Check if Firebase user exists
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        // No Firebase user found, navigate to login
        _navigateToLogin();
        return;
      }

      _updateLoadingText('Authenticating with server...');

      // Firebase user exists, authenticate with API
      final Map<String, dynamic>? userData =
          await AuthService.authenticateUser();

      if (userData == null) {
        // API authentication failed, navigate to login
        _navigateToLogin();
        return;
      }

      _updateLoadingText('Setting up notifications...');

      // Check and ensure device is registered for push notifications
      await _ensureDeviceRegistration();

      _updateLoadingText('Loading profile...');

      // Parse user data
      final UserModel user = UserModel.fromJson(userData);

      // Check if user has valid username
      if (user.fullname != "Unknown User" && user.phoneNumber != null) {
        // User has complete profile, navigate to home
        _updateLoadingText('Welcome back!');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        // User needs to complete profile, navigate to user details
        _updateLoadingText('Setting up profile...');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToUserDetails();
      }
    } catch (e) {
      print('Authentication check error: $e');
      _updateLoadingText('Something went wrong...');
      await Future.delayed(const Duration(milliseconds: 1000));
      // On error, navigate to login for safety
      _navigateToLogin();
    }
  }

  /// Ensure device is registered for push notifications
  Future<void> _ensureDeviceRegistration() async {
    try {
      final isRegistered = await DeviceService.ensureDeviceRegistered();
      if (isRegistered) {
        print('Device registration confirmed');
      } else {
        print('Device registration failed, but continuing...');
      }
    } catch (e) {
      print('Device registration error: $e');
      // Don't block the app flow if device registration fails
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const MainApp(),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToUserDetails() {
    // Determine login method
    final User? user = FirebaseAuth.instance.currentUser;
    LoginMethod loginMethod = LoginMethod.unknown;

    if (user != null) {
      for (UserInfo provider in user.providerData) {
        switch (provider.providerId) {
          case 'phone':
            loginMethod = LoginMethod.phone;
            break;
          case 'google.com':
            loginMethod = LoginMethod.google;
            break;
        }
      }
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder:
            (_, __, ___) => UserDetailRegPage(loginMethod: loginMethod),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with Animation
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Image.asset(
                        AppImages.logo, // Your app logo
                        width:
                            screenWidth *
                            (isLargeScreen
                                ? 0.25
                                : isTablet
                                ? 0.3
                                : 0.4),
                        height:
                            screenWidth *
                            (isLargeScreen
                                ? 0.25
                                : isTablet
                                ? 0.3
                                : 0.4),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.04),

              // App Name with Animation
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      Text(
                        'Let Me Goo',
                        style: AppFonts.bold24().copyWith(
                          fontSize:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.035
                                  : isTablet
                                  ? 0.045
                                  : 0.08),
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      Text(
                        'Smart app to unblock your way!',
                        style: AppFonts.regular16().copyWith(
                          fontSize:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.018
                                  : isTablet
                                  ? 0.025
                                  : 0.04),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.1),

              // Loading Indicator
              SizedBox(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Dynamic Loading Text
              FadeTransition(
                opacity: _textFade,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _loadingText,
                    key: ValueKey(_loadingText),
                    style: AppFonts.regular14().copyWith(
                      fontSize:
                          screenWidth *
                          (isLargeScreen
                              ? 0.016
                              : isTablet
                              ? 0.025
                              : 0.035),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
