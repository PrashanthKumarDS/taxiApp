# Username/Profile Creation Guide

This guide explains how user profiles and usernames are created in your taxi app.

## 📱 Profile Creation Flow

```
1. User opens app
   ↓
2. LoginOptionsScreen → Tap "Sign in with Phone"
   ↓
3. PhoneLoginScreen → Enter phone number
   ↓
4. Receive SMS OTP code
   ↓
5. Enter OTP code in PhoneLoginScreen
   ↓
6. OTP verified ✓
   ↓
7. Auto-navigate to ProfileSetupScreen
   ↓
8. Enter Full Name + Select Role (Rider/Driver)
   ↓
9. Tap "Create Profile"
   ↓
10. Profile created in Firestore
    ↓
11. Redirected to home screen (User/Driver/Admin)
```

## 📍 Profile Setup Screen

**File:** [lib/features/auth/screens/profile_setup_screen.dart](lib/features/auth/screens/profile_setup_screen.dart)

This screen appears **after successful OTP verification** and allows users to:

### Input Fields

- **Full Name** (username) - Required, displayed as "name" in Firestore
- **Phone Number** - Auto-filled, read-only (from OTP verification)
- **Role Selection** - Choose between "Book Rides" (Rider) or "Drive" (Driver)

### Example User Input

```
Full Name: John Smith
Phone: +1-555-123-4567  (auto-filled)
Role: Book Rides (Rider)
```

## 💾 Firestore Document Structure

After profile creation, a Firestore document is created in the `users` collection:

```json
{
  "id": "firebase_auth_uid",
  "name": "John Smith",
  "phone": "+15551234567",
  "role": "user",
  "isApproved": true,
  "fcmToken": "device_notification_token",
  "createdAt": "2026-03-31T12:30:00Z"
}
```

### Field Descriptions

| Field        | Type      | Description                                                       |
| ------------ | --------- | ----------------------------------------------------------------- |
| `id`         | String    | Firebase Auth UID (auto)                                          |
| `name`       | String    | User's full name (username)                                       |
| `phone`      | String    | Phone number in E.164 format                                      |
| `role`       | String    | `user` (Rider), `driver`, or `admin`                              |
| `isApproved` | Boolean   | `true` for riders, `false` for new drivers (needs admin approval) |
| `fcmToken`   | String    | Firebase Cloud Messaging token                                    |
| `createdAt`  | Timestamp | Account creation time                                             |

## 🔐 Code Flow Details

### 1. **OTP Verification** (PhoneLoginScreen)

```dart
// User taps "Verify & continue"
await auth.verifyOtp(_otpCtrl.text);

// If successful:
// - Firebase Auth user is created
// - firebaseUser property is set
// - AppUser is NOT yet created (profile not in Firestore)
// - Navigates to ProfileSetupScreen
```

### 2. **Profile Setup** (ProfileSetupScreen)

```dart
// User enters name and selects role
auth.completeProfileAfterSignIn(displayName: "John Smith");
```

### 3. **Profile Creation** (AuthProvider + UserFirestoreService)

```dart
// completeProfileAfterSignIn() calls:
await _users.ensureUserProfile(
  firebaseUser: firebaseUser,  // Firebase Auth user
  desiredRole: _signupRole,     // User or Driver (selected in ProfileSetupScreen)
  displayName: "John Smith",    // User's full name
);

// This creates/updates Firestore document in "users" collection
```

### 4. **Auto-Redirect** (RoleRouter)

```dart
// When Firestore document is created:
// - AuthProvider's _profileSub stream listener is triggered
// - _appUser property is updated
// - notifyListeners() is called
// - RoleRouter checks the role and shows appropriate home screen
```

## 📊 User Roles

After profile creation, users can have one of three roles:

### 1. **Rider** (UserRole.user)

- Books rides
- Can immediately use the app (`isApproved: true`)
- Home screen: [lib/features/user/screens/user_home_screen.dart](lib/features/user/screens/user_home_screen.dart)

### 2. **Driver** (UserRole.driver)

- Provides rides
- Needs admin approval (`isApproved: false` initially)
- Must wait for approval before going online
- Home screen: [lib/features/driver/screens/driver_home_screen.dart](lib/features/driver/screens/driver_home_screen.dart)

### 3. **Admin** (UserRole.admin)

- Auto-assigned for hardcoded phone numbers in `AppConstants.adminPhoneNumbers`
- Manages the platform
- Home screen: [lib/features/admin/screens/admin_shell_screen.dart](lib/features/admin/screens/admin_shell_screen.dart)

**Check Admin Numbers:**

```dart
// File: lib/core/constants/app_constants.dart
static const List<String> adminPhoneNumbers = [
  '+1234567890',  // Replace with your admin phone numbers
];
```

## 🔑 Key Files

| File                                                                      | Purpose                               |
| ------------------------------------------------------------------------- | ------------------------------------- |
| [ProfileSetupScreen](lib/features/auth/screens/profile_setup_screen.dart) | Collects user name and role           |
| [PhoneLoginScreen](lib/features/auth/screens/phone_login_screen.dart)     | Phone OTP collection and verification |
| [AuthProvider](lib/providers/auth_provider.dart)                          | State management for authentication   |
| [UserFirestoreService](lib/core/services/user_firestore_service.dart)     | Firestore database operations         |
| [AppUser Model](lib/models/app_user.dart)                                 | User data model                       |

## 🔄 Full Authentication Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│         LoginOptionsScreen                           │
│  - Sign in with Phone ← (selected)                   │
│  - Continue as Rider (Preview)                       │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│         PhoneLoginScreen (Phone Input)               │
│  - Enter phone +15551234567                          │
│  - Tap "Send code"                                   │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼ (Firebase verifyPhoneNumber)
         ┌────────────────────┐
         │  SMS to user:      │
         │  Code: 123456      │
         └────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│      PhoneLoginScreen (OTP Verification)             │
│  - Enter SMS code: 123456                            │
│  - Tap "Verify & continue"                           │
└──────────────┬──────────────────────────────────────┘
               │
               ▼ (Firebase signInWithCredential)
         ┌────────────────────┐
         │  OTP Verified ✓    │
         │  firebaseUser   ✓  │
         └────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│      ProfileSetupScreen                              │
│  - Phone: +15551234567 (read-only)                   │
│  - Full Name: [John Smith] (required)                │
│  - Role: [Book Rides] or [Drive] (required)          │
│  - Tap "Create Profile"                              │
└──────────────┬──────────────────────────────────────┘
               │
               ▼ (completeProfileAfterSignIn)
    ┌──────────────────────────┐
    │ Create Firestore Doc:    │
    │ - name: "John Smith"     │
    │ - phone: "+15551234567"  │
    │ - role: "user"           │
    │ - isApproved: true       │
    └──────────┬───────────────┘
               │
               ▼ (Profile stream updated)
         ┌──────────────────┐
         │  appUser loaded  │
         └──────────┬───────┘
                    │
                    ▼
          ┌──────────────────────┐
          │  RoleRouter redirect │
          │  → UserHomeScreen    │
          └──────────────────────┘
```

## 📝 Example: Creating a Test User

### Step 1: Launch App

```
→ See LoginOptionsScreen
```

### Step 2: Tap Phone Sign-In

```
→ PhoneLoginScreen appears
```

### Step 3: Enter Test Phone

```
Enter: +1 555 123 4567
Tap: "Send code"
→ Firebase sends SMS (or uses verified number for testing)
```

### Step 4: Enter OTP

```
(You'd normally receive SMS code)
For testing, use your configured test number in Firebase Console
Tap: "Verify & continue"
```

### Step 5: Complete Profile

```
Full Name: John Doe
Role: Book Rides
Tap: "Create Profile"
→ Profile created in Firestore
→ Redirected to Rider Home Screen
```

### Step 6: View in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select `mytowncabs-3eadc` project
3. Firestore Database → `users` collection
4. See your new document with `name: "John Doe"`

## 🚀 Customizing Profile Data

To add more fields to the profile:

### 1. Update Firestore Service

**File:** `lib/core/services/user_firestore_service.dart`

```dart
Future<AppUser> ensureUserProfile({
  required User firebaseUser,
  required UserRole desiredRole,
  String? displayName,
  String? profilePhotoUrl,  // Add new field
  String? email,             // Add new field
}) async {
  // ... existing code ...
  await ref.set({
    'phone': phone,
    'name': displayName,
    'profilePhotoUrl': profilePhotoUrl,  // Add here
    'email': email,                       // Add here
    'role': role.firestoreValue,
    'isApproved': isApproved,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

### 2. Update AppUser Model

**File:** `lib/models/app_user.dart`

```dart
class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    required this.isApproved,
    this.profilePhotoUrl,  // Add new field
    this.email,             // Add new field
  });

  final String id;
  final String phone;
  final String? name;
  final String? profilePhotoUrl;  // Add here
  final String? email;             // Add here
  final UserRole role;
  final bool isApproved;

  // ... rest of class
}
```

### 3. Update ProfileSetupScreen

**File:** `lib/features/auth/screens/profile_setup_screen.dart`

Add more input fields and pass them to `completeProfileAfterSignIn()`.

## ❓ Troubleshooting

### User stuck at ProfileSetupScreen

- Check Firestore rules allow writing to `users` collection
- Check user has internet connection
- Check `displayName` is not empty

### Profile not appearing in Firestore

- Open [Firebase Console](https://console.firebase.google.com)
- Check Authentication → Users (see if Firebase user exists)
- Check Firestore Database rules allow writing
- Check browser console for errors

### User auto-redirecting to login

- Firestore document wasn't created
- Check UserFirestoreService.ensureUserProfile() is being called
- Check Firestore security rules

## 📚 References

- [AppUser Model](lib/models/app_user.dart)
- [AuthProvider](lib/providers/auth_provider.dart)
- [UserFirestoreService](lib/core/services/user_firestore_service.dart)
- [ProfileSetupScreen](lib/features/auth/screens/profile_setup_screen.dart)
- [Firebase Documentation](https://firebase.flutter.dev/docs/auth/overview)

---

**Last Updated:** March 31, 2026
