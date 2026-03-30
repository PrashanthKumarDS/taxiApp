# Authentication Implementation Guide

This guide provides an overview of the integrated authentication system with Google Sign-In, Email/Password login, and Phone OTP.

## 📋 Overview

The taxi app now supports **three authentication methods**:

1. **Email & Password** - Traditional registration and login
2. **Google Sign-In** - OAuth with Google
3. **Phone OTP** - Phone number verification with OTP
4. **Preview Mode** - Demo mode without authentication

## 🗂️ File Structure

```
lib/
├── core/
│   └── services/
│       └── auth_service.dart          # Firebase authentication service
├── providers/
│   └── auth_provider.dart             # Auth state management
├── features/
│   └── auth/
│       └── screens/
│           ├── login_options_screen.dart    # Main login options
│           ├── email_password_screen.dart   # Email/Password
│           └── phone_login_screen.dart      # Phone OTP
└── shared/
    └── widgets/
        └── role_router.dart           # Route based on auth state
```

## 🔐 Authentication Service (AuthService)

Located in [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)

### Email/Password Methods

```dart
// Sign up with email and password
Future<UserCredential> signUpWithEmailPassword({
  required String email,
  required String password,
})

// Sign in with email and password
Future<UserCredential> signInWithEmailPassword({
  required String email,
  required String password,
})
```

### Google Sign-In Method

```dart
// Sign in with Google account
Future<UserCredential> signInWithGoogle()
```

### Phone OTP Methods (Existing)

```dart
Future<void> verifyPhoneNumber({...})
Future<UserCredential> signInWithCredential(PhoneAuthCredential credential)
```

### Sign Out

```dart
// Logs out from both Firebase and Google
Future<void> signOut()
```

## 🎯 Auth Provider (AuthProvider)

Located in [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart)

### Properties

- `appUser` - Current authenticated user in Firestore
- `firebaseUser` - Firebase Auth user
- `isAuthenticated` - Is user signed in and loaded
- `hasSession` - Can access role-based screens
- `errorMessage` - Last error message
- `isBusy` - Loading state
- `signupRole` - Role selected during signup (Rider/Driver)

### Email/Password Sign Up

```dart
Future<void> signUpWithEmailPassword({
  required String email,
  required String password,
  required String confirmPassword,
})
```

**Validates:**

- Email is not empty
- Password is at least 6 characters
- Passwords match
- Email isn't already registered

### Email/Password Sign In

```dart
Future<void> signInWithEmailPassword({
  required String email,
  required String password,
})
```

**Validates:**

- Email and password are provided
- Credentials are correct

### Google Sign In

```dart
Future<void> signInWithGoogle()
```

**Features:**

- Opens Google sign-in dialog
- Automatically creates/loads Firestore profile
- Handles cancellation gracefully

### Error Handling

The `_getErrorMessage()` method converts Firebase error codes to user-friendly messages:

```
weak-password → "The password provided is too weak."
email-already-in-use → "The account already exists for that email."
invalid-email → "The email address is invalid."
user-not-found → "No user found with this email."
wrong-password → "The password is incorrect."
too-many-requests → "Too many attempts. Please try again later."
```

## 🎨 UI Screens

### 1. Login Options Screen

**Path:** [lib/features/auth/screens/login_options_screen.dart](lib/features/auth/screens/login_options_screen.dart)

Main entry point with options to:

- Sign in with Email
- Sign in with Google
- Sign in with Phone
- Continue as Rider (Preview)

### 2. Email/Password Screen

**Path:** [lib/features/auth/screens/email_password_screen.dart](lib/features/auth/screens/email_password_screen.dart)

Features:

- **Sign In Tab** - Email and password fields
- **Sign Up Tab** - Email, password, confirm password, and role selection
- **Password visibility toggle** - Show/hide passwords
- **Error messages** - Clear error display
- **Loading state** - Loading indicator during auth

### 3. Phone Login Screen

**Path:** [lib/features/auth/screens/phone_login_screen.dart](lib/features/auth/screens/phone_login_screen.dart)

Existing phone OTP implementation with:

- Phone number input (E.164 format)
- OTP verification
- Role selection
- Import note: Set `FeatureFlags.phoneOtpEnabled = true` to enable

## 🔄 Flow Diagrams

### Email/Password Signup Flow

```
User → LoginOptionsScreen
  → Tap "Sign in with Email"
  → EmailPasswordScreen (Sign Up tab)
  → Enter email, password, confirm password
  → Select role (Rider/Driver)
  → Tap "Create account"
  → signUpWithEmailPassword() called
  → Firestore profile created
  → App user loaded
  → Redirected to home screen
```

### Email/Password Signin Flow

```
User → LoginOptionsScreen
  → Tap "Sign in with Email"
  → EmailPasswordScreen (Sign In tab)
  → Enter email and password
  → Tap "Sign in"
  → signInWithEmailPassword() called
  → Firestore profile loaded
  → Redirected to home screen
```

### Google Sign-In Flow

```
User → LoginOptionsScreen
  → Tap "Sign in with Google"
  → Google sign-in dialog opens
  → User selects Google account
  → signInWithGoogle() called
  → Firestore profile created/loaded
  → Redirected to home screen
```

## 🛠️ Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

The following dependencies are already added:

- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `google_sign_in` - Google Sign-In
- `cloud_firestore` - Database
- `provider` - State management

### 2. Configure Firebase

Your Firebase project is already configured:

- Project: `mytowncabs-3eadc`
- Android and iOS apps registered
- `GoogleService-Info.plist` and `google-services.json` present

### 3. Configure Google Sign-In

See [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md) for detailed setup:

**Android:**

- Add SHA-1 fingerprint to Firebase Console
- Ensure package name matches: `com.mytowncabs.app`

**iOS:**

- Verify Bundle ID: `com.mytown.cabs`
- Add custom URL scheme to `Info.plist`
- Run `cd ios && pod install`

### 4. Enable Phone OTP (Optional)

In [lib/core/constants/feature_flags.dart](lib/core/constants/feature_flags.dart):

```dart
static const bool phoneOtpEnabled = true; // Change from false to true
```

## 🧪 Testing

### Test Email/Password

1. Launch the app
2. Tap "Sign in with Email"
3. Tap "Sign up"
4. Enter email (e.g., `test@example.com`)
5. Enter password (min 6 chars)
6. Confirm password
7. Select role
8. Tap "Create account"
9. Verify in Firebase Console → Authentication

### Test Google Sign-In

1. Launch the app
2. Tap "Sign in with Google"
3. Select a Google account
4. Verify sign-in completes

### Debug Issues

**Check Logs:**

```bash
flutter logs
```

**Firebase Authentication Debugging:**

- Open [Firebase Console](https://console.firebase.google.com/)
- Select your project
- Go to **Authentication** → **Users**
- See all created accounts

**Google Sign-In Debugging:**

```dart
// Add to AuthService.signInWithGoogle()
print('Google Sign-In Details:');
print('Access Token: ${googleAuth.accessToken}');
print('ID Token: ${googleAuth.idToken}');
```

## 🔑 User Profile Creation

After successful authentication, the app creates a Firestore document:

```json
{
  "id": "firebase_uid",
  "email": "user@example.com",
  "phone": "+1234567890",
  "name": "User Name",
  "role": "user|driver|admin",
  "isApproved": false,
  "createdAt": "2026-03-30T12:00:00Z"
}
```

See [UserFirestoreService](lib/core/services/user_firestore_service.dart) for details.

## ⚠️ Important Notes

### Password Requirements

- Minimum 6 characters
- Should include uppercase, lowercase, numbers, special chars (recommended)
- Stored securely by Firebase

### Google Sign-In

- Requires internet connection
- Requires Google Play Services (Android)
- Sandbox app IDs in Firebase Console work for testing

### Phone OTP

- Requires `FeatureFlags.phoneOtpEnabled = true`
- E.164 format required: `+15551234567`
- Test numbers can be configured in Firebase

### Session Management

- User remains logged in across app restarts
- Sign out clears all authentication data
- Firebase Auth tokens auto-refresh

## 📚 Additional Resources

- [Firebase Authentication Docs](https://firebase.flutter.dev/docs/auth/overview)
- [Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)

## 🚀 Next Steps

Consider implementing:

1. **Email verification** - Verify email before account activation
2. **Password reset** - Forgot password functionality
3. **Profile completion** - Name, photo, vehicle info
4. **Multi-factor authentication** - SMS/authenticator app
5. **Social linking** - Link multiple auth methods to same account
6. **Analytics** - Track signup/login conversions

---

**Last Updated:** March 30, 2026
**Android Package:** com.mytowncabs.app
**iOS Bundle ID:** com.mytown.cabs
**Firebase Project:** mytowncabs-3eadc
