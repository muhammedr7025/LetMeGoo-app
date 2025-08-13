import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/screens/privacy_preferences_page.dart';
import 'package:letmegoo/utils/core_utils.dart';
import 'package:letmegoo/widgets/commonbutton.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/models/vehicle_type.dart';
import 'vehicle_add_success_page.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  VehicleType? selectedVehicleType;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingTypes = true;

  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Vehicle types from API
  List<VehicleType> vehicleTypes = [];

  // Fuel type options
  final List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
    'LPG',
    'Other',
  ];
  String? selectedFuelType;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _brandController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      setState(() {
        _isLoadingTypes = true;
      });

      final types = await AuthService.getVehicleTypes();

      setState(() {
        vehicleTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTypes = false;
      });
      _showSnackBar(
        'Failed to load vehicle types: ${e.toString()}',
        isError: true,
      );
    }
  }

  bool _isFormValid() {
    return selectedVehicleType != null &&
        _registrationController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showSnackBar('Image selected successfully', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
    }
  }

  void _showImageSourceDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Select image source',
            style: AppFonts.semiBold18().copyWith(
              fontSize:
                  screenWidth *
                  (isLargeScreen
                      ? 0.02
                      : isTablet
                      ? 0.03
                      : 0.045),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
              child: Text(
                'Camera',
                style: TextStyle(
                  color: AppColors.primary,
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
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
              child: Text(
                'Gallery',
                style: TextStyle(
                  color: AppColors.primary,
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
          ],
        );
      },
    );
  }

  Future<void> _createVehicle() async {
    if (!_isFormValid()) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicle = await AuthService.createVehicle(
        vehicleNumber: _registrationController.text.trim(),
        vehicleType: selectedVehicleType!.value,
        name:
            _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
        brand:
            _brandController.text.trim().isNotEmpty
                ? _brandController.text.trim()
                : null,
        fuelType: selectedFuelType?.toLowerCase(),
        image: _selectedImage,
      );

      if (vehicle != null) {
        _showSnackBar(
          'Vehicle "${vehicle.displayName}" added successfully!',
          isError: false,
        );

        // Navigate to success page with vehicle data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VehicleAddSuccessPage()),
        );
      } else {
        _showSnackBar(
          'Failed to add vehicle. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
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
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.02),

                    // Lock Image - Responsive
                    Image.asset(
                      AppImages.lock,
                      height:
                          screenWidth *
                          (isLargeScreen
                              ? 0.15
                              : isTablet
                              ? 0.2
                              : 0.35),
                      width:
                          screenWidth *
                          (isLargeScreen
                              ? 0.15
                              : isTablet
                              ? 0.2
                              : 0.35),
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    // Title - Responsive
                    Text(
                      'Add a Vehicle',
                      style: AppFonts.bold24().copyWith(
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
                    Text(
                      'Vehicle type and registration number are required',
                      style: AppFonts.regular14().copyWith(
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

                    SizedBox(height: screenHeight * 0.04),

                    // Form Container - Responsive width
                    Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            isLargeScreen
                                ? 500
                                : isTablet
                                ? 400
                                : double.infinity,
                      ),
                      child: Column(
                        children: [
                          // Vehicle Type Dropdown (Required)
                          _isLoadingTypes
                              ? Container(
                                height: screenHeight * 0.07,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Loading vehicle types...',
                                        style: AppFonts.regular14(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              : DropdownButtonFormField<VehicleType>(
                                value: selectedVehicleType,
                                style: TextStyle(
                                  fontSize:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.016
                                          : isTablet
                                          ? 0.025
                                          : 0.04),
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Vehicle Type *',
                                  hintText: 'Select Your Vehicle Type',
                                  labelStyle: TextStyle(
                                    fontSize:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.014
                                            : isTablet
                                            ? 0.022
                                            : 0.035),
                                    color: AppColors.textSecondary,
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.014
                                            : isTablet
                                            ? 0.022
                                            : 0.035),
                                    color: AppColors.textSecondary.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.02,
                                  ),
                                ),
                                onChanged:
                                    _isLoading
                                        ? null
                                        : (value) {
                                          setState(() {
                                            selectedVehicleType = value;
                                          });
                                        },
                                items:
                                    vehicleTypes.map((VehicleType type) {
                                      return DropdownMenuItem<VehicleType>(
                                        value: type,
                                        child: Text(
                                          type.displayName,
                                          style: TextStyle(
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
                                      );
                                    }).toList(),
                                dropdownColor: AppColors.background,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.primary,
                                  size:
                                      screenWidth *
                                      (isLargeScreen
                                          ? 0.025
                                          : isTablet
                                          ? 0.035
                                          : 0.06),
                                ),
                              ),

                          SizedBox(height: screenHeight * 0.025),

                          // Registration Number Field (Required)
                          _buildTextField(
                            controller: _registrationController,
                            labelText: 'Registration Number *',
                            hintText: 'KL00AA0000',
                            enabled: !_isLoading,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            isTablet: isTablet,
                            isLargeScreen: isLargeScreen,
                            onChanged: (value) => setState(() {}),
                          ),

                          SizedBox(height: screenHeight * 0.025),

                          // Vehicle Name Field (Optional)
                          _buildTextField(
                            controller: _nameController,
                            labelText: 'Vehicle Name (Optional)',
                            hintText: 'My favorite car',
                            enabled: !_isLoading,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            isTablet: isTablet,
                            isLargeScreen: isLargeScreen,
                          ),

                          SizedBox(height: screenHeight * 0.025),

                          // Brand Field (Optional)
                          _buildTextField(
                            controller: _brandController,
                            labelText: 'Brand (Optional)',
                            hintText: 'Toyota, Honda, etc.',
                            enabled: !_isLoading,
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            isTablet: isTablet,
                            isLargeScreen: isLargeScreen,
                          ),

                          SizedBox(height: screenHeight * 0.025),

                          // Fuel Type Dropdown (Optional)
                          DropdownButtonFormField<String>(
                            value: selectedFuelType,
                            style: TextStyle(
                              fontSize:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.016
                                      : isTablet
                                      ? 0.025
                                      : 0.04),
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Fuel Type (Optional)',
                              hintText: 'Select Fuel Type',
                              labelStyle: TextStyle(
                                fontSize:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.014
                                        : isTablet
                                        ? 0.022
                                        : 0.035),
                                color: AppColors.textSecondary,
                              ),
                              hintStyle: TextStyle(
                                fontSize:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.014
                                        : isTablet
                                        ? 0.022
                                        : 0.035),
                                color: AppColors.textSecondary.withOpacity(0.6),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.02,
                              ),
                            ),
                            onChanged:
                                _isLoading
                                    ? null
                                    : (value) {
                                      setState(() {
                                        selectedFuelType = value;
                                      });
                                    },
                            items:
                                fuelTypes.map((String fuel) {
                                  return DropdownMenuItem<String>(
                                    value: fuel,
                                    child: Text(
                                      fuel,
                                      style: TextStyle(
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
                                  );
                                }).toList(),
                            dropdownColor: AppColors.background,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                              size:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.025
                                      : isTablet
                                      ? 0.035
                                      : 0.06),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Add Image Container - Responsive
                          GestureDetector(
                            onTap: _isLoading ? null : _showImageSourceDialog,
                            child: Container(
                              width:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.4
                                      : isTablet
                                      ? 0.6
                                      : 0.75),
                              height: screenHeight * 0.07,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.textSecondary.withOpacity(
                                    0.3,
                                  ),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    _selectedImage != null
                                        ? AppColors.lightGreen.withOpacity(0.1)
                                        : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedImage != null
                                        ? Icons.check_circle
                                        : Icons.camera_alt_outlined,
                                    color:
                                        _selectedImage != null
                                            ? AppColors.darkGreen
                                            : AppColors.textSecondary,
                                    size:
                                        screenWidth *
                                        (isLargeScreen
                                            ? 0.025
                                            : isTablet
                                            ? 0.035
                                            : 0.06),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Text(
                                      _selectedImage != null
                                          ? 'Image selected'
                                          : 'Add an image of vehicle (Optional)',
                                      style: AppFonts.regular16().copyWith(
                                        fontSize:
                                            screenWidth *
                                            (isLargeScreen
                                                ? 0.016
                                                : isTablet
                                                ? 0.025
                                                : 0.04),
                                        color:
                                            _selectedImage != null
                                                ? AppColors.darkGreen
                                                : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Show selected image preview
                          if (_selectedImage != null) ...[
                            SizedBox(height: screenHeight * 0.02),
                            Container(
                              height: screenHeight * 0.15,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.darkRed,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: AppColors.white,
                                            size: 16,
                                          ),
                                        ),
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
                  ],
                ),
              ),
            ),

            // Fixed Bottom Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.075,
                vertical: screenHeight * 0.01,
              ),
              child: Column(
                children: [
                  // Add Vehicle Button
                  CommonButton(
                    text: _isLoading ? "Adding Vehicle..." : "Add Vehicle",
                    onTap:
                        (_isFormValid() && !_isLoading)
                            ? _createVehicle
                            : () {},
                    backgroundColor:
                        (_isFormValid() && !_isLoading)
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.3),
                    isEnabled: _isFormValid() && !_isLoading,
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Skip Button
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PrivacyPreferencesPage(
                                        currentPreference: 'private',
                                        isOnboarding:
                                            true, // This tells the page it's part of onboarding flow
                                        onPreferenceChanged: (newPreference) {
                                          // This callback will handle navigation to home after privacy setting is updated
                                          CoreUtil.goToHomePage(context);
                                        },
                                      ),
                                ),
                              );
                            },
                    child: Text(
                      'Skip this step',
                      style: TextStyle(
                        fontSize:
                            screenWidth *
                            (isLargeScreen
                                ? 0.014
                                : isTablet
                                ? 0.025
                                : 0.035),
                        color:
                            _isLoading
                                ? AppColors.textSecondary
                                : AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            _isLoading
                                ? AppColors.textSecondary
                                : AppColors.primary,
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool enabled,
    required double screenWidth,
    required double screenHeight,
    required bool isTablet,
    required bool isLargeScreen,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(
        fontSize:
            screenWidth *
            (isLargeScreen
                ? 0.016
                : isTablet
                ? 0.025
                : 0.04),
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          fontSize:
              screenWidth *
              (isLargeScreen
                  ? 0.014
                  : isTablet
                  ? 0.022
                  : 0.035),
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontSize:
              screenWidth *
              (isLargeScreen
                  ? 0.014
                  : isTablet
                  ? 0.022
                  : 0.035),
          color: AppColors.textSecondary.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
      ),
    );
  }
}
