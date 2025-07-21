import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:letmegoo/constants/app_images.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/screens/owner_not_found_page.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'package:letmegoo/services/location_service.dart';
import 'package:letmegoo/widgets/commonButton.dart';
import 'package:letmegoo/models/report_request.dart';
import 'package:letmegoo/models/vehicle.dart';
import 'package:letmegoo/screens/vehicle_found_page.dart';
import 'package:letmegoo/widgets/main_app.dart';
import '../../widgets/custom_bottom_nav.dart';

// State Management with Riverpod - FIXED the syntax error here
final reportStateProvider = StateNotifierProvider<
  ReportStateNotifier,
  AsyncValue<Map<String, dynamic>?>
>((ref) {
  return ReportStateNotifier();
});

final vehicleSearchProvider =
    StateNotifierProvider<VehicleSearchNotifier, AsyncValue<Vehicle?>>((ref) {
      return VehicleSearchNotifier();
    });

class ReportStateNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ReportStateNotifier() : super(const AsyncValue.data(null));

  Future<void> reportVehicle(ReportRequest request) async {
    state = const AsyncValue.loading();
    try {
      final result = await AuthService.reportVehicle(request);
      if (mounted) {
        state = AsyncValue.data(result);
      }
    } catch (e) {
      if (mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}

class VehicleSearchNotifier extends StateNotifier<AsyncValue<Vehicle?>> {
  VehicleSearchNotifier() : super(const AsyncValue.data(null));

  Future<void> searchVehicle(String registrationNumber) async {
    state = const AsyncValue.loading();
    try {
      final vehicle = await AuthService.getVehicleByRegistrationNumber(
        registrationNumber,
      );

      if (mounted) {
        state = AsyncValue.data(vehicle);
      }
    } catch (e) {
      if (mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}

// Message options enum
enum MessageOption {
  blocking(
    'Blocking Path',
    'Your vehicle XXXX is blocking my way, please provide assistance to unblock my way. Thank you.',
  ),
  parkingIssue(
    'Parking Issue',
    'Please come and visit your vehicle, it\'s parking light is on/its key is in it.',
  );

  const MessageOption(this.displayText, this.messageTemplate);
  final String displayText;
  final String messageTemplate;
}

// UI Component
class CreateReportPage extends ConsumerStatefulWidget {
  final String? registrationNumber;
  final Function(int)? onNavigate;
  final VoidCallback? onAddPressed;

  const CreateReportPage({
    super.key,
    this.registrationNumber,
    this.onNavigate,
    this.onAddPressed,
  });

  @override
  ConsumerState<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends ConsumerState<CreateReportPage> {
  final TextEditingController regNumberController = TextEditingController();
  final LocationService _locationService = LocationService();

  bool isAnonymous = true;
  List<File> _images = [];
  bool _isLocationLoading = false;
  MessageOption? selectedMessageOption;
  bool get isReportMode => widget.registrationNumber != null;

  @override
  void initState() {
    super.initState();
    // If registration number is passed, populate the field
    if (widget.registrationNumber != null) {
      regNumberController.text = widget.registrationNumber!;
    }
  }

  @override
  void dispose() {
    regNumberController.dispose();
    super.dispose();
  }

  // Get the final message with vehicle number replaced
  String _getFinalMessage() {
    if (selectedMessageOption == null) return '';

    final vehicleNumber = regNumberController.text.trim();
    return selectedMessageOption!.messageTemplate.replaceAll(
      'XXXX',
      vehicleNumber,
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        _images = picked.map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  Future<Position?> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Use medium accuracy to avoid GNSS callbacks
      final result = await _locationService.getCurrentLocation(
        accuracy: LocationAccuracy.medium, // Explicitly set to medium
        timeLimit: const Duration(seconds: 15),
      );

      if (result.isSuccess) {
        return result.position;
      } else {
        // Handle different error types including system errors
        switch (result.errorType) {
          case LocationErrorType.serviceDisabled:
            LocationService.showLocationServiceDialog(context);
            break;
          case LocationErrorType.permissionDenied:
            LocationService.showPermissionDeniedDialog(
              context,
              onRetry: _getCurrentLocation,
            );
            break;
          case LocationErrorType.permissionPermanentlyDenied:
            LocationService.showPermissionPermanentlyDeniedDialog(context);
            break;
          case LocationErrorType.systemError:
            LocationService.showSystemErrorDialog(
              context,
              message: result.errorMessage,
            );
            break;
          case LocationErrorType.locationError:
            LocationService.showLocationErrorDialog(
              context,
              message: result.errorMessage,
              onRetry: _getCurrentLocation,
            );
            break;
          default:
            LocationService.showLocationErrorDialog(context);
        }
        return null;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<String> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    return await _locationService.getAddressFromCoordinates(
      latitude,
      longitude,
    );
  }

  void _showFullScreenDialog(
    String title,
    String content, {
    bool isError = false,
    VoidCallback? onOkPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog.fullscreen(
            child: Container(
              color: AppColors.background,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 80,
                      color: isError ? AppColors.darkRed : AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: AppFonts.semiBold24(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        content,
                        style: AppFonts.regular16().copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CommonButton(
                        text: "OK",
                        onTap:
                            onOkPressed ??
                            () {
                              Navigator.of(context).pop();
                              if (!isError) {
                                Navigator.of(
                                  context,
                                ).pop(); // Go back to previous screen
                              }
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _handleSearchTap() {
    final regNumber = regNumberController.text.trim();

    if (regNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a registration number"),
          backgroundColor: AppColors.darkRed,
        ),
      );
      return;
    }

    ref.read(vehicleSearchProvider.notifier).searchVehicle(regNumber);
  }

  void _handleInformTap() async {
    final regNumber = regNumberController.text.trim();

    if (regNumber.isEmpty || selectedMessageOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all required fields"),
          backgroundColor: AppColors.darkRed,
        ),
      );
      return;
    }

    // Get current location
    Position? position = await _getCurrentLocation();
    if (position == null) {
      // Location was not obtained, user was already notified
      return;
    }

    // Get address from coordinates (optional)
    String location = await _getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final finalMessage = _getFinalMessage();

    final request = ReportRequest(
      vehicleId: regNumber, // Using registration number as vehicleId
      images: _images,
      isAnonymous: isAnonymous,
      notes: finalMessage, // Use the generated message
      longitude: position.longitude.toString(),
      latitude: position.latitude.toString(),
      location: location,
    );

    ref.read(reportStateProvider.notifier).reportVehicle(request);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Listen to vehicle search state changes
    ref.listen<AsyncValue<Vehicle?>>(vehicleSearchProvider, (previous, next) {
      next.when(
        data: (vehicle) {
          if (vehicle != null) {
            // Navigate to notify page with vehicle data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleFoundPage(vehicle: vehicle),
              ),
            );
            // ref.read(vehicleSearchProvider.notifier).resetState();
          } else {
            // Show vehicle not registered dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OwnerNotFoundPage()),
            );
          }
        },
        error: (error, stackTrace) {
          _showFullScreenDialog(
            "Error",
            "Failed to search vehicle. Please try again.",
            isError: true,
          );
          ref.read(vehicleSearchProvider.notifier).resetState();
        },
        loading: () {},
      );
    });

    // Listen to report state changes
    ref.listen<AsyncValue<Map<String, dynamic>?>>(reportStateProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (data) {
          if (data != null) {
            _showFullScreenDialog(
              "Report Submitted",
              "Your report has been submitted successfully. The vehicle owner will be notified.",
              onOkPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => MainApp(),
                  ), // Replace with your home page widget
                  (Route<dynamic> route) => false,
                );
              },
            );
            ref.read(reportStateProvider.notifier).resetState();
          }
        },
        error: (error, stackTrace) {
          print("Error submitting report: $error \n StackTrace: $stackTrace");
          _showFullScreenDialog(
            "Error",
            "Failed to submit report. Please try again.",
            isError: true,
          );
          ref.read(reportStateProvider.notifier).resetState();
        },
        loading: () {},
      );
    });

    final reportState = ref.watch(reportStateProvider);
    final vehicleSearchState = ref.watch(vehicleSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isLargeScreen ? 600 : double.infinity,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.02),

                          // Angry Lock Image
                          Image.asset(
                            AppImages.home,
                            height:
                                screenWidth *
                                (isLargeScreen
                                    ? 0.2
                                    : isTablet
                                    ? 0.25
                                    : 0.4),
                            width:
                                screenWidth *
                                (isLargeScreen
                                    ? 0.2
                                    : isTablet
                                    ? 0.25
                                    : 0.4),
                            fit: BoxFit.contain,
                          ),

                          SizedBox(height: screenHeight * 0.02),

                          // Title
                          Text(
                            isReportMode
                                ? "Inform Owner"
                                : "Let's get the help",
                            textAlign: TextAlign.center,
                            style: AppFonts.semiBold24().copyWith(
                              fontSize:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.025
                                      : isTablet
                                      ? 0.035
                                      : 0.055),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.015),

                          // Description
                          Text(
                            isReportMode
                                ? "Fill in the details below so we can alert the\nowner and get things moving quickly."
                                : "Search whether the vehicle owner blocking\nyour way is registered with us or not!",
                            textAlign: TextAlign.center,
                            style: AppFonts.regular14().copyWith(
                              fontSize:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.014
                                      : isTablet
                                      ? 0.025
                                      : 0.035),
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Registration Number Field
                          TextField(
                            controller: regNumberController,
                            readOnly:
                                isReportMode, // Make readonly in report mode
                            style: TextStyle(
                              fontSize:
                                  screenWidth *
                                  (isLargeScreen
                                      ? 0.016
                                      : isTablet
                                      ? 0.025
                                      : 0.04),
                              color:
                                  isReportMode
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: "KL00AA0000",
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
                              labelText: "Registration Number",
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
                              filled: isReportMode,
                              fillColor:
                                  isReportMode
                                      ? AppColors.textSecondary.withOpacity(0.1)
                                      : null,
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
                          ),

                          // Show additional fields only in report mode
                          if (isReportMode) ...[
                            SizedBox(height: screenHeight * 0.025),

                            // Message Type Dropdown
                            DropdownButtonFormField<MessageOption>(
                              value: selectedMessageOption,
                              decoration: InputDecoration(
                                labelText: "Select Message Type",
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
                              items:
                                  MessageOption.values.map((option) {
                                    return DropdownMenuItem<MessageOption>(
                                      value: option,
                                      child: Text(
                                        option.displayText,
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
                              onChanged: (MessageOption? newValue) {
                                setState(() {
                                  selectedMessageOption = newValue;
                                });
                              },
                              hint: Text(
                                "Choose a message type",
                                style: TextStyle(
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
                              ),
                            ),

                            // Show message preview if option is selected
                            if (selectedMessageOption != null) ...[
                              SizedBox(height: screenHeight * 0.02),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(screenWidth * 0.04),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.preview,
                                          color: AppColors.primary,
                                          size: screenWidth * 0.04,
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          'Message Preview:',
                                          style: AppFonts.semiBold14().copyWith(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenWidth * 0.02),
                                    Text(
                                      _getFinalMessage(),
                                      style: AppFonts.regular14().copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: screenHeight * 0.025),

                            // Add Images Button
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width:
                                    screenWidth *
                                    (isLargeScreen
                                        ? 0.4
                                        : isTablet
                                        ? 0.6
                                        : 0.75),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.018,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.3,
                                    ),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      color: AppColors.textSecondary,
                                      size:
                                          screenWidth *
                                          (isLargeScreen
                                              ? 0.025
                                              : isTablet
                                              ? 0.035
                                              : 0.055),
                                    ),
                                    SizedBox(width: screenWidth * 0.025),
                                    Text(
                                      "Add images of vehicle",
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
                                  ],
                                ),
                              ),
                            ),

                            // Show selected images
                            if (_images.isNotEmpty) ...[
                              SizedBox(height: screenHeight * 0.02),
                              SizedBox(
                                height: screenHeight * 0.15,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.file(
                                              _images[index],
                                              height: screenHeight * 0.15,
                                              width: screenHeight * 0.15,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _images.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
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
                                    );
                                  },
                                ),
                              ),
                            ],

                            SizedBox(height: screenHeight * 0.03),

                            // Anonymous Checkbox
                            Row(
                              children: [
                                Transform.scale(
                                  scale:
                                      isLargeScreen
                                          ? 1.2
                                          : isTablet
                                          ? 1.1
                                          : 1.0,
                                  child: Checkbox(
                                    value: isAnonymous,
                                    onChanged: (val) {
                                      setState(() {
                                        isAnonymous = val ?? false;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                    checkColor: AppColors.white,
                                    side: BorderSide(
                                      color:
                                          isAnonymous
                                              ? AppColors.primary
                                              : AppColors.textSecondary
                                                  .withOpacity(0.5),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Text(
                                    "Do you want to keep your identity anonymous",
                                    style: AppFonts.regular16().copyWith(
                                      fontSize:
                                          screenWidth *
                                          (isLargeScreen
                                              ? 0.014
                                              : isTablet
                                              ? 0.025
                                              : 0.038),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          SizedBox(height: screenHeight * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Bottom Button
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.075,
                    vertical: screenHeight * 0.02,
                  ),
                  child: CommonButton(
                    text: _getButtonText(),
                    onTap: _getButtonAction(),
                  ),
                ),

                // Bottom Navigation (only show if navigation callbacks are provided)
                if (widget.onNavigate != null)
                  CustomBottomNav(
                    currentIndex: 0,
                    onTap: widget.onNavigate!,
                    onInformPressed: widget.onAddPressed ?? () {},
                  ),
              ],
            ),

            // Loading overlay
            if (reportState.isLoading ||
                vehicleSearchState.isLoading ||
                _isLocationLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      if (_isLocationLoading) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Getting your location...",
                          style: AppFonts.regular16().copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    final reportState = ref.watch(reportStateProvider);
    final vehicleSearchState = ref.watch(vehicleSearchProvider);

    if (_isLocationLoading) return "Getting Location...";
    if (reportState.isLoading) return "Submitting...";
    if (vehicleSearchState.isLoading) return "Searching...";

    return isReportMode ? "Inform" : "Search";
  }

  VoidCallback _getButtonAction() {
    final reportState = ref.watch(reportStateProvider);
    final vehicleSearchState = ref.watch(vehicleSearchProvider);

    if (reportState.isLoading ||
        vehicleSearchState.isLoading ||
        _isLocationLoading) {
      return () {};
    }

    return isReportMode ? _handleInformTap : _handleSearchTap;
  }
}
