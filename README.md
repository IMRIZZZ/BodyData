<h1 align="center">
  <br>
  🏋️ BodyData Mobile App
  <br>
</h1>

<h4 align="center">A premium body-composition and weight-tracking application built with Flutter.</h4>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" alt="iOS" />
</p>

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-key-features">Key Features</a> •
  <a href="#%EF%B8%8F-technical-architecture">Architecture</a> •
  <a href="#-data--privacy-model">Privacy</a> •
  <a href="#-getting-started">Getting Started</a>
</p>

---

## 📱 Overview

**BodyData** is a comprehensive, mobile-first personal health utility designed to help users track their body composition and weight history. The application delivers a highly polished user experience, featuring seamless account access, a keyboard-aware body-data onboarding flow, dynamic BMI calculation, multi-profile management, and interactive weight-history visualizations.

Designed with modern UI principles, BodyData defaults to a sleek dark presentation, with an optional light theme for bright environments, and utilizes immersive-sticky system UI behavior on Android for a distraction-free experience.

## ✨ Key Features

### 🔐 Advanced Account Access & Security
*   **Multi-Provider Auth:** Supports Email/Password and Google Sign-In via Firebase Authentication.
*   **Smart Credential Linking:** Prevents duplicate accounts by seamlessly associating a Google credential with an existing email/password identity.
*   **IPTV-Style Signup Recovery:** Implements a robust 5-minute recovery window. If the app is killed or refreshed during email verification, the state is preserved via `SharedPreferences`, allowing the user to seamlessly resume the onboarding flow.

### 📊 Health Tracking & Visualization
*   **Dynamic BMI Calculation:** Automatically calculates BMI based on metric or imperial inputs (`kg / (m × m)`), converting pounds/inches accurately on the fly, and assigning standard health categories (Underweight, Normal, Overweight, Obese).
*   **Weight History Charts:** Provides a real-time, seven-day visual weight history using custom chart widgets to track health trends effortlessly.
*   **Multi-Profile Support:** Manage multiple users locally on a single device, each with their isolated body details, metrics, and weight history.

### 🎨 Premium UI/UX
*   **Keyboard-Aware Onboarding:** Step-by-step onboarding features a dynamically adjusting bottom action area that moves above the keyboard with safe-area insets.
*   **Adaptive Theming:** Persistent Dark and Light modes built on Material 3 component styling and color seeds.
*   **Immersive Experience:** Requests immersive-sticky system UI behavior on Android to hide navigation buttons during use.

---

## 🛠️ Technical Architecture

BodyData follows a clean, decoupled architecture utilizing `ChangeNotifier` for state management and local persistence for offline-first data handling.

### Presentation & State Management Layer
`AppProvider` acts as the central state coordinator, preventing business logic from bleeding into UI components. It manages:
*   Firebase auth state and local account fallbacks.
*   Profile selection and weight-record loading.
*   Google/email provider conflict resolution.
*   Theme (Dark/Light) and Unit (Metric/Imperial) preferences.

| Domain | Core Files | Responsibility |
| :--- | :--- | :--- |
| **Routing & Core** | `lib/main.dart` | Firebase startup, system UI, theme selection, cold-start recovery. |
| **Auth Flows** | `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart` | Provider links, login, signup, password resets. |
| **Session Recovery** | `signup_verification_screen.dart` | Polling, resend timers, expiry handling, final password creation. |
| **Data Intake** | `body_data_step1_screen.dart`, `body_data_step2_screen.dart` | Input validation, keyboard-aware formatting. |
| **Dashboard** | `dashboard_screen.dart`, `weight_chart_widget.dart` | BMI summary, state presentation, recent weight charts. |
| **Settings** | `settings_screen.dart` | Profiles, units, theme toggling. |

### Local Persistence (Offline-First)
The application leverages `StorageService` (wrapping `SharedPreferences`) to store sensitive body metrics locally rather than in the cloud.

| Data Type | Storage Key | Description |
| :--- | :--- | :--- |
| **Profiles** | `bd_profiles` | Name, DOB, gender, height, weight. |
| **Weight History** | `bd_weight_records` | Timestamped records used for charting. |
| **Active States** | `bd_active_account_id`, `bd_active_profile_id` | Restores last used account and profile. |
| **Preferences** | `bd_dark_mode` | Saves appearance choice. |
| **Signup Recovery** | `bd_recovering_signup` (and related) | Manages the 5-minute ephemeral recovery draft. |

---

## 🛡️ Data & Privacy Model

**BodyData prioritizes user privacy.** 
*   **Cloud Data:** Firebase Authentication strictly manages identity (Email addresses, verification state, auth providers). 
*   **Local Data:** All health data (Name, DOB, gender, height, weight, BMI, history charts) is kept **strictly local** on the device via `SharedPreferences`. Firestore is intentionally excluded to ensure personal health information never leaves the user's phone.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (Latest stable)
*   Dart SDK
*   Android Studio / Xcode (for iOS builds)
*   Firebase Project (with Authentication enabled)

### Firebase Configuration
1. Open your Firebase Console and enable **Email/Password** and **Google** under *Authentication > Sign-in method*.
2. Add an Android app with the package ID: `com.ivinnovations.bodydata`.
3. Add your development and release `SHA-1` and `SHA-256` fingerprints to the Firebase console.
4. Download the `google-services.json` file and place it in the `android/app/` directory.

*(Note: Email link authentication should remain disabled unless deliberately extending the app).*

### Installation & Build

Clone the repository and run the standard Flutter workflow:

```bash
# Get dependencies
flutter pub get

# Check for code issues
flutter analyze

# Run unit and widget tests
flutter test

# Build for production (Android)
flutter build apk --release
```

### Generating Assets
App icons have been prepared using a reproducible Python script. If you need to regenerate icons:
```bash
python tool/generate_icons.py
```
*Generated paths: `android/app/src/main/res/mipmap-*/ic_launcher.png` and `ios/Runner/Assets.xcassets/AppIcon.appiconset/`*

---

## ✅ Final User Test Checklist

Before deploying, ensure the following flows have been validated:
- [ ] Email/password account creation & email verification.
- [ ] 5-minute IPTV-style signup recovery (close and reopen app during verification).
- [ ] Google Sign-In provider linking (using the same email as an existing account).
- [ ] Keyboard-aware UI validation on Step 1 & 2 of onboarding.
- [ ] Accurate BMI and health category output.
- [ ] Multi-profile creation and switching.
- [ ] Weight record addition and real-time chart UI updates.
- [ ] Persistent Dark/Light theme switching across app restarts.
- [ ] Android immersive system UI behavior (auto-hiding navigation).

---
<p align="center">
  <i>Developed by a passionate Flutter developer. Open to new job opportunities!</i><br>
  <b>Application ID:</b> <code>com.ivinnovations.bodydata</code>
</p>
