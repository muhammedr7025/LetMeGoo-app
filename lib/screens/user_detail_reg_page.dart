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

  bool _areAllFieldsValid() {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    return name.isNotEmpty &&
        phone.isNotEmpty &&
        phone.length == 10 &&
        email.isNotEmpty &&
        _isValidEmail(email) &&
        checkboxValue;
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
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

    if (phone.isEmpty || phone.length != 10) {
      _showSnackBar(
        "Please enter a valid 10-digit phone number",
        isError: true,
      );
      return;
    }

    if (email.isEmpty || !_isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address", isError: true);
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
      // Format phone number with country code for API
      String formattedPhone = phone.startsWith('91') ? phone : '91$phone';
      if (formattedPhone.startsWith('+')) {
        formattedPhone = formattedPhone.substring(1);
      }

      final result = await AuthService.updateUserProfile(
        fullname: name,
        email: email,
        phoneNumber: formattedPhone,
        companyName: "", // Empty company name since field is removed
      );

      if (result != null) {
        _showSnackBar("Profile updated successfully!", isError: false);

        // Navigate to next screen (Add Vehicle Page)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AddVehiclePage()),
        );
      } else {
        _showSnackBar(
          "Failed to update profile. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Error updating profile: ${e.toString()}", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                    icon: const Icon(Icons.arrow_back),
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
                    image: const DecorationImage(
                      image: AssetImage(AppImages.logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Title
                Text(
                  "Complete Your Profile",
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
                    "Please provide your details to complete your profile",
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
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading && !_isEmailReadOnly,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor:
                              _isEmailReadOnly
                                  ? Colors.grey[200]
                                  : Colors.white,
                          suffixIcon:
                              _isEmailReadOnly
                                  ? const Icon(Icons.lock_outline, size: 16)
                                  : null,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Phone Number Input
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter 10-digit phone number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          prefixText: '+91 ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '', // Hide character counter
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
                                style: AppFonts.regular13(
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
                                'Signed in with ${_currentLoginMethod.displayName}',
                                style: AppFonts.regular13(
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
