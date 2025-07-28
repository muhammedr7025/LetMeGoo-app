// lib/widgets/buildreportsection.dart - Update to pass image data

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../widgets/reportcard.dart';

Widget buildReportSection({
  required BuildContext context,
  required String title,
  required List<Map<String, dynamic>> reports,
  required double screenWidth,
  required bool isTablet,
  required bool isLargeScreen,
}) {
  print('📊 Building report section: $title with ${reports.length} reports');

  // Debug: Print first report to see available data
  if (reports.isNotEmpty) {
    print('🔍 First report data: ${reports.first}');
  }

  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: screenWidth * 0.03,
      vertical: screenWidth * 0.04,
    ),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          child: Text(
            title,
            style: AppFonts.bold16().copyWith(
              fontSize:
                  screenWidth *
                  (isLargeScreen
                      ? 0.018
                      : isTablet
                      ? 0.028
                      : 0.045),
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        ...reports.map(
          (report) => Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
            child: ReportCard(
              timeDate: report['timeDate'] ?? 'Unknown Time',
              status: report['status'] ?? 'Unknown',
              location: report['location'] ?? 'Unknown Location',
              message: report['message'] ?? 'No message',
              reporter: report['reporter'] ?? 'Unknown',
              profileImage: report['profileImage'],
              latitude: report['latitude'],
              longitude: report['longitude'],
              // ADD THESE NEW PARAMETERS
              images: (report['images'] as List<dynamic>?)?.cast<String>(),
              hasImages: report['hasImages'] ?? false,
              firstImage: report['firstImage'],
            ),
          ),
        ),
      ],
    ),
  );
}
