# AI Resume Builder

A Flutter app that helps job seekers build a professional, ATS-friendly resume
in minutes. You describe your experience, Google Gemini writes and polishes the
content, and you export a print-ready PDF in one of four templates.

Built as an internship project for [Internee.pk](https://internee.pk) with
Flutter, Firebase and the Google Gemini API.

## Features

- **Sign in** with email and password or Google, with password reset.
- **Guided resume form** for your target role, summary, experience, education
  and skills. Changes save automatically, including offline.
- **AI writing** with Gemini: generate a professional summary, rewrite
  experience into achievement-focused bullet points, and get skill suggestions
  for your target role. Everything stays editable, and any section can be
  regenerated.
- **LinkedIn import**: paste the text of your LinkedIn profile and the AI fills
  in your resume. You review each section before anything is added.
- **Four templates** (Classic, Modern, Minimal, Compact) with six accent
  colors and four fonts.
- **PDF export and sharing**: the preview shows the actual PDF, so what you see
  is exactly what you export. Share it to email, WhatsApp or anywhere else, or
  print it. PDFs contain real text, so applicant tracking systems can read
  them.
- **Multiple resumes**: keep a version for each job, and duplicate or delete
  them.
- **Offline-friendly**: edits save on the device and sync when you reconnect.
  A banner tells you when you're offline.

## Tech stack

| Area | Technology |
|---|---|
| App | Flutter (Dart), Provider for dependency injection |
| Authentication | Firebase Authentication (email/password, Google) |
| Database | Cloud Firestore, with per-user security rules |
| AI | Google Gemini API (`gemini-flash-lite-latest`) via `google_generative_ai` |
| PDF | `pdf` and `printing` packages, with bundled Open Font License fonts |
| Monitoring | Firebase Analytics and Crashlytics |

## Project structure

```
lib/
├── main.dart              App setup: Firebase, Crashlytics, providers
├── models/                Resume and template data models
├── screens/               Auth, resume form, LinkedIn import, preview/export
├── services/              Auth, Firestore, Gemini, PDF and analytics services
├── utils/                 Friendly error messages
└── widgets/               Resume list, offline banner
assets/fonts/              Resume fonts and their licenses
test/                      Unit and widget tests
firestore.rules            Firestore security rules
```

## Getting started

The app currently targets **Android**. iOS needs its own Firebase app and
configuration.

### Prerequisites

- Flutter 3.47 or newer (Dart 3.13)
- A Firebase project
- A free Gemini API key from [Google AI Studio](https://aistudio.google.com)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Connect Firebase

Firebase config files are git-ignored, so you need to add your own.

1. In the [Firebase console](https://console.firebase.google.com), create a
   project and add an Android app with the package name
   `com.example.resume_builder_ai`.
2. Under **Authentication → Sign-in method**, enable **Email/Password** and
   **Google**.
3. Add your debug SHA-1 fingerprint to the Android app (required for Google
   sign-in). Get it with `cd android && ./gradlew signingReport`.
4. Create a **Cloud Firestore** database.
5. Download `google-services.json` into `android/app/`.
6. Generate `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
7. Deploy the security rules, which let each user read and write only their
   own resumes. Either paste `firestore.rules` into **Firestore → Rules** in
   the console, or run:
   ```bash
   firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   ```

### 3. Add your Gemini API key

Copy the template and paste in your key. `lib/secrets.dart` is git-ignored.

```bash
cp lib/secrets.example.dart lib/secrets.dart
```

### 4. Run

```bash
flutter run
```

## Tests

```bash
flutter analyze
flutter test
```

The tests cover the data models, Firestore resume service (using
`fake_cloud_firestore`), PDF generation for every template and font,
the LinkedIn import review flow, the resume list, the offline banner and
error messages.

## Design notes

- **Gemini is called directly from the app** (TRD approach A). This keeps the
  project free to run, but the API key ships inside the app. For production,
  move the calls into a Firebase Cloud Function so the key stays on the
  server, and restrict the key to this app in the Google Cloud console.
- **LinkedIn import is user-assisted.** LinkedIn's public API only provides
  name, email and photo; experience, education and skills require partner
  approval. Instead, you paste your profile text and Gemini extracts it.
  Manual entry always works.
- **The PDF is the single source of truth** for how a resume looks. The
  preview screen displays the generated PDF rather than a separate on-screen
  layout, which guarantees the export matches the preview.
- **Saves don't wait for the server.** Firestore applies writes to the
  on-device cache immediately and syncs later, so the app never blocks on a
  slow or missing connection.
- **Crashlytics is disabled in debug builds** so development crashes don't
  pollute the reports.

## Before releasing to the Play Store

- Change `applicationId` in `android/app/build.gradle.kts` from
  `com.example.resume_builder_ai` to your own ID. Then register that package
  in Firebase and download a new `google-services.json`.
- Add a release signing config (see the TODO in the same file).
- Restrict the Gemini API key, or move AI calls to a Cloud Function (see
  above).
