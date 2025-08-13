import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/models/vehicle.dart';
import 'package:letmegoo/models/vehicle_type.dart';
import 'package:letmegoo/services/auth_service.dart';
import 'labeledtextfield.dart';

class Editvehicledialog extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onEdit;
  final VoidCallback onDelete;

  const Editvehicledialog({
    super.key,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<Editvehicledialog> createState() => _EditvehicledialogState();
}

class _EditvehicledialogState extends State<Editvehicledialog> {
  late TextEditingController _registrationController;
  late TextEditingController _brandController;
  late TextEditingController _nameController;

  VehicleType? selectedVehicleType;
  String? selectedFuelType;
  File? _selectedImage;

  List<VehicleType> vehicleTypes = [];

  // Fuel types matching server expectations
  final List<Map<String, String>> fuelTypes = [
    {'display': 'Petrol', 'value': 'petrol'},
    {'display': 'Diesel', 'value': 'diesel'},
    {'display': 'Electric', 'value': 'electric'},
    {'display': 'Hybrid', 'value': 'hybrid'},
    {'display': 'CNG', 'value': 'cng'},
    {'display': 'LPG', 'value': 'lpg'},
    {'display': 'Hydrogen', 'value': 'hydrogen'},
    {'display': 'Biofuel', 'value': 'biofuel'},
    {'display': 'Other', 'value': 'other'},
  ];

  bool _isLoading = false;
  bool _isLoadingTypes = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadVehicleTypes();

    // Add a delayed check to see if values are properly set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print('=== POST-INIT VALUES CHECK ===');
          print('Brand controller text: "${_brandController.text}"');
          print('Name controller text: "${_nameController.text}"');
          print(
            'Registration controller text: "${_registrationController.text}"',
          );
          print(
            'Selected vehicle type: ${selectedVehicleType?.displayName ?? 'null'}',
          );
          print('Selected fuel type: $selectedFuelType');
          print('==============================');
        }
      });
    });
  }

  void _initializeControllers() {
    _registrationController = TextEditingController(
      text: widget.vehicle.vehicleNumber,
    );
    _brandController = TextEditingController(text: widget.vehicle.brand ?? '');
    _nameController = TextEditingController(text: widget.vehicle.name);

    // Debug prints for initialization
    print('=== VEHICLE EDIT INITIALIZATION ===');
    print('Vehicle ID: ${widget.vehicle.id}');
    print('Vehicle Number: ${widget.vehicle.vehicleNumber}');
    print('Vehicle Name: ${widget.vehicle.name}');
    print('Vehicle Brand: ${widget.vehicle.brand}');
    print('Vehicle Type: ${widget.vehicle.vehicleType}');
    print('Vehicle Fuel Type: ${widget.vehicle.fuelType}');
    print('=====================================');

    // Initialize fuel type
    _initializeFuelType();
  }

  void _initializeFuelType() {
    print('=== FUEL TYPE INITIALIZATION ===');
    print('Original fuel type from vehicle: "${widget.vehicle.fuelType}"');

    if (widget.vehicle.fuelType.isNotEmpty) {
      // Clean and normalize the fuel type from database
      String cleanFuelType = widget.vehicle.fuelType.trim().toLowerCase();
      print('Cleaned fuel type: "$cleanFuelType"');

      // Handle if fuel type is stored as an object (extract value)
      if (widget.vehicle.fuelType.contains('{') &&
          widget.vehicle.fuelType.contains('}')) {
        print('🔍 Fuel type appears to be JSON object, extracting...');

        // Extract value from object format like "{key: petrol, value: Petrol}"
        RegExp valueRegex = RegExp(r'value["\s]*:["\s]*([^,}"]+)');
        Match? match = valueRegex.firstMatch(widget.vehicle.fuelType);
        if (match != null) {
          cleanFuelType = match.group(1)?.trim().toLowerCase() ?? '';
          print('🔍 Extracted value from object: "$cleanFuelType"');
        }
      }

      print('Available fuel types:');
      for (var fuel in fuelTypes) {
        print('  - display: "${fuel['display']}", value: "${fuel['value']}"');
      }

      // Find matching fuel type in our predefined list
      Map<String, String>? matchedFuel;

      // Try exact match by value
      try {
        matchedFuel = fuelTypes.firstWhere(
          (fuel) => fuel['value']?.toLowerCase() == cleanFuelType,
        );
        print('✅ Found exact match by value: ${matchedFuel['display']}');
      } catch (e) {
        print('❌ No exact match by value');

        // Try exact match by display name
        try {
          matchedFuel = fuelTypes.firstWhere(
            (fuel) => fuel['display']?.toLowerCase() == cleanFuelType,
          );
          print('✅ Found exact match by display: ${matchedFuel['display']}');
        } catch (e) {
          print('❌ No exact match by display');

          // Try partial matching
          for (final fuel in fuelTypes) {
            if (fuel['value']!.toLowerCase().contains(cleanFuelType) ||
                fuel['display']!.toLowerCase().contains(cleanFuelType) ||
                cleanFuelType.contains(fuel['value']!.toLowerCase()) ||
                cleanFuelType.contains(fuel['display']!.toLowerCase())) {
              matchedFuel = fuel;
              print('✅ Found partial match: ${matchedFuel['display']}');
              break;
            }
          }
        }
      }

      if (matchedFuel != null) {
        selectedFuelType = matchedFuel['value'];
        print(
          '🎯 Final selected fuel type: ${matchedFuel['display']} (${matchedFuel['value']})',
        );
      } else {
        print('⚠️ No fuel type match found, leaving as null');
      }
    } else {
      print('⚠️ Vehicle fuel type is empty');
    }
    print('=================================');
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final types = await AuthService.getVehicleTypes();
      print('=== VEHICLE TYPES LOADED ===');
      print('Available types count: ${types.length}');
      for (var type in types) {
        print('Type: value="${type.value}", displayName="${type.displayName}"');
      }
      print('Current vehicle type to match: "${widget.vehicle.vehicleType}"');

      setState(() {
        vehicleTypes = types;
        _isLoadingTypes = false;

        // Set initial vehicle type after types are loaded
        if (vehicleTypes.isNotEmpty && widget.vehicle.vehicleType.isNotEmpty) {
          VehicleType? matchedType;

          // First check if it's an object format (which it seems to be based on debug output)
          if (widget.vehicle.vehicleType.contains('{') ||
              widget.vehicle.vehicleType.contains(':')) {
            print(
              '🔍 Vehicle type looks like JSON object, trying to extract...',
            );

            // Try to extract from object format like {key: car, value: Car}
            // First try to extract the 'key' value (which should match our API values)
            RegExp keyRegex = RegExp(r'key["\s]*:["\s]*([^,}"]+)');
            Match? keyMatch = keyRegex.firstMatch(widget.vehicle.vehicleType);
            if (keyMatch != null) {
              String extractedKey = keyMatch.group(1)?.trim() ?? '';
              print('🔍 Extracted key from object: "$extractedKey"');

              try {
                matchedType = vehicleTypes.firstWhere(
                  (type) =>
                      type.value.toLowerCase() == extractedKey.toLowerCase(),
                );
                print(
                  '✅ Found match with extracted key: ${matchedType.displayName}',
                );
              } catch (e) {
                print('❌ No match with extracted key');
              }
            }

            // If key didn't work, try to extract the 'value' (which should match displayName)
            if (matchedType == null) {
              RegExp valueRegex = RegExp(r'value["\s]*:["\s]*([^,}"]+)');
              Match? valueMatch = valueRegex.firstMatch(
                widget.vehicle.vehicleType,
              );
              if (valueMatch != null) {
                String extractedValue = valueMatch.group(1)?.trim() ?? '';
                print('🔍 Extracted value from object: "$extractedValue"');

                try {
                  matchedType = vehicleTypes.firstWhere(
                    (type) =>
                        type.displayName.toLowerCase() ==
                        extractedValue.toLowerCase(),
                  );
                  print(
                    '✅ Found match with extracted value: ${matchedType.displayName}',
                  );
                } catch (e) {
                  print('❌ No match with extracted value either');
                }
              }
            }
          }

          // If object extraction didn't work, try direct string matching
          if (matchedType == null) {
            // Try exact match by value (case-insensitive)
            try {
              matchedType = vehicleTypes.firstWhere(
                (type) =>
                    type.value.toLowerCase().trim() ==
                    widget.vehicle.vehicleType.toLowerCase().trim(),
              );
              print('✅ Found exact match by value: ${matchedType.displayName}');
            } catch (e) {
              print('❌ No exact match by value found');

              // Try exact match by display name (case-insensitive)
              try {
                matchedType = vehicleTypes.firstWhere(
                  (type) =>
                      type.displayName.toLowerCase().trim() ==
                      widget.vehicle.vehicleType.toLowerCase().trim(),
                );
                print(
                  '✅ Found exact match by displayName: ${matchedType.displayName}',
                );
              } catch (e) {
                print('❌ No exact match by displayName found');

                // Try partial match
                try {
                  matchedType = vehicleTypes.firstWhere(
                    (type) =>
                        type.value.toLowerCase().contains(
                          widget.vehicle.vehicleType.toLowerCase(),
                        ) ||
                        type.displayName.toLowerCase().contains(
                          widget.vehicle.vehicleType.toLowerCase(),
                        ) ||
                        widget.vehicle.vehicleType.toLowerCase().contains(
                          type.value.toLowerCase(),
                        ) ||
                        widget.vehicle.vehicleType.toLowerCase().contains(
                          type.displayName.toLowerCase(),
                        ),
                  );
                  print('✅ Found partial match: ${matchedType.displayName}');
                } catch (e) {
                  print('❌ No partial match found either');
                }
              }
            }
          }

          if (matchedType != null) {
            selectedVehicleType = matchedType;
            print(
              '🎯 Final selected vehicle type: ${selectedVehicleType!.displayName}',
            );
          } else {
            // Set to first available type as fallback
            selectedVehicleType = vehicleTypes.first;
            print(
              '⚠️ No match found, using first available type: ${selectedVehicleType!.displayName}',
            );
          }
        } else if (vehicleTypes.isNotEmpty) {
          selectedVehicleType = vehicleTypes.first;
          print(
            '⚠️ Vehicle type is empty, using first available type: ${selectedVehicleType!.displayName}',
          );
        }
      });
      print('=============================');
    } catch (e) {
      print('❌ Error loading vehicle types: $e');
      setState(() {
        _isLoadingTypes = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  bool _validateForm() {
    if (selectedVehicleType == null) {
      _showSnackBar('Please select a vehicle type');
      return false;
    }
    if (_registrationController.text.trim().isEmpty) {
      _showSnackBar('Please enter registration number');
      return false;
    }
    return true;
  }

  Future<void> _updateVehicle() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual API to update the vehicle on the server
      final updatedVehicle = await AuthService.updateVehicle(
        vehicleId: widget.vehicle.id,
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
        fuelType: selectedFuelType, // No need to convert to lowercase anymore
        image: _selectedImage,
      );

      if (updatedVehicle != null) {
        // Call the callback to update the UI
        widget.onEdit(updatedVehicle);
        _showSnackBar('Vehicle updated successfully!', isError: false);

        // Don't close the dialog here - let the parent handle navigation
        // The parent (my_vehicles_page.dart) will call Navigator.pop(context)
      } else {
        _showSnackBar('Failed to update vehicle');
      }
    } on SocketException {
      _showSnackBar('Network error. Please check your connection.');
    } on TimeoutException {
      _showSnackBar('Request timeout. Please try again.');
    } catch (e) {
      // Handle other errors
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }
      _showSnackBar('Error: $errorMessage');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.darkRed : AppColors.darkGreen,
      ),
    );
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _brandController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Center(
        child: Text(
          'Edit Vehicle',
          style: AppFonts.bold18(
            color: AppColors.textPrimary,
          ).copyWith(fontSize: isTablet ? 20 : 18),
          textAlign: TextAlign.center,
        ),
      ),
      content: SizedBox(
        width: isTablet ? 400 : 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Description
              Text(
                "Update your vehicle information below. Vehicle type and registration number are required.",
                style: AppFonts.regular14(
                  color: AppColors.textSecondary,
                ).copyWith(fontSize: isTablet ? 16 : 14),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              /// Vehicle Type Dropdown
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Type *',
                      style: AppFonts.regular14(
                        color: AppColors.textPrimary,
                      ).copyWith(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingTypes
                        ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                        : DropdownButtonFormField<VehicleType>(
                          value: selectedVehicleType,
                          decoration: InputDecoration(
                            hintText: 'Select Vehicle Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                          items:
                              vehicleTypes.map((VehicleType type) {
                                return DropdownMenuItem<VehicleType>(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                          onChanged:
                              _isLoading
                                  ? null
                                  : (value) {
                                    setState(() {
                                      selectedVehicleType = value;
                                    });
                                  },
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// Registration Number Field
              Labeledtextfield(
                label: "Registration Number *",
                hint: "KL00AA0000",
                controller: _registrationController,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 12),

              /// Vehicle Name Field
              Labeledtextfield(
                label: "Vehicle Name",
                hint: "My Car",
                controller: _nameController,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 12),

              /// Brand Field
              Labeledtextfield(
                label: "Brand",
                hint: "Honda",
                controller: _brandController,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 12),

              /// Fuel Type Dropdown
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel Type',
                      style: AppFonts.regular14(
                        color: AppColors.textPrimary,
                      ).copyWith(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedFuelType,
                      decoration: InputDecoration(
                        hintText: 'Select Fuel Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items:
                          fuelTypes.map((Map<String, String> fuel) {
                            return DropdownMenuItem<String>(
                              value: fuel['value'], // Store API value
                              child: Text(
                                fuel['display']!,
                              ), // Display user-friendly name
                            );
                          }).toList(),
                      onChanged:
                          _isLoading
                              ? null
                              : (value) {
                                setState(() {
                                  selectedFuelType = value;
                                });
                              },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// Add Image Button
              SizedBox(
                width: 250,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: Icon(
                    _selectedImage != null
                        ? Icons.check_circle
                        : Icons.image_outlined,
                    color:
                        _selectedImage != null
                            ? AppColors.darkGreen
                            : AppColors.textPrimary,
                  ),
                  label: Text(
                    _selectedImage != null
                        ? "Image Selected"
                        : "Add an image of vehicle",
                    style: TextStyle(
                      color:
                          _selectedImage != null
                              ? AppColors.darkGreen
                              : AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          _selectedImage != null
                              ? AppColors.darkGreen
                              : AppColors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    foregroundColor:
                        _selectedImage != null
                            ? AppColors.darkGreen
                            : AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// Action Buttons - Matching AddVehicleDialog exactly
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: AppFonts.regular14(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  "Update Vehicle",
                                  style: TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
