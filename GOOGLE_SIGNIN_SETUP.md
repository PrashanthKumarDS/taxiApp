# Google Sign-In Setup Guide for Flutter Taxi App

This guide covers the setup of Google Sign-In for both iOS and Android platforms.

## Prerequisites

- Firebase project already created in [Firebase Console](https://console.firebase.google.com/)
- Flutter and Firebase CLI installed
- Your project's iOS and Android app registered with Firebase

## Step 1: Enable Google Sign-In in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **mytowncabs-3eadc**
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Google**
5. Enable the Google provider
6. Set support email (required)
7. Click **Save**

## Step 2: Android Configuration

### Get Your SHA-1 Fingerprint

Run this command to get your debug SHA-1:

```bash
cd android
./gradlew signingReport
```

Look for the `Variant: debugAndroidTest` and copy the **SHA-1** value.

Or use keytool:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Add Credentials to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Project Settings → **Your apps** → Android app
3. Scroll to **SHA certificate fingerprints**
4. Click **Add fingerprint** and paste your SHA-1
5. Click **Save**

### Update android/build.gradle.kts (if needed)

The `google-services.json` is already configured. Ensure your `android/app/build.gradle.kts` has:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## Step 3: iOS Configuration

### Update iOS Bundle ID

The iOS Bundle ID is already set to `com.mytown.cabs`. Ensure it matches your Firebase setup:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Project Settings → **Your apps** → iOS app
3. Verify **Bundle ID** is `com.mytown.cabs`

### Configure GoogleService-Info.plist

Your `GoogleService-Info.plist` is already in the project root. Ensure it's added to Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode (not Runner.xcodeproj)
2. Select **Runner** project in sidebar
3. Select **Runner** target
4. Go to **Build Phases** → **Copy Bundle Resources**
5. If `GoogleService-Info.plist` is missing, drag it from the file system

### Update ios/Runner/Info.plist

Add the following to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.606763588417-YOUR_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Get your iOS Client ID:**

1. Open `GoogleService-Info.plist` in a text editor
2. Look for `GOOGLE_APP_ID` and `CLIENT_ID`
3. The CLIENT_ID looks like: `606763588417-xxxxx.apps.googleusercontent.com`

Or find it in Firebase Console:

1. Project Settings → Service Accounts
2. Download your private key
3. Look for `client_id` in the JSON

### Update ios/Podfile (if needed)

Ensure your Podfile targets iOS 11 or higher:

```ruby
platform :ios, '12.0'
```

## Step 4: Complete the Setup

### Install/Update Dependencies

```bash
flutter pub get
flutter pub upgrade google_sign_in
```

### Run Flutter App

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

## Usage

The Google Sign-In is integrated into the app flow:

1. User navigates to **LoginOptionsScreen** (`lib/features/auth/screens/login_options_screen.dart`)
2. Taps "Sign in with Google"
3. **AuthProvider.signInWithGoogle()** is called
4. User completes authentication
5. User profile is created/loaded in Firestore

See [AuthProvider](../../../providers/auth_provider.dart) for implementation details.

## Troubleshooting

### Android Issues

**Error: "12500 - the app signature is not recognized"**

- Your SHA-1 fingerprint doesn't match Firebase
- Add your correct SHA-1 in Firebase Console

**Error: "DEVELOPER_ERROR" or "SERVICE_VERSION_UPDATE_REQUIRED"**

- Check that you're using the correct SHA-1
- Ensure the package name matches Firebase (`com.mytowncabs.app`)
- Clear app cache: `adb shell pm clear com.mytowncabs.app`

### iOS Issues

**Error: "Cannot find GIDSignIn in Bridging Header"**

- Run `cd ios && pod install`
- Clean build folder: `flutter clean`

**Error: "URL scheme not registered"**

- Ensure your custom scheme is in Info.plist (see Step 3)
- Run `flutter clean && flutter run`

**Error: "NSURLIsFileReferenceError"**

- Ensure GoogleService-Info.plist is properly linked in Xcode
- Run `cd ios && pod install --repo-update`

## Testing Google Sign-In

You can test with:

- Real Google accounts
- Test accounts configured in Firebase (App Sign-in → Test app)
- Use a physical device or simulator with Google Play Services installed (Android)

## Generate OAuth Consent Screen (Production)

Before releasing to production:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Find your project: **mytowncabs-3eadc**
3. Go to **APIs & Services** → **OAuth consent screen**
4. Choose **External** user type
5. Fill in required fields:
   - App name: "MyTown Cabs"
   - User support email: your@email.com
   - Developer contact info: your@email.com
6. Add required scopes: `email`, `profile`, `openid`
7. Publish to production

## Security Notes

- Never commit sensitive keys to version control
- Use environment-specific configurations
- Implement token refresh mechanisms
- Validate tokens server-side
- Use HTTPS for all backend communication

## References

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication](https://firebase.flutter.dev/docs/auth/overview)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/)

---

**Last Updated:** March 30, 2026
