import 'package:flutter/material.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:letmegoo/widgets/commonbutton.dart';
import 'package:letmegoo/services/auth_service.dart';

class PrivacyPreferencesPage extends StatefulWidget {
  final String currentPreference;
  final Function(String) onPreferenceChanged;
  final bool isOnboarding; // Added parameter to detect onboarding flow

  const PrivacyPreferencesPage({
    super.key,
    required this.currentPreference,
    required this.onPreferenceChanged,
    this.isOnboarding =
        false, // Default to false for existing usage from profile page
  });

  @override
  State<PrivacyPreferencesPage> createState() => _PrivacyPreferencesPageState();
}

class _PrivacyPreferencesPageState extends State<PrivacyPreferencesPage> {
  String? _selectedOption;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Map the current preference to the UI value
    _selectedOption = _mapApiToUiValue(widget.currentPreference);
  }

  // Map API values to UI values
  String _mapApiToUiValue(String apiValue) {
    switch (apiValue.toLowerCase()) {
      case 'public':
        return 'all';
      case 'private':
        return 'private';
      case 'anonymous':
        return 'anonymous';
      default:
        return 'all'; // Default fallback
    }
  }

  // Map UI values to API values
  String _mapUiToApiValue(String uiValue) {
    switch (uiValue) {
      case 'all':
        return 'public';
      case 'private':
        return 'private';
      case 'anonymous':
        return 'anonymous';
      default:
        return 'public'; // Default fallback
    }
  }

  Future<void> _updatePrivacyPreference() async {
    if (_selectedOption == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiValue = _mapUiToApiValue(_selectedOption!);
      final result = await AuthService.updatePrivacyPreference(apiValue);

      if (result != null) {
        // Success - call the callback with the new preference
        widget.onPreferenceChanged(apiValue);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Privacy preference updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Only pop if this is NOT part of onboarding flow
          // During onboarding, the callback should handle navigation to home
          if (!widget.isOnboarding) {
            Navigator.pop(context);
          }
        }
      }
    } on ConnectivityException catch (e) {
      _showErrorDialog('Connection Error', e.message);
    } on AuthException catch (e) {
      _showErrorDialog('Authentication Error', e.message);
    } on ApiException catch (e) {
      _showErrorDialog('Error', e.message);
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: 20,
          ),
          child: Column(
            children: [
              // Back button - only show if not in onboarding flow
              if (!widget.isOnboarding)
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: widget.isOnboarding ? 60 : 40),

              // Title
              Text(
                'Privacy Preferences',
                style: AppFonts.semiBold24(color: Colors.black),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Subtitle
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 16,
                ),
                child: Text(
                  widget.isOnboarding
                      ? "Choose what details you'd like to make visible\nwhen someone needs to contact you about your vehicle."
                      : "Choose what details you'd like to make visible\nto the person who reported your vehicle.",
                  style: AppFonts.regular16(color: const Color(0xFF656565)),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: isSmallScreen ? 30 : 40),

              // Radio options
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Option 1 - Show All Details (maps to 'public')
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: RadioListTile<String>(
                          value: 'all',
                          groupValue: _selectedOption,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (val) =>
                                      setState(() => _selectedOption = val),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: 8,
                          ),
                          title: Text(
                            'Show All Details',
                            style: AppFonts.regular16(color: Colors.black),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Will show all details including name, email\nand phone number',
                              style: AppFonts.regular13(
                                color: const Color(0xFF656565),
                              ),
                            ),
                          ),
                          activeColor: const Color(0xFF31C5F4),
                          visualDensity: VisualDensity.comfortable,
                        ),
                      ),

                      // Option 2 - Show Only Name (maps to 'private')
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: RadioListTile<String>(
                          value: 'private',
                          groupValue: _selectedOption,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (val) =>
                                      setState(() => _selectedOption = val),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: 8,
                          ),
                          title: Text(
                            'Show Only Name',
                            style: AppFonts.regular16(color: Colors.black),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Will show name. Email and phone number\nwill be hidden',
                              style: AppFonts.regular13(
                                color: const Color(0xFF656565),
                              ),
                            ),
                          ),
                          activeColor: const Color(0xFF31C5F4),
                          visualDensity: VisualDensity.comfortable,
                        ),
                      ),

                      // Option 3 - Stay Anonymous (maps to 'anonymous')
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: RadioListTile<String>(
                          value: 'anonymous',
                          groupValue: _selectedOption,
                          onChanged:
                              _isLoading
                                  ? null
                                  : (val) =>
                                      setState(() => _selectedOption = val),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: 8,
                          ),
                          title: Text(
                            'Stay Anonymous',
                            style: AppFonts.regular16(color: Colors.black),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Everything including name, email and phone\nnumber will be hidden',
                              style: AppFonts.regular13(
                                color: const Color(0xFF656565),
                              ),
                            ),
                          ),
                          activeColor: const Color(0xFF31C5F4),
                          visualDensity: VisualDensity.comfortable,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Done button
              Padding(
                padding: EdgeInsets.only(
                  bottom: isSmallScreen ? 16 : 20,
                  top: 20,
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF31C5F4),
                              ),
                            ),
                          ),
                        )
                        : CommonButton(
                          text: "Done",
                          onTap: _updatePrivacyPreference,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
