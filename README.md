# Taxi App (Flutter MVP)

Single Flutter app with **User**, **Driver**, and **Admin** roles. State: **Provider** (`ChangeNotifier` + `Consumer` / `Selector`). Backend: **Firebase** (Auth, Firestore, FCM). **Riders enter pickup/drop manually** (lat/long); embedded **Google Maps** is optional via `FeatureFlags.googleMapsEnabled` (see below).

## Project layout

```
lib/
  core/           # services, constants, theme, utils
  models/
  providers/
  features/
    auth/
    user/
    driver/
    admin/
    map/
    ride/         # see README inside for pointers
  shared/widgets/
```

### Rider preview (no phone OTP yet)

- `lib/core/constants/feature_flags.dart` — `phoneOtpEnabled` is **`false`**: the login screen offers **Continue as rider (preview)** without SMS.
- Same file: **`googleMapsEnabled` is `false`** — rider home uses **manual coordinates**; driver/admin map tiles are hidden (coordinates still shown in lists/cards). Set to **`true`** when Maps SDK + keys are ready.
- Set **`phoneOtpEnabled` to `true`** when Phone Auth is ready in Firebase.
- Preview uses a local user id (`local_preview_rider`); **Firestore** ride requests / history will fail until you sign in with a real account.

### Firebase project (MyTownCabs)

| | |
|--|--|
| **Name** | mytowncabs |
| **Project ID** | `mytowncabs-3eadc` |
| **Project number** | `606763588417` |

`lib/firebase_options.dart` and `android/app/google-services.json` use this project ID and sender ID. You still must add **real API keys and App IDs** by downloading config from the console or running `flutterfire configure`.

**Package IDs:** Android `applicationId` is **`com.mytowncabs.app`**, iOS bundle ID is **`com.mytown.cabs`**. Register those exact values in Firebase for each platform.

## Setup

### 0. No Firebase account yet?

1. Sign in with a Google account at [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** → name it → continue (Google Analytics is optional).
3. **Register Android**
   - Project overview → **Add app** → Android.
   - **Android package name** must be exactly: `com.mytowncabs.app` (matches this app).
   - Download **`google-services.json`** and place it at **`android/app/google-services.json`** (replace the placeholder file).
4. **Register iOS** (if you build for iPhone)
   - Add app → iOS.
   - **Bundle ID** must match Xcode: `com.mytown.cabs`.
   - Download **`GoogleService-Info.plist`** → add to **`ios/Runner/`** in Xcode (and keep a copy in that folder).
5. In the console, enable:
   - **Build → Authentication → Sign-in method → Phone** (turn on).
   - **Build → Firestore Database** → create database (start in **test mode** for local dev if you want; tighten with `firestore.rules` later).
   - **Build → Cloud Messaging** (no extra toggle needed for basic FCM; use a real device for push tests).
6. **Phone auth**: Firebase may ask you to add a **billing account** for Phone provider on some projects (Blaze plan). The Spark (free) tier still includes generous free usage; check current [Firebase pricing](https://firebase.google.com/pricing).

Until steps 0–5 are done, the app **cannot** sign users in or load data—there is no backend without Firebase.

### 1. Firebase (Flutter + config files)

1. With the project created and apps registered (step 0), run [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This overwrites `lib/firebase_options.dart` with real values.

3. Replace `android/app/google-services.json` with the file from the Firebase console (the committed file is a **placeholder**).

4. Add `GoogleService-Info.plist` to `ios/Runner/` from the console.

5. Deploy indexes and rules (optional but recommended):

   ```bash
   firebase deploy --only firestore:indexes,firestore:rules
   ```

   Repo includes `firestore.indexes.json` and `firestore.rules`.

### 2. Google Maps & Directions (when you enable maps)

With **`googleMapsEnabled: false`**, you can skip Maps SDK setup for now. Riders type **place names** (e.g. Udupi, Mangaluru, Karnataka); the app **geocodes** them: with `GOOGLE_MAPS_API_KEY` it uses **Google Geocoding** (enable Geocoding API in GCP). Without a key it uses **OpenStreetMap Nominatim** (India-biased, fine for light use). Routing still uses **straight-line / Directions** as before when the Directions key is missing.

When you set **`googleMapsEnabled: true`**, maps need a **Google Cloud API key** with the right APIs enabled (same GCP project as Firebase is fine).

1. Open [Google Cloud Console](https://console.cloud.google.com/) → select project **mytowncabs-3eadc** (or your Firebase project).
2. **APIs & Services → Library** → enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API** (place names → coordinates when using a key)
   - **Directions API** (for route line / fare distance in the app)
3. **Billing** must be enabled on the GCP project (Maps has a free monthly credit; Firebase stays separate).

**Android**

- If `GOOGLE_MAPS_API_KEY` is **not** in `android/local.properties`, the build falls back to the `current_key` inside `android/app/google-services.json`.
- You can still override explicitly:

  ```properties
  GOOGLE_MAPS_API_KEY=your_key_here
  ```

**iOS**

- `GMSApiKey` in `ios/Runner/Info.plist` is set from your Firebase iOS client key (same as `API_KEY` in `GoogleService-Info.plist`). Change it there if you use a dedicated Maps key.

**Dart (Directions HTTP)**

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

Use a key that has **Directions API** enabled. If empty, routing uses haversine distance and a simple time estimate (no road geometry).

### 3. iOS pods

```bash
cd ios && pod install && cd ..
```

### 4. Admin users

- Either add phone numbers to `AppConstants.adminPhoneNumbers` (E.164, e.g. `+15551234567`) so the first profile is created with role **admin**, or manually set `role: admin` and `isApproved: true` on a user document in Firestore.

## Running

```bash
flutter pub get
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key
```

## Firestore data model

- **`users/{uid}`** — `phone`, `name`, `role` (`user` | `driver` | `admin`), `isApproved`, `isOnline`, `latitude`, `longitude`, `fcmToken`, …
- **`rides/{rideId}`** — `userId`, `driverId`, `pickup`, `drop`, `status`, `otp`, `estimatedPrice`, `finalPrice`, `vehicleType`, `distanceMeters`, `durationSeconds`, `polyline`, `createdAt`, `updatedAt`

## Push notifications

The app registers FCM and stores the token on the user document. **Sending** pushes (e.g. “new ride for drivers”) requires your own **Cloud Function** or backend using the FCM HTTP API and stored tokens. In-app updates already use Firestore listeners.

## Notes

- **Driver location** is written every ~4s while online (`AppConstants.driverLocationInterval`).
- **OTP** is generated when a driver **accepts** a ride; the rider shows it and the driver enters it to **start** the trip.
- **Cash** only: final fare is entered by the driver at drop-off.

## Tests

```bash
flutter test
flutter analyze
```
# taxiApp
