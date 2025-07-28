class Report {
  final String id;
  final int reportNumber;
  final ReportedVehicle vehicle;
  final String notes;
  final String currentStatus;
  final bool isClosed;
  final bool isAnonymous;
  final Reporter reporter;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? latitude;
  final String? longitude;
  final String? location;
  final List<ReportImage> images;
  final List<StatusLog> statusLogs;

  Report({
    required this.id,
    required this.reportNumber,
    required this.vehicle,
    required this.notes,
    required this.currentStatus,
    required this.isClosed,
    required this.isAnonymous,
    required this.reporter,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.location,
    required this.images,
    required this.statusLogs,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    try {
      print('📝 Parsing report: ${json['id']}');

      // Handle current_status which can be either String or Map
      String currentStatus;
      if (json['current_status'] is Map<String, dynamic>) {
        final statusMap = json['current_status'] as Map<String, dynamic>;
        currentStatus = statusMap['key']?.toString() ?? 'unknown';
        print('  - Status from map: $currentStatus');
      } else {
        currentStatus = json['current_status']?.toString() ?? 'unknown';
        print('  - Status from string: $currentStatus');
      }

      final report = Report(
        id: json['id']?.toString() ?? '',
        reportNumber: json['report_number'] ?? 0,
        vehicle: ReportedVehicle.fromJson(json['vehicle'] ?? {}),
        notes: json['notes']?.toString() ?? '',
        currentStatus: currentStatus,
        isClosed: json['is_closed'] ?? false,
        isAnonymous: json['is_anonymous'] ?? false,
        reporter: Reporter.fromJson(json['reporter'] ?? {}),
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
        latitude: json['latitude']?.toString(),
        longitude: json['longitude']?.toString(),
        location: json['location']?.toString(),
        images:
            (json['images'] as List<dynamic>?)
                ?.map((img) => ReportImage.fromJson(img))
                .toList() ??
            [],
        statusLogs:
            (json['status_logs'] as List<dynamic>?)
                ?.map((log) => StatusLog.fromJson(log))
                .toList() ??
            [],
      );

      print('✅ Successfully parsed report: ${report.id}');
      return report;
    } catch (e) {
      print('❌ Error parsing report: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }

  // Helper methods for widget compatibility
  String get formattedTimeDate => _formatDateTime(createdAt.toIso8601String());
  String get displayStatus => isClosed ? 'Solved' : 'Active';
  String get displayLocation => location ?? 'Unknown Location';
  String get displayMessage =>
      notes.isEmpty ? 'Your vehicle has been reported.' : notes;
  String get displayReporter => reporter.displayName;
  String? get profileImage => reporter.profilePicture;

  static String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown Time';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final day = dateTime.day.toString();
      final month = _getMonthName(dateTime.month);
      final year = dateTime.year.toString();

      return '$hour:$minute | ${day}${_getDaySuffix(dateTime.day)} $month $year';
    } catch (e) {
      return 'Unknown Time';
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // Convert to the format your existing widgets expect
  // lib/models/report.dart - Fix the toWidgetFormat method

  // Convert to the format your existing widgets expect
  Map<String, dynamic> toWidgetFormat() {
    try {
      final widgetData = {
        'timeDate': formattedTimeDate,
        'status': displayStatus,
        'location': displayLocation,
        'message': displayMessage,
        'reporter': displayReporter,
        'profileImage': profileImage, // Reporter's profile picture
        'latitude': latitude,
        'longitude': longitude,
        // ADD THESE LINES - Include report images
        'images':
            images
                .map((img) => img.bestImage)
                .where((url) => url != null)
                .toList(),
        'hasImages': images.isNotEmpty,
        'imageCount': images.length,
        'firstImage': images.isNotEmpty ? images.first.bestImage : null,
      };
      print('🎨 Widget format for ${id}: $widgetData');
      return widgetData;
    } catch (e) {
      print('❌ Error formatting widget data for ${id}: $e');
      return {
        'timeDate': 'Unknown Time',
        'status': 'Unknown',
        'location': 'Unknown Location',
        'message': 'Error loading report',
        'reporter': 'Unknown',
        'profileImage': null,
        'latitude': null,
        'longitude': null,
        // ADD THESE FALLBACK VALUES TOO
        'images': [],
        'hasImages': false,
        'imageCount': 0,
        'firstImage': null,
      };
    }
  }

  @override
  String toString() {
    return 'Report(id: $id, reportNumber: $reportNumber, currentStatus: $currentStatus, isClosed: $isClosed, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Report && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ReportedVehicle class (renamed from Vehicle to avoid conflicts)
class ReportedVehicle {
  final String id;
  final String vehicleNumber;
  final String vehicleType;
  final String? brand;
  final Map<String, dynamic>? image;
  final Owner? owner;

  ReportedVehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    this.brand,
    this.image,
    this.owner,
  });

  factory ReportedVehicle.fromJson(Map<String, dynamic> json) {
    try {
      return ReportedVehicle(
        id: json['id']?.toString() ?? '',
        vehicleNumber: json['vehicle_number']?.toString() ?? '',
        vehicleType: json['vehicle_type']?.toString() ?? '',
        brand: json['brand']?.toString(),
        image: json['image'] as Map<String, dynamic>?,
        owner: json['owner'] != null ? Owner.fromJson(json['owner']) : null,
      );
    } catch (e) {
      print('❌ Error parsing ReportedVehicle: $e');
      print('📄 Vehicle JSON: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'ReportedVehicle(id: $id, vehicleNumber: $vehicleNumber, vehicleType: $vehicleType)';
  }
}

class Owner {
  final String id;
  final String? privacyPreference;
  final String? fullname;
  final String? email;
  final String? phoneNumber;
  final String? profilePicture;
  final String? companyName;

  Owner({
    required this.id,
    this.privacyPreference,
    this.fullname,
    this.email,
    this.phoneNumber,
    this.profilePicture,
    this.companyName,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    try {
      return Owner(
        id: json['id']?.toString() ?? '',
        privacyPreference: json['privacy_preference']?.toString(),
        fullname: json['fullname']?.toString(),
        email: json['email']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        profilePicture: json['profile_picture']?.toString(),
        companyName: json['company_name']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing Owner: $e');
      print('📄 Owner JSON: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'Owner(id: $id, fullname: $fullname, privacyPreference: $privacyPreference)';
  }
}

class Reporter {
  final String id;
  final String? privacyPreference;
  final String? fullname;
  final String? email;
  final String? phoneNumber;
  final String? profilePicture;
  final String? companyName;

  Reporter({
    required this.id,
    this.privacyPreference,
    this.fullname,
    this.email,
    this.phoneNumber,
    this.profilePicture,
    this.companyName,
  });

  factory Reporter.fromJson(Map<String, dynamic> json) {
    try {
      return Reporter(
        id: json['id']?.toString() ?? '',
        privacyPreference: json['privacy_preference']?.toString(),
        fullname: json['fullname']?.toString(),
        email: json['email']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        profilePicture: json['profile_picture']?.toString(),
        companyName: json['company_name']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing Reporter: $e');
      print('📄 Reporter JSON: $json');
      rethrow;
    }
  }

  String get displayName {
    if (fullname != null &&
        fullname!.isNotEmpty &&
        fullname != 'Anonymous User') {
      return fullname!;
    }
    return 'Anonymous User';
  }

  @override
  String toString() {
    return 'Reporter(id: $id, fullname: $fullname, privacyPreference: $privacyPreference)';
  }
}

class ReportImage {
  final String id;
  final Map<String, dynamic> image;

  ReportImage({required this.id, required this.image});

  factory ReportImage.fromJson(Map<String, dynamic> json) {
    try {
      return ReportImage(
        id: json['id']?.toString() ?? '',
        image: json['image'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      print('❌ Error parsing ReportImage: $e');
      print('📄 ReportImage JSON: $json');
      rethrow;
    }
  }

  // Helper getters for image URLs
  String? get thumbnail => image['thumbnail']?.toString();
  String? get medium => image['medium']?.toString();
  String? get large => image['large']?.toString();
  String? get original => image['original']?.toString();

  // Get the best available image
  String? get bestImage => large ?? medium ?? original ?? thumbnail;

  @override
  String toString() {
    return 'ReportImage(id: $id, hasImage: ${image.isNotEmpty})';
  }
}

class StatusLog {
  final String id;
  final String status;
  final DateTime timestamp;

  StatusLog({required this.id, required this.status, required this.timestamp});

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    try {
      return StatusLog(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing StatusLog: $e');
      print('📄 StatusLog JSON: $json');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'StatusLog(id: $id, status: $status, timestamp: $timestamp)';
  }
}
