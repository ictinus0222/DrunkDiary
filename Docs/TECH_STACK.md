# Technology Stack Documentation

## 1. Stack Overview

Last Updated: 2026-03-03

Architecture Type:
Mobile Client / Serverless Backend (Flutter application communicating directly with Firebase services).

Deployment Configuration:
Firebase configuration identified via `firebase.json`. No external server deployments explicitly documented.

## 2. Frontend Stack (Mobile Client)

Library: Flutter
Version: sdk: flutter (requires Dart SDK ^3.5.3)
Source File Evidence: `pubspec.yaml`
Reason: Core UI toolkit for cross-platform app development. Reason not explicitly documented in repository.

Library: flutter_riverpod
Version: ^3.0.3
Source File Evidence: `pubspec.yaml`
Reason: Primary state management used for UI updates and global configuration management (e.g., Feature Flags).

Library: image_picker
Version: ^1.2.1
Source File Evidence: `pubspec.yaml`
Reason: Image selection from camera/gallery. Reason not explicitly documented in repository.

Library: cached_network_image
Version: ^3.3.1
Source File Evidence: `pubspec.yaml`
Reason: Fetching and caching network images. Reason not explicitly documented in repository.

Library: google_fonts
Version: ^6.3.3
Source File Evidence: `pubspec.yaml`
Reason: Custom typography loading. Reason not explicitly documented in repository.

Library: intl
Version: ^0.19.0
Source File Evidence: `pubspec.yaml`
Reason: Internationalization and date formatting. Reason not explicitly documented in repository.

Library: timeago
Version: ^3.6.0
Source File Evidence: `pubspec.yaml`
Reason: Relative time formatting (e.g., "5 mins ago"). Reason not explicitly documented in repository.

Library: shimmer
Version: ^3.0.0
Source File Evidence: `pubspec.yaml`
Reason: Implementation of skeleton loading states (shimmers) to provide a more stable and premium perceived performance during async data fetching.

Library: cupertino_icons
Version: ^1.0.8
Source File Evidence: `pubspec.yaml`
Reason: Default iOS styling icons. Reason not explicitly documented in repository.

## 3. Backend Stack

The application uses Firebase as a Backend-as-a-Service (BaaS). The following client SDKs integrate with the backend:

Library: firebase_core
Version: ^4.2.1
Source File Evidence: `pubspec.yaml`
Reason: Core initialization for Firebase services. Reason not explicitly documented in repository.

Library: firebase_auth
Version: ^6.1.3
Source File Evidence: `pubspec.yaml`
Reason: User authentication tracking and token management. Reason not explicitly documented in repository.

Library: google_sign_in
Version: ^6.2.1
Source File Evidence: `pubspec.yaml`
Reason: Google OAuth provider integration. Reason not explicitly documented in repository.

Library: cloud_firestore
Version: ^6.1.1
Source File Evidence: `pubspec.yaml`
Reason: NoSQL database storage. Reason not explicitly documented in repository.

Library: firebase_storage
Version: ^13.0.4
Source File Evidence: `pubspec.yaml`
Reason: Cloud storage for user-uploaded images. Reason not explicitly documented in repository.

If database is used but version not specified:
Database version not specified in repository (Firestore is a managed, versionless BaaS).

## 4. Database Configuration

No explicit migration tooling identified. Firestore is schemaless, and no ORM schema files or manual seed scripts were found.

## 5. DevOps & Infrastructure (Code-Verified Only)

Version Control:
System: Git (Identified via `.git` folder)

CI/CD:
No CI/CD configuration found in repository.

Hosting:
Firebase (Identified via `firebase.json` containing Project ID `drunkdiary-d9241`).

Monitoring:
No explicit application monitoring or telemetry configuration (e.g., Crashlytics, Sentry) identified in repository.

## 6. Development Tooling

ESLint / Prettier / Typescript: N/A (Flutter/Dart project)

Testing tools:
- `flutter_test` (Flutter SDK default testing framework)

Linting:
- `flutter_lints`: ^5.0.0
- Configured via `analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml`).

Husky / Pre-commit hooks:
No explicit hooks identified.

## 7. Environment Variables

No `.env` or explicit environment configuration templates identified in the repository.

## 8. Package.json Scripts

Not applicable. (Project relies on Flutter SDK CLI commands, no package.json scripts present). 

## 9. Dependencies Lock

Frontend Dependencies (from `pubspec.yaml`):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^4.2.1
  firebase_auth: ^6.1.3
  cloud_firestore: ^6.1.1
  image_picker: ^1.2.1
  firebase_storage: ^13.0.4
  google_fonts: ^6.3.3
  flutter_riverpod: ^3.0.3
  google_sign_in: ^6.2.1
  intl: ^0.19.0
  timeago: ^3.6.0
  cached_network_image: ^3.3.1
```
*(Exact locked dependency graphs are available in `pubspec.lock`)*.

## 10. Security Configuration (Only If Implemented)

No explicit security hardening configuration identified. Auth and Data access rules are abstracted completely by Firebase SDKs on the client-side. No API or custom middleware constraints exist on the client repository side.

## 11. Version Upgrade Policy

No explicit version upgrade policy documented in repository.
