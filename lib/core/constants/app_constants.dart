/// Pass at build time: `--dart-define=GOOGLE_MAPS_API_KEY=your_key`
/// Enable Directions API for the same key (or a server key) in Google Cloud.
class AppConstants {
  AppConstants._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Demo: add E.164 numbers (e.g. +15551234567) to treat as admin on first signup.
  static const List<String> adminPhoneNumbers = [];

  static const Duration driverLocationInterval = Duration(seconds: 4);
  static const int otpLength = 4;
}
