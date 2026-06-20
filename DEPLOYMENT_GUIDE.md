# Firebase & App Store Deployment Guide - AroundU

This guide provides exhaustive, step-by-step instructions to configure your production Firebase project backend, secure the database, set up platform-specific permissions, configure release app signing, build release packages, and publish the AroundU application to Google Play and Apple App Store.

---

## 1. Firebase Project Setup

### A. Creating the Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it **AroundU** (or select your existing development/production project).
3. Choose whether to enable Google Analytics (recommended for tracking user retention and active radar usage) and click **Create Project**.

### B. Configuring Authentication
1. Navigate to **Build** ➔ **Authentication** in the left sidebar.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, select **Email/Password**.
4. Enable the **Email/Password** provider (leave *Email link (passwordless sign-in)* disabled for now).
5. Click **Save**.

### C. Creating the Firestore Database
1. Navigate to **Build** ➔ **Firestore Database**.
2. Click **Create Database**.
3. Select **Start in production mode** (this enforces security rules from day one).
4. Choose a database location closest to your target audience (e.g., `us-central1` or `asia-east1`) and click **Create**.

---

## 2. Production Firestore Security Rules

To protect user profiles, geolocations, waves, and chats, replace your database rules in the **Rules** tab of Firestore with the following configuration. 

> [!IMPORTANT]
> The previous development rules allowed wildcard access to all collections for any authenticated user. The following production-ready rules ensure that users can only modify their own profiles, send waves/likes as themselves, read matching chats, and that report details remain secure.

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: Checks if the request is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper: Checks if the user is accessing their own document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Helper: Verifies that a mutual match document exists for a chat room
    function isMatchParticipant(matchId) {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/matches/$(matchId)) &&
        (request.auth.uid in get(/databases/$(database)/documents/matches/$(matchId)).data.userIds);
    }

    // --- Users Profiles ---
    // Read: Any authenticated user can read other profiles to discover nearby vibe tags.
    // Write: Users can only write/update their own profile data (uid matches document id).
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    // --- Blocks ---
    // Read: Users can only fetch block entries they are involved in.
    // Write: A user can block/unblock another user only under their own UID.
    match /blocks/{blockId} {
      allow read: if isAuthenticated() && 
        (resource.data.blockerId == request.auth.uid || resource.data.blockedId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.blockerId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.blockerId == request.auth.uid;
    }

    // --- Reports ---
    // Write: Users can submit a report. The reporterId in the document must match their UID.
    // Read: Denied for standard clients (Restricted to security admins in the Firebase console).
    match /reports/{reportId} {
      allow create: if isAuthenticated() && request.resource.data.reporterId == request.auth.uid;
      allow read, update, delete: if false;
    }

    // --- Likes ---
    // Read: Users can query likes they sent or received.
    // Write: Users can only create/update likes where they are the sender.
    match /likes/{likeId} {
      allow read: if isAuthenticated() && 
        (resource.data.senderId == request.auth.uid || resource.data.receiverId == request.auth.uid);
      allow write: if isAuthenticated() && request.resource.data.senderId == request.auth.uid;
    }

    // --- Matches ---
    // Read: Users can read matches that contain their user ID in the `userIds` array.
    // Write: Created when a mutual like is established. Can only be written if the client auth UID is in the `userIds` list.
    match /matches/{matchId} {
      allow read: if isAuthenticated() && (request.auth.uid in resource.data.userIds);
      allow write: if isAuthenticated() && (request.auth.uid in request.resource.data.userIds);
    }

    // --- Waves (Short Signal Interactions) ---
    // Read: Users can query waves they sent or waves sent to them.
    // Write: Users can only create wave documents specifying themselves as the sender.
    match /waves/{waveId} {
      allow read: if isAuthenticated() && 
        (resource.data.receiverId == request.auth.uid || resource.data.senderId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.senderId == request.auth.uid;
    }

    // --- Connection Requests ---
    // Read: Users can query connection requests they sent or received.
    // Write: Users can only create connection requests where they are the sender.
    match /connection_requests/{requestId} {
      allow read: if isAuthenticated() && 
        (resource.data.senderId == request.auth.uid || resource.data.receiverId == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.senderId == request.auth.uid;
    }

    // --- Chats & Messages subcollection ---
    // Read/Write: Denied unless there is a verified, active mutual Match document corresponding to the chatId/matchId.
    match /chats/{matchId} {
      allow read, write: if isMatchParticipant(matchId);

      match /messages/{messageId} {
        allow read, write: if isMatchParticipant(matchId);
      }
    }
  }
}
```

---

## 3. Database Indexing & Query Architecture

AroundU queries Firestore data using geo-filtering and client-side sorting. 

### A. Geohash Radius Queries
The radar feature uses the `geoflutterfire_plus` library (configured in [discovery_repository.dart](file:///c:/Users/admin/StudioProjects/AroundU/lib/features/discovery/data/repositories/discovery_repository.dart)) which calculates a geographic bounding box and queries users where `location.geohash` falls within a specific range.
* **Indexes Required**: Because this is a single-field range query, Firestore's **automatic single-field indexing** is sufficient.
* **Additional Filters**: If you decide to move filters like `isGhostMode` or block status from the client side to the Firestore query level (e.g., `.where('isGhostMode', isEqualTo: false)`), you **MUST** create a composite index in the Firebase console:
  * **Collection**: `users`
  * **Fields**: `isGhostMode` (Ascending), `location.geohash` (Ascending)

### B. Message Ordering Index
The messages in a chat are queried descending by timestamp:
```dart
_firestore.collection('chats').doc(matchId).collection('messages').orderBy('timestamp', descending: true)
```
* **Indexes Required**: Works out-of-the-box with Firestore's default subcollection index. No additional composite indexes are needed unless filters are added to the stream.

---

## 4. Local Flutter & Firebase Setup

Ensure you configure the native platforms in the project root folder.

### A. Prerequisites
* Install the **Firebase CLI**:
  ```bash
  npm install -g firebase-tools
  ```
* Log in with your Google account:
  ```bash
  firebase login
  ```
* Install the **FlutterFire CLI**:
  ```bash
  dart pub global activate flutterfire_cli
  ```
  Make sure your system variables contain the Pub cache bin directory (e.g., `C:\Users\<username>\AppData\Local\Pub\Cache\bin` on Windows).

### B. Generating Platform Config Files
From the project root:
```bash
flutterfire configure
```
1. Select the target Firebase project.
2. Select the platform targets: `android` and `ios` (and `web` if compiling web).
3. The CLI will download/update:
   * `android/app/google-services.json`
   * `ios/Runner/GoogleService-Info.plist`
   * [firebase_options.dart](file:///c:/Users/admin/StudioProjects/AroundU/lib/firebase_options.dart)

---

## 5. Android Build Configuration

To deploy the Android application (`com.aroundu.aroundu`), follow these configuration instructions.

### A. Location & Foreground Permissions
The Android Manifest ([AndroidManifest.xml](file:///c:/Users/admin/StudioProjects/AroundU/android/app/src/main/AndroidManifest.xml)) is configured to request foreground and background location permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

> [!WARNING]
> **Google Play Background Location Policy**: Google Play has strict guidelines regarding background location (`ACCESS_BACKGROUND_LOCATION`).
> 1. You must submit a declaration form explaining why background location access is core to the application.
> 2. You must provide a clear in-app disclosure showing how the location is used (even when closed) and receive user consent.
> 3. If rejected during the review, remove the `ACCESS_BACKGROUND_LOCATION` permission from the manifest and fall back to foreground location.

### B. Signing Credentials (Keystore Setup)
For release builds, you must generate a secure keystore file.
1. Run this command in a terminal to generate a secure keystore (`upload-keystore.jks`):
   ```bash
   keytool -genkey -v -keystore c:\Users\admin\StudioProjects\AroundU\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create a file named `key.properties` (which **MUST** be added to your `.gitignore` file to prevent committing passwords) in `android/key.properties`:
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Update [build.gradle.kts](file:///c:/Users/admin/StudioProjects/AroundU/android/app/build.gradle.kts) to parse this properties file and use it for release builds. Replace the `buildTypes` block with the following config:

```kotlin
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = java.util.Properties()
                keystoreProperties.load(keystorePropertiesFile.inputStream())
                
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
```

### C. Extracting SHA-1 & SHA-256 for Firebase Auth
Firebase Authentication uses app signatures to verify requests.
1. Navigate to the `android` directory in your terminal and execute:
   ```bash
   ./gradlew signingReport
   ```
2. Copy the `SHA-1` and `SHA-256` keys printed for the `Variant: release` / `Config: release`.
3. Paste these fingerprints in the **Firebase Console ➔ Project Settings ➔ Your Apps ➔ Android app** section. Without these, email login and app security integrations will fail.

---

## 6. iOS Build Configuration

To deploy the iOS application, complete the following configurations using Xcode on a macOS machine.

### A. Location Permissions & Disclosures
The app's [Info.plist](file:///c:/Users/admin/StudioProjects/AroundU/ios/Runner/Info.plist) is set up for foreground/background tracking:
* `NSLocationWhenInUseUsageDescription`: Displays when the app is in the foreground.
* `NSLocationAlwaysAndWhenInUseUsageDescription` & `NSLocationAlwaysUsageDescription`: Triggers when background location is active.
* `UIBackgroundModes` ➔ `location`: Essential for updating coordinates in the background.

> [!WARNING]
> **Apple App Store Review Guidelines (Section 2.5.4 - Multitasking & Background Services)**:
> Apple requires background location usage to be directly beneficial to the user experience. You must include a description explaining that location is queried to discover other active users within 100 meters, and warning that continued background GPS usage can decrease battery life.

### B. Provisioning and Bundle Identifier
1. Open the `/ios` directory in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select the top-level **Runner** project.
3. Under the **Signing & Capabilities** tab, check **Automatically manage signing**.
4. Select your **Apple Developer Program Team**.
5. Update the **Bundle Identifier** matching your App Store Connect app ID (e.g., `com.aroundu.aroundu`).
6. Ensure the **Background Modes** capability is enabled with the **Location updates** checkbox checked.

---

## 7. Compiling and Building the Releases

Once configuration files and keys are complete, run the following compilation routines.

### A. Cleaning Project Cache
Always clean build artifacts before compiling release versions:
```bash
flutter clean
flutter pub get
```

### B. Android Release Build
Compile an Android App Bundle (AAB), which is optimized for Google Play store submissions:
```bash
flutter build appbundle --release
```
* **Output Path**: `build/app/outputs/bundle/release/app-release.aab`
* *Alternatively*, if you need a direct installable APK for side-loading:
  ```bash
  flutter build apk --release
  ```

### C. iOS Release Build
Compile a release IPA container:
```bash
flutter build ipa --release
```
* **Output Path**: `build/ios/archive/Runner.xcarchive` / `build/ios/ipa/aroundu.ipa`
* Use Xcode's Organizer (`Window` ➔ `Organizer` in Xcode) to select the archive and upload it to App Store Connect/TestFlight.

---

## 8. Web App Deployment to Firebase Hosting (Optional)

If you plan to compile a Web preview version of AroundU:

### A. Initialize Hosting
Run the initialization wizard from your project root:
```bash
firebase init hosting
```
1. Select **Use an existing project** and select your AroundU project.
2. Enter the public directory folder: **`build/web`**
3. Configure as a single-page app (rewrite all URLs to `/index.html`): **`Yes`**
4. Set up automatic builds/deploys with GitHub: **`No`** (unless CI/CD is required).

### B. Compile and Deploy Web Build
Compile the release bundle and upload to Firebase:
```bash
flutter build web --release
firebase deploy --only hosting
```
* Your app will be live at: `https://<your-project-id>.web.app`

---

## 9. Post-Deployment Checklist & Production Upgrades

### A. Profile Image Handling Optimization
Currently, the onboarding flow ([onboarding_providers.dart](file:///c:/Users/admin/StudioProjects/AroundU/lib/features/onboarding/presentation/controllers/onboarding_providers.dart)) saves image file paths locally:
```dart
final nonNullPics = state.profilePictures.whereType<String>().toList();
// Writes local paths directly to Firestore
```
For production deployment, you should upload selected images to **Firebase Storage** first and write the returned network URLs to the Firestore user profile.
1. Enable **Firebase Storage** in the Firebase console.
2. Add the `firebase_storage` upload function to your repository before store deployment.
3. Update the storage security rules to restrict writes:
   ```javascript
   service firebase.storage {
     match /b/{bucket}/o {
       match /users/{userId}/{allPaths=**} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### B. Monitoring and Crash Reports
Add Firebase Crashlytics to report runtime crashes on users' devices:
1. Run: `flutter pub add firebase_crashlytics`
2. Configure initialization in `main.dart`:
   ```dart
   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
   ```
