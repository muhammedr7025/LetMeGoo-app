enum LoginMethod { email, google, unknown }

extension LoginMethodExtension on LoginMethod {
  String get displayName {
    switch (this) {
      case LoginMethod.email:
        return 'Email';
      case LoginMethod.google:
        return 'Google';
      case LoginMethod.unknown:
        return 'Unknown';
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
    }
  }
}
