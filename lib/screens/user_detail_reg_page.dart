import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/models/login_method.dart';
import 'package:letmegoo/screens/add_vehicle_page.dart';
import 'package:letmegoo/widgets/commonbutton.dart';
import 'package:letmegoo/services/auth_service.dart';

class UserDetailRegPage extends StatefulWidget {
  final LoginMethod? loginMethod;

  const UserDetailRegPage({super.key, this.loginMethod});

  @override
  State<UserDetailRegPage> createState() => _UserDetailRegPageState();
}

class _UserDetailRegPageState extends State<UserDetailRegPage> {
  bool checkboxValue = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  LoginMethod _currentLoginMethod = LoginMethod.unknown;
  bool _isEmailReadOnly = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Determine login method
      _currentLoginMethod = _determineLoginMethod(user);

      // Pre-fill fields based on login method
      if (_currentLoginMethod == LoginMethod.google && user.email != null) {
        _emailController.text = user.email!;
        _isEmailReadOnly = true;
      } else if (_currentLoginMethod == LoginMethod.email &&
          user.email != null) {
        _emailController.text = user.email!;
        _isEmailReadOnly = true;
      }

      // Pre-fill name if available
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }

      // Pre-fill email if available and not readonly
      if (!_isEmailReadOnly && user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
    }
  }

  LoginMethod _determineLoginMethod(User user) {
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

    return LoginMethod.unknown;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  bool _isValidPhoneNumber(String phone) {
    // Phone number validation - should be 10 digits if provided
    if (phone.isEmpty) return true; // Allow empty phone number
    return phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  Future<void> _updateUserProfile() async {
    // Validate fields
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    if (name.isEmpty) {
      _showSnackBar("Please enter your full name", isError: true);
      return;
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address", isError: true);
      return;
    }

    if (phone.isNotEmpty && !_isValidPhoneNumber(phone)) {
      _showSnackBar(
        "Please enter a valid 10-digit phone number or leave it empty",
        isError: true,
      );
      return;
    }

    if (!checkboxValue) {
      _showSnackBar("Please accept the permissions to continue", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format phone number with country code if provided
      String? formattedPhone;
      if (phone.isNotEmpty) {
        formattedPhone = phone.startsWith('91') ? phone : '91$phone';
        if (formattedPhone.startsWith('+')) {
          formattedPhone = formattedPhone.substring(1);
        }
      }

      // For new users after email verification, we need to create the backend user
      // First, get a fresh Firebase token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Force token refresh to ensure we have valid auth
      await user.getIdToken(true);

      Map<String, dynamic>? result;

      // First, try to authenticate to check if user exists in backend
      try {
        result = await AuthService.authenticateUser();
        print('User exists in backend, updating profile...');
      } catch (e) {
        print('User may not exist in backend yet: $e');
        result = null;
      }

      if (result != null) {
        // User exists in backend, update their profile
        result = await AuthService.updateUserProfile(
          fullname: name,
          email: email,
          phoneNumber: formattedPhone,
          companyName: "",
        );
      } else {
        // User doesn't exist in backend yet (new user)
        // The authenticateUser endpoint should create the user if they don't exist
        // Wait a moment and try again
        print('New user detected, creating backend user...');
        await Future.delayed(const Duration(seconds: 1));

        // Try authenticate again - this should create the user
        result = await AuthService.authenticateUser();

        if (result != null) {
          // Now update the profile
          result = await AuthService.updateUserProfile(
            fullname: name,
            email: email,
            phoneNumber: formattedPhone,
            companyName: "",
          );
        }
      }

      if (result != null) {
        _showSnackBar("Profile created successfully!", isError: false);

        // Navigate to next screen (Add Vehicle Page)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AddVehiclePage()),
        );
      } else {
        _showSnackBar(
          "Failed to create profile. Please try again.",
          isError: true,
        );
      }
    } on AuthException catch (e) {
      // Handle authentication errors specifically
      print('Auth error: ${e.toString()}');

      // Check if this is a "user not found" type error
      if (e.message.toLowerCase().contains('authentication') ||
          e.message.toLowerCase().contains('user') ||
          e.message.toLowerCase().contains('token')) {
        _showSnackBar(
          "There was an issue with your account. Please sign in again.",
          isError: true,
        );

        // Sign out and redirect to login
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', // Replace with your login route
          (route) => false,
        );
      } else {
        _showSnackBar("Error: ${e.message}", isError: true);
      }
    } catch (e) {
      print('Profile creation error: ${e.toString()}');
      _showSnackBar("Error creating profile: ${e.toString()}", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
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
                SizedBox(height: screenHeight * 0.05),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Logo
                Container(
                  width:
                      screenWidth *
                      (isLargeScreen
                          ? 0.1
                          : isTablet
                          ? 0.15
                          : 0.25),
                  height:
                      screenWidth *
                      (isLargeScreen
                          ? 0.1
                          : isTablet
                          ? 0.15
                          : 0.25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Title
                Text(
                  "Complete Your Profile",
                  style: AppFonts.bold24().copyWith(
                    fontSize:
                        screenWidth *
                        (isLargeScreen
                            ? 0.025
                            : isTablet
                            ? 0.035
                            : 0.055),
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: screenHeight * 0.015),

                // Subtitle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    "Please provide your details to complete your profile",
                    style: AppFonts.regular16().copyWith(
                      fontSize:
                          screenWidth *
                          (isLargeScreen
                              ? 0.014
                              : isTablet
                              ? 0.025
                              : 0.035),
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Form Fields
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
                      // Full Name Input
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        style: AppFonts.regular16(),
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          labelStyle: AppFonts.regular14().copyWith(
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'Enter your full name',
                          hintStyle: AppFonts.regular14().copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading && !_isEmailReadOnly,
                        style: AppFonts.regular16().copyWith(
                          color:
                              _isEmailReadOnly
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          labelStyle: AppFonts.regular14().copyWith(
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'Enter your email',
                          hintStyle: AppFonts.regular14().copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              _isEmailReadOnly
                                  ? AppColors.textSecondary.withOpacity(0.1)
                                  : AppColors.background,
                          suffixIcon:
                              _isEmailReadOnly
                                  ? Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  )
                                  : null,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Phone Number Input (Optional)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        enabled: !_isLoading,
                        style: AppFonts.regular16(),
                        decoration: InputDecoration(
                          labelText: 'Phone Number (Optional)',
                          labelStyle: AppFonts.regular14().copyWith(
                            color: AppColors.textSecondary,
                          ),
                          hintText: 'Enter 10-digit phone number',
                          hintStyle: AppFonts.regular14().copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.textSecondary,
                          ),
                          prefixText: '+91 ',
                          prefixStyle: AppFonts.regular16().copyWith(
                            color: AppColors.textPrimary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          counterText: '', // Hide character counter
                          helperText: 'You can add this later in settings',
                          helperStyle: AppFonts.regular13().copyWith(
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Permissions Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: checkboxValue,
                            onChanged:
                                _isLoading
                                    ? null
                                    : (value) {
                                      setState(() {
                                        checkboxValue = value ?? false;
                                      });
                                    },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                "I agree to the Terms of Service and Privacy Policy. I also consent to receive notifications and updates.",
                                style: AppFonts.regular14().copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Continue Button
                      CommonButton(
                        text: "Continue",
                        onTap: () => _updateUserProfile(),
                        isLoading: _isLoading,
                        isEnabled: !_isLoading,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Login Method Indicator
                      if (_currentLoginMethod != LoginMethod.unknown)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentLoginMethod == LoginMethod.google
                                    ? Icons.g_mobiledata
                                    : Icons.email_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Signed in with ${_getLoginMethodDisplayName(_currentLoginMethod)}',
                                style: AppFonts.regular13().copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
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

  String _getLoginMethodDisplayName(LoginMethod method) {
    switch (method) {
      case LoginMethod.email:
        return 'Email';
      case LoginMethod.google:
        return 'Google';
      case LoginMethod.phone:
        return 'Phone';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
