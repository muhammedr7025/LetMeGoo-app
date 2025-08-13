import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/models/login_method.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _lockController;
  late AnimationController _textController;

  late Animation<Offset> _lockSlide;
  late Animation<double> _lockFade;
  late Animation<double> _lockScale;

  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  bool _showText = false;

  @override
  void initState() {
    super.initState();

    // Single smooth controller for lock animation
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Smooth lock entry with gentle settle
    _lockSlide = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _lockController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Lock fade in
    _lockFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Subtle scale for gentle landing effect
    _lockScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Text animations
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startSequence();
  }

  // Method to determine login method from Firebase user
  LoginMethod _determineLoginMethod() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return LoginMethod.unknown;
    }

    // Check provider data to determine login method
    for (UserInfo provider in user.providerData) {
      switch (provider.providerId) {
        case 'password':
          return LoginMethod.email;
        case 'google.com':
          return LoginMethod.google;
      }
    }

    // Fallback: check if email exists (likely email auth)
    if (user.email != null && user.email!.isNotEmpty) {
      return LoginMethod.email;
    }

    // Check if signed in with Google (alternative check)
    if (user.email != null &&
        user.email!.isNotEmpty &&
        user.displayName != null) {
      return LoginMethod.google;
    }

    return LoginMethod.unknown;
  }

  Future<void> _startSequence() async {
    try {
      // Step 1: Lock enters smoothly from top
      await _lockController.forward();

      // Step 2: Small pause to let lock settle
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Text appears
      setState(() => _showText = true);
      await _textController.forward();

      // Step 4: Wait and navigate
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        // Determine login method before navigation
        final LoginMethod loginMethod = _determineLoginMethod();

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder:
                (_, __, ___) => UserDetailRegPage(loginMethod: loginMethod),
            transitionsBuilder:
                (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fallback navigation with unknown login method
        final LoginMethod loginMethod = _determineLoginMethod();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UserDetailRegPage(loginMethod: loginMethod),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _lockController.dispose();
    _textController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Lock Icon
                    AnimatedBuilder(
                      animation: _lockController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _lockSlide,
                          child: FadeTransition(
                            opacity: _lockFade,
                            child: ScaleTransition(
                              scale: _lockScale,
                              child: Container(
                                width:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.12
                                        : isTablet
                                        ? 0.2
                                        : 0.3),
                                height:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.12
                                        : isTablet
                                        ? 0.2
                                        : 0.3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.06
                                          : isTablet
                                          ? 0.1
                                          : 0.15),
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: screenHeight * 0.06),

                    // Animated Text Content
                    if (_showText)
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textFade,
                              child: Column(
                                children: [
                                  // Welcome Title
                                  Text(
                                    "Welcome to LetMeGoo!",
                                    style: AppFonts.bold13(
                                      color: AppColors.primary,
                                    ).copyWith(
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

                                  SizedBox(height: screenHeight * 0.02),

                                  // Subtitle
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.1,
                                    ),
                                    child: Text(
                                      "Let's set up your profile to get started with your smart vehicle assistant",
                                      style: AppFonts.regular16(
                                        color: AppColors.textSecondary,
                                      ).copyWith(
                                        fontSize:
                                            screenWidth *
                                            (isLargeScreen
                                                ? 0.016
                                                : isTablet
                                                ? 0.025
                                                : 0.04),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.04),

                                  // Features List
                                  Container(
                                    width:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.4
                                            : isTablet
                                            ? 0.6
                                            : 0.8),
                                    child: Column(
                                      children: [
                                        _buildFeatureItem(
                                          Icons.security,
                                          "Secure Authentication",
                                          "Your account is protected",
                                          screenWidth,
                                          isLargeScreen,
                                          isTablet,
                                        ),
                                        SizedBox(height: screenHeight * 0.02),
                                        _buildFeatureItem(
                                          Icons.directions_car,
                                          "Vehicle Management",
                                          "Track and manage your vehicles",
                                          screenWidth,
                                          isLargeScreen,
                                          isTablet,
                                        ),
                                        SizedBox(height: screenHeight * 0.02),
                                        _buildFeatureItem(
                                          Icons.notifications_active,
                                          "Smart Alerts",
                                          "Get notified about important updates",
                                          screenWidth,
                                          isLargeScreen,
                                          isTablet,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Loading indicator at bottom
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.08),
              child: Column(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Setting up your profile...",
                    style: AppFonts.regular14(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    double screenWidth,
    bool isLargeScreen,
    bool isTablet,
  ) {
    return Row(
      children: [
        Container(
          width:
              screenWidth *
              (isLargeScreen
                  ? 0.03
                  : isTablet
                  ? 0.05
                  : 0.08),
          height:
              screenWidth *
              (isLargeScreen
                  ? 0.03
                  : isTablet
                  ? 0.05
                  : 0.08),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size:
                screenWidth *
                (isLargeScreen
                    ? 0.015
                    : isTablet
                    ? 0.025
                    : 0.04),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.semiBold14(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.014
                          : isTablet
                          ? 0.025
                          : 0.035),
                ),
              ),
              Text(
                description,
                style: AppFonts.regular13(
                  color: AppColors.textSecondary,
                ).copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.012
                          : isTablet
                          ? 0.02
                          : 0.03),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
