import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/models/user_model.dart';
import 'package:letmegoo/screens/email_signup_page.dart';
import 'package:letmegoo/screens/privacy_policy_page.dart';
import 'package:letmegoo/screens/terms_and_condition_page.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';
import 'package:letmegoo/screens/welcome_page.dart';
import 'package:letmegoo/widgets/main_app.dart';
import 'package:letmegoo/services/google_auth_service.dart';
import 'package:letmegoo/services/apple_auth_service.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/services/device_service.dart';
import 'package:letmegoo/models/login_method.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    final safeAreaHeight =
        MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - safeAreaHeight;

    // Responsive sizing
    final logoSize = screenWidth < 400 ? 120.0 : (isTablet ? 160.0 : 140.0);
    final contentPadding = screenWidth < 400 ? 12.0 : (isTablet ? 24.0 : 18.0);
    final sectionSpacing =
        availableHeight < 700 ? 16.0 : (availableHeight < 800 ? 20.0 : 24.0);
    final buttonWidth =
        isLargeScreen
            ? 400.0
            : (isTablet ? screenWidth * 0.6 : screenWidth * 0.85);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Status Bar
          _buildStatusBar(),

          // Main Content - Flexible to fit available space
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: contentPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // App Logo - Responsive
                          _buildAppLogo(logoSize),

                          // Text Content
                          _buildTextContent(
                            screenWidth,
                            isTablet,
                            isLargeScreen,
                          ),

                          // // Feature List - Compact for small screens
                          // _buildFeaturesList(
                          //   screenWidth,
                          //   isTablet,
                          //   availableHeight < 700,
                          // ),

                          // Login Section
                          Column(
                            children: [
                              // Decorative line
                              // Container(
                              //   width: screenWidth * 0.4,
                              //   height: 1,
                              //   decoration: BoxDecoration(
                              //     border: Border.all(
                              //       color: AppColors.primary,
                              //       width: 1,
                              //     ),
                              //   ),
                              // ),
                              SizedBox(height: sectionSpacing),

                              // Login Buttons
                              _buildLoginButtons(
                                buttonWidth,
                                availableHeight < 700,
                              ),

                              SizedBox(height: sectionSpacing * 0.8),

                              // Privacy Notice - Compact
                              _buildPrivacyNotice(
                                buttonWidth,
                                availableHeight < 700,
                              ),

                              SizedBox(height: sectionSpacing * 0.6),

                              // Bottom Links
                              _buildBottomLinks(screenWidth),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Home Indicator
          _buildHomeIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      height: 53,
      decoration: const BoxDecoration(color: Color(0xEAFDFDFD)),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 21,
              top: 16,
              child: Text(
                '9:41',
                style: AppFonts.semiBold14().copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: -0.28,
                ),
              ),
            ),
            Positioned(
              right: 27,
              top: 21,
              child: Container(
                width: 24,
                height: 11,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: AppColors.textSecondary.withOpacity(0.35),
                    ),
                    borderRadius: BorderRadius.circular(2.67),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 7,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(1.33),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(double logoSize) {
    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(logoSize * 0.12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: logoSize * 0.15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(logoSize * 0.12),
        child: Image.asset(
          AppImages.logo,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextContent(
    double screenWidth,
    bool isTablet,
    bool isLargeScreen,
  ) {
    final maxWidth =
        isLargeScreen
            ? 600.0
            : (isTablet ? screenWidth * 0.8 : screenWidth * 0.9);
    final headingSize = screenWidth < 400 ? 20.0 : (isTablet ? 26.0 : 22.0);
    final subtitleSize = screenWidth < 400 ? 14.0 : (isTablet ? 18.0 : 16.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          Text(
            'Blocked by a carelessly parked vehicle? We\'re here to help.',
            textAlign: TextAlign.center,
            style: AppFonts.semiBold24().copyWith(
              color: AppColors.textPrimary,
              fontSize: headingSize,
              height: 1.3,
            ),
          ),

          SizedBox(height: screenWidth < 400 ? 12 : 16),

          Text(
            'Don\'t let bad parking ruin your day.\nLet\'s fix it fast.',
            textAlign: TextAlign.center,
            style: AppFonts.regular16().copyWith(
              color: AppColors.textSecondary,
              fontSize: subtitleSize,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(double screenWidth, bool isTablet, bool isCompact) {
    final maxWidth = isTablet ? screenWidth * 0.7 : screenWidth * 0.85;
    final iconSize = screenWidth < 400 ? 36.0 : (isTablet ? 44.0 : 40.0);
    final textSize = screenWidth < 400 ? 14.0 : (isTablet ? 17.0 : 15.0);
    final spacing = isCompact ? 16.0 : 24.0;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          _buildFeatureItem('📷', 'Snap a photo', iconSize, textSize),
          SizedBox(height: spacing),
          _buildFeatureItem('⚡', 'Report in 10 seconds', iconSize, textSize),
          SizedBox(height: spacing),
          _buildFeatureItem(
            '🗺️',
            'We\'ll try to alert the vehicle owner',
            iconSize,
            textSize,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String emoji,
    String text,
    double iconSize,
    double textSize,
  ) {
    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(iconSize * 0.5),
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: iconSize * 0.45)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppFonts.regular16().copyWith(
              color: AppColors.textPrimary,
              fontSize: textSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButtons(double buttonWidth, bool isCompact) {
    final buttonHeight = isCompact ? 48.0 : 54.0;
    final spacing = isCompact ? 12.0 : 16.0;
    final fontSize = isCompact ? 15.0 : 16.0;
    final showAppleSignIn = Platform.isIOS;

    return Center(
      child: SizedBox(
        width: buttonWidth,
        child: Column(
          children: [
            // Primary Email Button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _navigateToEmailRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue with Email',
                  style: AppFonts.regular16().copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                  ),
                ),
              ),
            ),

            SizedBox(height: spacing),

            // Google Sign-In Button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  side: BorderSide(color: AppColors.textSecondary, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isGoogleLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppImages.googleLogo,
                              width: isCompact ? 20 : 24,
                              height: isCompact ? 20 : 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: AppFonts.regular16().copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: fontSize,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            // Apple Sign-In Button (only on iOS)
            // Replace the existing Apple Sign-In button with this custom one
            // that matches the Google Sign-In button style

            // Apple Sign-In Button (only on iOS)
            if (showAppleSignIn) ...[
              SizedBox(height: spacing),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: _isAppleLoading ? null : _handleAppleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    side: BorderSide(
                      color: AppColors.textSecondary,
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isAppleLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                AppImages
                                    .appleLogo, // You'll need to add this to your assets
                                width: isCompact ? 20 : 24,
                                height: isCompact ? 20 : 24,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Continue with Apple',
                                style: AppFonts.regular16().copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: fontSize,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice(double width, bool isCompact) {
    final fontSize = isCompact ? 11.0 : 13.0;
    final padding = isCompact ? 12.0 : 16.0;

    return Center(
      child: Container(
        width: width,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppColors.lightGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Choose "Email" for maximum privacy. Additional information may be requested after signup for incident reporting features.',
          style: AppFonts.regular13().copyWith(
            color: AppColors.textSecondary,
            height: 1.3,
            fontSize: fontSize,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomLinks(double screenWidth) {
    final fontSize = screenWidth < 400 ? 12.0 : 14.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyPage(),
              ),
            );
          },
          child: Text(
            'Privacy Policy',
            style: AppFonts.regular14().copyWith(
              color: AppColors.textAccent,
              fontSize: fontSize,
            ),
          ),
        ),
        const SizedBox(width: 20),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TermsAndConditionsPage(),
              ),
            );
          },
          child: Text(
            'Terms of Service',
            style: AppFonts.regular14().copyWith(
              color: AppColors.textAccent,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      width: double.infinity,
      height: 33,
      child: Center(
        child: Container(
          width: 139,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }

  // Show snackbar for user feedback
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

  // Navigation methods
  void _navigateToEmailRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailSignupPage()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final UserCredential? userCredential =
          await GoogleAuthService.signInWithGoogle();

      if (userCredential == null) {
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
      await _registerDeviceAfterLogin();

      try {
        final userData = await AuthService.authenticateUser();

        if (userData != null) {
          final UserModel userModel = UserModel.fromJson(userData);

          if (userModel.fullname != "Unknown User" &&
              userModel.fullname!.isNotEmpty) {
            _navigateToMainApp();
          } else {
            _navigateToUserDetails(LoginMethod.google);
          }
        } else {
          _navigateToWelcome();
        }
      } catch (e) {
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

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    try {
      final UserCredential? userCredential =
          await AppleAuthService.signInWithApple();

      if (userCredential == null) {
        setState(() {
          _isAppleLoading = false;
        });
        return;
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to get user information');
      }

      _showSnackBar('Apple sign-in successful!', isError: false);
      await _registerDeviceAfterLogin();

      try {
        final userData = await AuthService.authenticateUser();

        if (userData != null) {
          final UserModel userModel = UserModel.fromJson(userData);

          if (userModel.fullname != "Unknown User" &&
              userModel.fullname!.isNotEmpty) {
            _navigateToMainApp();
          } else {
            _navigateToUserDetails(LoginMethod.apple);
          }
        } else {
          _navigateToWelcome();
        }
      } catch (e) {
        _navigateToWelcome();
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _showSnackBar('Sign-in failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isAppleLoading = false;
      });
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
        errorMessage = 'This sign-in method is not enabled';
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
        errorMessage = 'Too many attempts. Please try again later';
        break;
      default:
        errorMessage = 'Sign-in failed. Please try again';
    }
    _showSnackBar(errorMessage, isError: true);
  }

  Future<void> _registerDeviceAfterLogin() async {
    try {
      await DeviceService.registerDevice();
      print('Device registered successfully after login');
    } catch (e) {
      print('Device registration failed after login: $e');
    }
  }

  void _navigateToMainApp() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => const MainApp()));
  }

  void _navigateToUserDetails(LoginMethod loginMethod) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => UserDetailRegPage(loginMethod: loginMethod),
      ),
    );
  }

  void _navigateToWelcome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
    );
  }
}
