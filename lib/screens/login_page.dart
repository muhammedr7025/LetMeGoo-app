import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/models/user_model.dart';
import 'package:letmegoo/screens/phone_number_page.dart';
import 'package:letmegoo/screens/user_detail_reg_page.dart';
import 'package:letmegoo/screens/welcome_page.dart';
import 'package:letmegoo/widgets/main_app.dart';
import 'package:letmegoo/widgets/commonbutton.dart';
import 'package:letmegoo/widgets/loginactionrow.dart';
import 'package:letmegoo/services/google_auth_service.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/models/login_method.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isGoogleLoading = false;

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
        errorMessage = 'Too many attempts. Please try again later';
        break;
      default:
        errorMessage = 'Sign-in failed: ${e.message}';
    }
    _showSnackBar(errorMessage, isError: true);
  }

  void _navigateToMainApp() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainApp()));
  }

  void _navigateToWelcome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  void _navigateToUserDetails() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserDetailRegPage(loginMethod: LoginMethod.google),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.darkRed : AppColors.darkGreen,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, // 5% padding on sides
            ),
            child: Column(
              children: [
                // Logo Container
                Container(
                  height: screenHeight * (isTablet ? 0.25 : 0.28),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      Image.asset(
                        AppImages.lock,
                        width:
                            screenWidth *
                            (isLargeScreen
                                ? 0.15
                                : isTablet
                                ? 0.2
                                : 0.35),
                        height:
                            screenWidth *
                            (isLargeScreen
                                ? 0.15
                                : isTablet
                                ? 0.2
                                : 0.35),
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                // Title Section
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 600 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Blocked by a carelessly parked",
                        style: AppFonts.semiBold24().copyWith(
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
                      Text(
                        "vehicle? We're here to help.",
                        style: AppFonts.semiBold24().copyWith(
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
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Subtitle Section
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 500 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Don't let bad parking ruin your day.",
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
                      Text(
                        "Let's fix it fast.",
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
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.035),

                // Action buttons - Make them responsive
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        isLargeScreen
                            ? 500
                            : isTablet
                            ? 400
                            : double.infinity,
                  ),
                  child: const Column(
                    children: [
                      LoginActionRow(
                        icon: Icons.camera_alt_outlined,
                        label: "Find owner",
                        color: Color(0xFF31C5F4),
                        showConnector: true,
                      ),
                      LoginActionRow(
                        icon: Icons.alarm,
                        label: "Report in one minute",
                        color: Color(0xFF31C5F4),
                        showConnector: true,
                      ),
                      LoginActionRow(
                        icon: Icons.notifications_active_outlined,
                        label: "Get help & save time!",
                        color: Color(0xFF31C5F4),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Buttons Container
                Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        isLargeScreen
                            ? 400
                            : isTablet
                            ? 350
                            : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // Phone Number Login Button
                      CommonButton(
                        text: "Login With Phone Number",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PhoneNumberPage(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Google Login Button - Enhanced with loading state
                      GestureDetector(
                        onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                        child: Container(
                          width:
                              screenWidth *
                              (isLargeScreen
                                  ? 0.4
                                  : isTablet
                                  ? 0.6
                                  : 0.85),
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
                                  width:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.02
                                          : isTablet
                                          ? 0.04
                                          : 0.06),
                                  height:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.02
                                          : isTablet
                                          ? 0.04
                                          : 0.06),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Image.asset(
                                  AppImages.googleLogo,
                                  width:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.02
                                          : isTablet
                                          ? 0.04
                                          : 0.06),
                                  height:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.02
                                          : isTablet
                                          ? 0.04
                                          : 0.06),
                                ),
                              ],
                              SizedBox(width: screenWidth * 0.025),
                              Text(
                                _isGoogleLoading
                                    ? "Signing in..."
                                    : "Login With Google",
                                style: TextStyle(
                                  fontSize:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.016
                                          : isTablet
                                          ? 0.025
                                          : 0.04),
                                  color:
                                      _isGoogleLoading
                                          ? AppColors.textSecondary.withOpacity(
                                            0.7,
                                          )
                                          : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
