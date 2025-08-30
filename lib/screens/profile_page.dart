import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/screens/about_us_page.dart';
import 'package:letmegoo/screens/edit_profile_page.dart';
import 'package:letmegoo/screens/my_vehicles_page.dart';
import 'package:letmegoo/screens/privacy_policy_page.dart';
import 'package:letmegoo/screens/privacy_preferences_page.dart';
import 'package:letmegoo/providers/user_provider.dart';
import 'package:letmegoo/providers/app_providers.dart';
import 'package:letmegoo/providers/app_state_provider.dart';
import 'package:letmegoo/screens/terms_and_condition_page.dart';
import 'package:letmegoo/services/auth_service.dart';
import '../../widgets/profileoption.dart';
import '../../widgets/usertile.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../widgets/sectionheader.dart';
import '../widgets/Customdivider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final Function(int) onNavigate;
  final VoidCallback onAddPressed;

  const ProfilePage({
    super.key,
    required this.onNavigate,
    required this.onAddPressed,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load user data on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUserData();
    });
  }

  @override
  void dispose() {
    // Cancel any ongoing operations or timers here if needed
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    // Update global snackbar provider
    ref.read(snackbarProvider.notifier).state = SnackbarMessage(
      message: message,
      isError: isError,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.darkRed : AppColors.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Watch user state
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Column(
            children: [
              // Main Content
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Row(
                  children: [
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Profile",
                          style: AppFonts.bold20().copyWith(
                            fontSize:
                                screenWidth *
                                (isLargeScreen
                                    ? 0.022
                                    : isTablet
                                    ? 0.032
                                    : 0.05),
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(userProvider.notifier).refreshUserData();
                  },
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isLargeScreen ? 600 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Profile Card with Loading State
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: _buildUserTile(),
                          ),

                          SizedBox(height: screenHeight * 0.035),

                          // Account Settings Section
                          const SectionHeader(title: "Account Settings"),

                          SizedBox(height: screenHeight * 0.015),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Profileoption(
                                  icon: Icons.edit_outlined,
                                  title: "Edit Profile",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const EditProfilePage(),
                                      ),
                                    );
                                  },
                                ),
                                CustomDivider(screenWidth: screenWidth),

                                Profileoption(
                                  icon: Icons.lock_outline,
                                  title: "Privacy Preference",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  onTap: () {
                                    if (userState.userData != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (
                                                context,
                                              ) => PrivacyPreferencesPage(
                                                currentPreference:
                                                    userState
                                                        .userData!['privacy_preference']
                                                        ?.toString() ??
                                                    'private',
                                                onPreferenceChanged: (
                                                  newPreference,
                                                ) {
                                                  if (mounted) {
                                                    ref
                                                        .read(
                                                          userProvider.notifier,
                                                        )
                                                        .updatePrivacyPreference(
                                                          newPreference,
                                                        );
                                                    _showSnackBar(
                                                      'Privacy preference updated successfully!',
                                                      isError: false,
                                                    );
                                                  }
                                                },
                                              ),
                                        ),
                                      );
                                    } else {
                                      _showSnackBar(
                                        'Please wait for profile to load',
                                        isError: true,
                                      );
                                    }
                                  },
                                ),

                                CustomDivider(screenWidth: screenWidth),

                                Profileoption(
                                  icon: Icons.directions_car_outlined,
                                  title: "My Vehicles",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const MyVehiclesPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.035),

                          // Support & Legal Section
                          SectionHeader(title: "Support & Legal"),

                          SizedBox(height: screenHeight * 0.015),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Profileoption(
                                  icon: Icons.shield_outlined,
                                  title: "Privacy Policy",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  onTap: () {
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

                                CustomDivider(screenWidth: screenWidth),

                                Profileoption(
                                  icon: Icons.article_outlined,
                                  title: "Terms and Conditions",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  onTap: () {
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

                                CustomDivider(screenWidth: screenWidth),

                                Profileoption(
                                  icon: Icons.info_outline,
                                  title: "About Us",
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  onTap: () {
                                    // Handle about us - you can create an AboutUsPage similar to PrivacyPolicyPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const AboutUsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.035),

                          // Danger Zone Section
                          const SectionHeader(title: "Danger Zone"),

                          SizedBox(height: screenHeight * 0.015),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Profileoption(
                              icon: Icons.delete_outline,
                              title: "Delete Account",
                              trailing: Icon(
                                Icons.chevron_right,
                                color: AppColors.darkRed.withOpacity(0.7),
                                size:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.025
                                        : isTablet
                                        ? 0.035
                                        : 0.06),
                              ),
                              onTap: () {
                                _showDeleteAccountDialog(context);
                              },
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Enhanced Logout Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.darkRed.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton.icon(
                              onPressed: () => _showLogoutDialog(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.018,
                                  horizontal: screenWidth * 0.04,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                Icons.logout_outlined,
                                color: AppColors.darkRed,
                                size:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.025
                                        : isTablet
                                        ? 0.035
                                        : 0.055),
                              ),
                              label: Text(
                                "Log Out",
                                style: AppFonts.regular20(
                                  color: AppColors.darkRed,
                                ).copyWith(
                                  fontSize:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.018
                                          : isTablet
                                          ? 0.028
                                          : 0.042),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Navigation - FIXED: Changed currentIndex from 0 to 1
              CustomBottomNav(
                currentIndex: 1, // This was the issue! Changed from 0 to 1
                onTap: widget.onNavigate,
                onInformPressed: widget.onAddPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile() {
    final userState = ref.watch(userProvider);

    if (userState.isLoading) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Loading profile...',
                style: AppFonts.regular16(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (userState.errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.darkRed, size: 32),
            SizedBox(height: 8),
            Text(
              'Failed to load profile',
              style: AppFonts.semiBold16(color: AppColors.darkRed),
            ),
            SizedBox(height: 4),
            Text(
              userState.errorMessage!,
              style: AppFonts.regular14(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  () => ref.read(userProvider.notifier).refreshUserData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (userState.userData == null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'No user data available',
            style: AppFonts.regular16(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Usertile(
      initials: ref.read(userProvider.notifier).getUserInitials(),
      name: ref.read(userProvider.notifier).getDisplayName(),
      email: ref.read(userProvider.notifier).getEmail(),
      phone: ref.read(userProvider.notifier).getPhone(),
      image: ref.read(userProvider.notifier).getProfilePicture(),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 20,
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.darkRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: AppColors.darkRed,
                  size:
                      screenWidth *
                      (isLargeScreen
                          ? 0.035
                          : isTablet
                          ? 0.045
                          : 0.08),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                'Delete Account',
                style: AppFonts.semiBold18().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.02
                          : isTablet
                          ? 0.03
                          : 0.045),
                  color: AppColors.darkRed,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete your account?',
                textAlign: TextAlign.center,
                style: AppFonts.regular16().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.016
                          : isTablet
                          ? 0.025
                          : 0.04),
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'This action cannot be undone. All your data including:',
                textAlign: TextAlign.center,
                style: AppFonts.regular14().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.014
                          : isTablet
                          ? 0.022
                          : 0.035),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem(
                    '• Profile information',
                    screenWidth,
                    isTablet,
                    isLargeScreen,
                  ),
                  _buildWarningItem(
                    '• Vehicle registrations',
                    screenWidth,
                    isTablet,
                    isLargeScreen,
                  ),
                  _buildWarningItem(
                    '• Message history',
                    screenWidth,
                    isTablet,
                    isLargeScreen,
                  ),
                  _buildWarningItem(
                    '• Account preferences',
                    screenWidth,
                    isTablet,
                    isLargeScreen,
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'will be permanently deleted.',
                textAlign: TextAlign.center,
                style: AppFonts.regular14().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.014
                          : isTablet
                          ? 0.022
                          : 0.035),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.035,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize:
                            screenWidth *
                            (isLargeScreen
                                ? 0.016
                                : isTablet
                                ? 0.025
                                : 0.04),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleDeleteAccount(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.darkRed,
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.035,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Delete Forever',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            screenWidth *
                            (isLargeScreen
                                ? 0.016
                                : isTablet
                                ? 0.025
                                : 0.04),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningItem(
    String text,
    double screenWidth,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: AppFonts.regular14().copyWith(
          fontSize:
              screenWidth *
              (isLargeScreen
                  ? 0.013
                  : isTablet
                  ? 0.02
                  : 0.032),
          color: AppColors.darkRed.withOpacity(0.8),
        ),
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkRed),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                'Deleting Account...',
                style: AppFonts.regular16().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.016
                          : isTablet
                          ? 0.025
                          : 0.04),
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Please wait while we process your request',
                textAlign: TextAlign.center,
                style: AppFonts.regular14().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.014
                          : isTablet
                          ? 0.022
                          : 0.035),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Call the delete account API
      final success = await AuthService.deleteUserAccount();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (success) {
        // Clear app state
        ref.read(appStateProvider.notifier).logout(ref);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: AppColors.darkGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Navigate to login page and clear all routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // Replace with your login route
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showSnackBar(
            'Failed to delete account. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      String errorMessage = 'Failed to delete account';
      if (e is ConnectivityException) {
        errorMessage =
            'No internet connection. Please check your network and try again.';
      } else if (e is AuthException) {
        errorMessage = 'Authentication error. Please login again.';
      } else if (e is ApiException) {
        errorMessage = 'Server error. Please try again later.';
      }

      if (mounted) {
        _showSnackBar(errorMessage, isError: true);
      }
    }
  }
  // lib/screens/profile_page.dart - Updated logout dialog in your existing code

  // Replace your existing logout dialog code with this enhanced version:

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 20,
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_outlined,
                  color: AppColors.primary,
                  size:
                      screenWidth *
                      (isLargeScreen
                          ? 0.03
                          : isTablet
                          ? 0.04
                          : 0.06),
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'Logout',
                style: AppFonts.bold20().copyWith(
                  fontSize:
                      screenWidth *
                      (isLargeScreen
                          ? 0.02
                          : isTablet
                          ? 0.03
                          : 0.045),
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            textAlign: TextAlign.center,
            style: AppFonts.regular16().copyWith(
              fontSize:
                  screenWidth *
                  (isLargeScreen
                      ? 0.016
                      : isTablet
                      ? 0.025
                      : 0.04),
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.035,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize:
                            screenWidth *
                            (isLargeScreen
                                ? 0.016
                                : isTablet
                                ? 0.025
                                : 0.04),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog first
                      await _performLogout(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.035,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            screenWidth *
                            (isLargeScreen
                                ? 0.016
                                : isTablet
                                ? 0.025
                                : 0.04),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Add this new method to handle the logout process
  Future<void> _performLogout(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Logging out...', style: AppFonts.regular16()),
              ],
            ),
          ),
    );

    try {
      // Use the enhanced logout from AuthService
      await AuthService.logout(context);

      // Clear app state
      ref.read(appStateProvider.notifier).logout(ref);

      // Show success message (this will show on the login page)
      _showSnackBar('Logged out successfully', isError: false);
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Handle different types of errors
      String errorMessage = 'Logout failed. Please try again.';

      if (e.toString().contains('network') ||
          e.toString().contains('internet')) {
        errorMessage =
            'Network error during logout. You have been signed out locally.';
      } else if (e.toString().contains('timeout')) {
        errorMessage =
            'Logout request timed out. You have been signed out locally.';
      }

      _showSnackBar(errorMessage, isError: true);
    }
  }
}
