enum LoginMethod { email, google, unknown, phone, apple }

extension LoginMethodExtension on LoginMethod {
  String get displayName {
    switch (this) {
      case LoginMethod.email:
        return 'Email';
      case LoginMethod.google:
        return 'Google';
      case LoginMethod.unknown:
        return 'Unknown';
      case LoginMethod.phone:
        return 'Phone';
      case LoginMethod.apple:
        return 'Apple';
    }
  }

  String get providerID {
    switch (this) {
      case LoginMethod.email:
        return 'password';
      case LoginMethod.google:
        return 'google.com';
      case LoginMethod.unknown:
        return '';
      case LoginMethod.phone:
        return 'phone';
      case LoginMethod.apple:
        return 'apple.com';
    }
  }
}
