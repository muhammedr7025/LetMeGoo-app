// lib/widgets/reportcard.dart - Updated with map navigation functionality

import 'package:flutter/material.dart';
import 'package:letmegoo/constants/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportCard extends StatelessWidget {
  final String timeDate;
  final String status;
  final String location;
  final String message;
  final String reporter;
  final String? profileImage;
  final String? latitude;
  final String? longitude;
  // ADD THESE NEW PARAMETERS
  final List<String>? images;
  final bool? hasImages;
  final String? firstImage;

  const ReportCard({
    super.key,
    required this.timeDate,
    required this.status,
    required this.location,
    required this.message,
    required this.reporter,
    this.profileImage,
    this.latitude,
    this.longitude,
    // ADD THESE TO CONSTRUCTOR
    this.images,
    this.hasImages,
    this.firstImage,
  });

  /// Open map with coordinates
  Future<void> _openMap(BuildContext context) async {
    if (latitude == null || longitude == null) {
      _showSnackBar(
        context,
        'Location coordinates not available',
        isError: true,
      );
      return;
    }

    try {
      final double lat = double.parse(latitude!);
      final double lng = double.parse(longitude!);

      // Create map URLs for different platforms
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final String appleMapsUrl = 'https://maps.apple.com/?q=$lat,$lng';
      final String universalUrl = 'geo:$lat,$lng';

      // Try to launch in order of preference
      List<String> urls = [
        googleMapsUrl, // Works on both Android and iOS
        appleMapsUrl, // iOS fallback
        universalUrl, // Android fallback
      ];

      bool launched = false;

      for (String url in urls) {
        final Uri uri = Uri.parse(url);

        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication, // Open in external maps app
          );

          if (launched) {
            print('🗺️ Successfully opened map with: $url');
            break;
          }
        }
      }

      if (!launched) {
        _showSnackBar(context, 'No maps application available', isError: true);
      }
    } catch (e) {
      print('❌ Error opening map: $e');
      _showSnackBar(
        context,
        'Error opening map: Invalid coordinates',
        isError: true,
      );
    }
  }

  /// Show snackbar message
  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    final bool hasValidLocation = latitude != null && longitude != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  timeDate,
                  style: AppFonts.regular14().copyWith(
                    fontSize:
                        screenWidth *
                        (isLargeScreen
                            ? 0.012
                            : isTablet
                            ? 0.02
                            : 0.032),
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenWidth * 0.01,
                ),
                decoration: BoxDecoration(
                  color:
                      status.toLowerCase() == 'active'
                          ? AppColors.lightRed
                          : AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: AppFonts.semiBold14().copyWith(
                    fontSize:
                        screenWidth *
                        (isLargeScreen
                            ? 0.012
                            : isTablet
                            ? 0.02
                            : 0.032),
                    color:
                        status.toLowerCase() == 'active'
                            ? AppColors.darkRed
                            : AppColors.darkGreen,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.025),

          // Location Row (if available) - Updated with tap functionality
          if (hasValidLocation)
            Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.025),
              child: GestureDetector(
                onTap: () => _openMap(context), // Add tap functionality here
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenWidth * 0.015,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                    // Add subtle background to indicate it's clickable
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: screenWidth * 0.04,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Flexible(
                        child: Text(
                          "View vehicle location on map",
                          style: AppFonts.regular14().copyWith(
                            fontSize:
                                screenWidth *
                                (isLargeScreen
                                    ? 0.014
                                    : isTablet
                                    ? 0.022
                                    : 0.035),
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Icon(
                        Icons.open_in_new,
                        size: screenWidth * 0.035,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Message
          Text(
            message,
            style: AppFonts.semiBold16().copyWith(
              fontSize:
                  screenWidth *
                  (isLargeScreen
                      ? 0.016
                      : isTablet
                      ? 0.025
                      : 0.04),
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: screenWidth * 0.025),

          // Images Section - With tap to view full image
          if (hasImages == true && images != null && images!.isNotEmpty) ...[
            Container(
              height: screenHeight * 0.12,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images!.length,
                itemBuilder: (context, index) {
                  final imageUrl = images![index];
                  return Container(
                    margin: EdgeInsets.only(right: screenWidth * 0.02),
                    child: GestureDetector(
                      onTap: () => _showFullImage(context, imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: screenHeight * 0.12,
                          height: screenHeight * 0.12,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: screenHeight * 0.12,
                              height: screenHeight * 0.12,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: screenWidth * 0.06,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: screenHeight * 0.12,
                              height: screenHeight * 0.12,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: screenWidth * 0.025),
          ],

          // Reporter Row
          Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.04,
                backgroundColor: AppColors.textSecondary.withOpacity(0.3),
                backgroundImage:
                    profileImage != null ? NetworkImage(profileImage!) : null,
                child:
                    profileImage == null
                        ? Icon(
                          Icons.person,
                          size: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        )
                        : null,
              ),
              SizedBox(width: screenWidth * 0.025),
              Flexible(
                child: Text(
                  "Reported by $reporter",
                  style: AppFonts.regular14().copyWith(
                    fontSize:
                        screenWidth *
                        (isLargeScreen
                            ? 0.012
                            : isTablet
                            ? 0.02
                            : 0.032),
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show full screen image dialog
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
