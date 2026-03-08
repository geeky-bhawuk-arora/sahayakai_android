# Sahayak AI (सहायक AI) 🇮🇳

**Sahayak AI** is a premium, national-scale GovTech platform designed to empower Indian citizens through a voice-first, privacy-compliant, and accessible interface. It acts as a digital companion to help users discover and apply for government schemes (like PM-KISAN, MGNREGS) using natural language.

---

## 🌟 Key Features

### 🎙️ Voice-First Interaction
Built for accessibility, allowing users to interact with the "Sahayak Assistant" via voice. Supports real-time feedback and processing animations.

### 🛡️ Privacy First (DPDP Act 2023)
Strict adherence to the Digital Personal Data Protection Act. Includes a "Digital Citizen Agreement" onboarding flow where users have granular control over their data processing and notifications.

### 🏛️ "Premium Government" UI/UX
- **Material 3 Design:** Clean, high-trust interface using a National Palette (Navy Blue & Saffron).
- **Bilingual Support:** Persistent toggle for Hindi (HI) and English (EN) to bridge the digital divide.
- **Accessibility:** High-contrast text and support for dynamic font scaling for elderly users.

### 🔍 Scheme Intelligence
- **Eligibility Discovery:** Automated checking against user profiles (Age, Income, Occupation).
- **Actionable Insights:** AI-generated summaries of schemes with clickable "Action Chips" for next steps.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Latest Stable)
- **State Management:** [Riverpod](https://riverpod.dev) (Global state for Auth, Profile, and Voice sessions)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (Declarative routing with protected paths)
- **Networking:** [Dio](https://pub.dev/packages/dio) with a centralized `BaseRepository` and Mocking Layer.
- **UI Components:** 
  - `flutter_markdown` for LLM responses.
  - `google_fonts` (Inter) for modern typography.
  - `lottie` for engaging voice-processing animations.

---

## 🏗️ Project Architecture

The project follows a modular and scalable directory structure:

```text
lib/
├── models/           # Data schemas (Scheme, UserProfile, TurnResponse)
├── services/         # API Service & Mock Interceptors
├── providers/        # Riverpod providers for global state
└── main.dart         # Routing, Theme definition, and UI Screens
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / VS Code
- An Android Emulator or physical device

### Installation & Execution
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/sahayakai_android.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

> **Note:** The app currently uses a `MockInterceptor` in `lib/services/api_service.dart`. This allows you to test the full flow (Consent -> Dashboard -> Voice Interaction) without requiring live AWS endpoints.

---

## 🗺️ Roadmap
- [ ] **AWS Cognito Integration:** Secure biometric and OTP login.
- [ ] **S3 Voice Pipeline:** Real-time upload of `.m4a` voice recordings.
- [ ] **Live API Sync:** Transition from mock data to live Government Scheme APIs.
- [ ] **Document Vault:** Secure storage for Aadhar and Land records using Digilocker integration.

---

## 📄 License
This project is proprietary and intended for the **Sahayak AI** platform.
