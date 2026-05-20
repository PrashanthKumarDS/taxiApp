/// Toggle features while backend auth is still being set up.
class FeatureFlags {
  FeatureFlags._();

  /// Phone OTP is optional until Firebase Phone Auth is fully configured.
  static const bool phoneOtpEnabled = true;

  /// When false, pickup/drop use manual coordinates; map widgets are not shown.
  static const bool googleMapsEnabled = true;
}
