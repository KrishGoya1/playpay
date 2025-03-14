# PlayPay

PlayPay is a mobile payment application built with Flutter and Firebase that allows users to securely make payments using QR codes.

## Prerequisites

Before getting started, make sure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Android SDK](https://developer.android.com/studio) (via Android Studio)
- [Git](https://git-scm.com/downloads) for cloning the repository
- A Google account for Firebase access

## Setup and Build Instructions

Follow these steps to set up and run the PlayPay application:

### 1. Clone the Repository


### 2. Firebase Setup

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Give your project a name (e.g., "PlayPay")
4. Follow the on-screen instructions to complete project creation

### 3. Add Android App to Firebase

1. In the Firebase console, click on the Android icon to add an Android app
2. Enter the package name: `com.example.playpay` (or your custom package name if changed)
3. Enter app nickname: "PlayPay"
4. (Optional) Enter SHA-1 if you need Google Sign-In
5. Click "Register app"

### 4. Download Configuration File

1. Download the `google-services.json` file provided by Firebase
2. Place this file in the `android/app` directory of your Flutter project

### 5. Configure Your App

The project should already be configured with the necessary Firebase dependencies, but verify:
- The Google Services plugin is applied in `android/app/build.gradle.kts`
- Firebase dependencies are in `pubspec.yaml`

### 6. Connect Android Device

1. Enable USB debugging on your Android device
2. Connect it to your development machine
3. Verify connection with `flutter devices`

### 7. Run the Application


### 8. Enable Authentication in Firebase

1. In the Firebase console, go to "Authentication"
2. Click "Get started"
3. Select "Email/Password" from the sign-in methods
4. Enable the "Email/Password" option and save

### 9. Create a User

1. In the Firebase Authentication section, click "Add user"
2. Enter an email and password for testing
3. Click "Add user"

### 10. Login and Use PlayPay

1. Open the app on your device
2. Login with the credentials you created
3. Start using the PlayPay features

## Features

- User authentication with email and password
- QR code generation for payments
- QR code scanning for processing payments
- Profile management
- Secure PIN setup for transactions

## Troubleshooting

- If you encounter build errors, make sure `google-services.json` is in the correct location
- For "Failed to load FirebaseOptions" errors, verify your Firebase configuration
- Make sure all dependencies are up-to-date with `flutter pub upgrade`