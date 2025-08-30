import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/providers/user_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailReadOnly =
      true; // Email is typically read-only after registration

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final userState = ref.read(userProvider);
      if (userState.userData != null) {
        // Pre-fill form fields from existing user data
        _nameController.text = userState.userData!['fullname'] ?? '';
        _emailController.text = userState.userData!['email'] ?? '';

        // Format phone number for display (remove country code)
        String? phone = userState.userData!['phone_number']?.toString();
        if (phone != null && phone.isNotEmpty) {
          if (phone.startsWith('91') && phone.length > 2) {
            phone = phone.substring(2);
          }
          _phoneController.text = phone;
        }
      } else {
        // Fallback to API call if no cached data
        final userData = await AuthService.authenticateUser();
        if (userData != null) {
          _nameController.text = userData['fullname'] ?? '';
          _emailController.text = userData['email'] ?? '';

          String? phone = userData['phone_number']?.toString();
          if (phone != null && phone.isNotEmpty) {
            if (phone.startsWith('91') && phone.length > 2) {
              phone = phone.substring(2);
            }
            _phoneController.text = phone;
          }
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load profile: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return true; // Allow empty phone number
    return phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      String name = _nameController.text.trim();
      String phone = _phoneController.text.trim();
      String email = _emailController.text.trim();

      // Format phone number with country code if provided
      String? formattedPhone;
      if (phone.isNotEmpty) {
        formattedPhone = phone.startsWith('91') ? phone : '91$phone';
        if (formattedPhone.startsWith('+')) {
          formattedPhone = formattedPhone.substring(1);
        }
      }

      final result = await AuthService.updateUserProfile(
        fullname: name,
        email: email,
        phoneNumber: formattedPhone,
        companyName: "", // Keep existing or empty
      );

      if (result != null) {
        // Update Firebase display name if changed
        final User? firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null && firebaseUser.displayName != name) {
          await firebaseUser.updateDisplayName(name);
        }

        // Refresh user data in provider
        ref.read(userProvider.notifier).refreshUserData();

        _showSnackBar('Profile updated successfully!', isError: false);

        // Navigate back after successful update
        Navigator.pop(context);
      } else {
        _showSnackBar(
          'Failed to update profile. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error updating profile: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.regular14().copyWith(color: AppColors.white),
        ),
        backgroundColor: isError ? AppColors.darkRed : AppColors.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          'Edit Profile',
          style: AppFonts.semiBold18().copyWith(color: AppColors.textPrimary),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: AppFonts.regular16().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: 24,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Profile Picture Section
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(_nameController.text),
                                  style: AppFonts.bold24().copyWith(
                                    color: AppColors.white,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight < 700 ? 32 : 40),

                            // Form Fields
                            TextFormField(
                              controller: _nameController,
                              enabled: !_isLoading,
                              style: AppFonts.regular16().copyWith(
                                fontSize: fontSize,
                              ),
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
                              onChanged: (value) {
                                // Update avatar initials in real-time
                                setState(() {});
                              },
                            ),

                            SizedBox(height: 20),

                            TextFormField(
                              controller: _emailController,
                              enabled: !_isLoading && !_isEmailReadOnly,
                              keyboardType: TextInputType.emailAddress,
                              style: AppFonts.regular16().copyWith(
                                fontSize: fontSize,
                                color:
                                    _isEmailReadOnly
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                              ),
                              decoration: _buildInputDecoration(
                                'Email Address *',
                                Icons.email_outlined,
                                fontSize,
                                suffixIcon:
                                    _isEmailReadOnly
                                        ? Icon(
                                          Icons.lock_outline,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        )
                                        : null,
                                filled: _isEmailReadOnly,
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

                            SizedBox(height: 20),

                            TextFormField(
                              controller: _phoneController,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: AppFonts.regular16().copyWith(
                                fontSize: fontSize,
                              ),
                              decoration: _buildInputDecoration(
                                'Phone Number (Optional)',
                                Icons.phone_outlined,
                                fontSize,
                                prefixText: '+91 ',
                                counterText: '',
                                helperText:
                                    'Leave empty if you prefer not to provide',
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    !_isValidPhoneNumber(value)) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 40),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppColors.textSecondary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: AppFonts.semiBold16().copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: fontSize,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
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
                                              'Save Changes',
                                              style: AppFonts.semiBold16()
                                                  .copyWith(
                                                    color: AppColors.white,
                                                    fontSize: fontSize,
                                                  ),
                                            ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 32),

                            // Info Note
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your email address is locked for security reasons. Contact support if you need to change it.',
                                      style: AppFonts.regular14().copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: fontSize - 2,
                                      ),
                                    ),
                                  ),
                                ],
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
    String? prefixText,
    String? counterText,
    String? helperText,
    bool filled = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppFonts.regular14().copyWith(
        color: AppColors.textSecondary,
        fontSize: fontSize - 2,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      prefixStyle: AppFonts.regular16().copyWith(
        color: AppColors.textPrimary,
        fontSize: fontSize,
      ),
      counterText: counterText,
      helperText: helperText,
      helperStyle: AppFonts.regular13().copyWith(
        color: AppColors.textSecondary.withOpacity(0.8),
      ),
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
        borderSide: BorderSide(color: AppColors.darkRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.darkRed, width: 2),
      ),
      filled: filled,
      fillColor:
          filled
              ? AppColors.textSecondary.withOpacity(0.1)
              : AppColors.background,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'
          .toUpperCase();
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
