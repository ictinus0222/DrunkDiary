# Technology Stack Documentation

## 1. Stack Overview

Last Updated: 2026-05-08

Architecture Type:
Mobile Client / Serverless Backend (Flutter application communicating directly with Firebase services).

Deployment Configuration:
Firebase configuration identified via `firebase.json`.
Build uses Android Gradle Plugin (AGP) 8.9.1 and JDK 17 as the minimum baseline for modern Flutter builds (configured in `android/app/build.gradle`).

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
Version: ^8.0.2
Source File Evidence: `pubspec.yaml`
Reason: Custom typography loading. Reason not explicitly documented in repository.

Library: intl
Version: any
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

Library: flutter_svg
Version: ^2.0.10
Source File Evidence: `pubspec.yaml`
Reason: Rendering scalable vector graphics (SVGs), primarily for the AppBar branding logo.

Library: cupertino_icons
Version: ^1.0.8
Source File Evidence: `pubspec.yaml`
Reason: Default iOS styling icons. Reason not explicitly documented in repository.

Library: screenshot
Version: ^3.0.0
Source File Evidence: `pubspec.yaml`
Reason: High-fidelity in-app screen capture for bug reporting and feedback.

Library: path_provider
Version: ^2.1.4
Source File Evidence: `pubspec.yaml`
Reason: Accessing local file system paths for temporary storage.

Library: package_info_plus
Version: ^9.0.0
Source File Evidence: `pubspec.yaml`
Reason: Reading application package information.

Library: url_launcher
Version: ^6.3.1
Source File Evidence: `pubspec.yaml`
Reason: Opening browser URLs for privacy policies and external links.

### Responsive Architecture Implementation
- **Layout Governance**: `ResponsiveScaffoldBody` and `SliverResponsiveConstrainedBox` (Custom components).
- **Design Tokens**: `lib/core/theme/responsive_tokens.dart` (Semantic widths: 600px, 800px, 1200px).
- **Adaptive Utilities**: `lib/core/utils/responsive_utils.dart` (Context extensions for `isTablet`, `isDesktop`).

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
Version: ^7.2.0
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

## 5. Monitoring
- **Telemetry:** Firebase Analytics used for tracking user behavior and feature engagement. Automatically tracks screen transitions and custom business events. Supports context-aware identity tracking (`setUserId`).
- **Crash Reporting:** Firebase Crashlytics is integrated for real-time monitoring of application stability and fatal/non-fatal exception tracking.
- **Icon Generation:** `flutter_launcher_icons: ^0.14.3` used for cross-platform icon scaling and adaptive background/foreground management.

## 6. Development Tooling

ESLint / Prettier / Typescript: N/A (Flutter/Dart project)

Testing tools:
- `flutter_test` (Flutter SDK default testing framework)

Linting:
- `flutter_lints`: ^6.0.0
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
  google_fonts: ^8.0.2
  flutter_riverpod: ^3.0.3
  google_sign_in: ^7.2.0
  intl: any
  timeago: ^3.6.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.10
  firebase_analytics: ^12.3.0
  firebase_crashlytics: ^5.2.0
  firebase_remote_config: ^6.4.0
  screenshot: ^3.0.0
  path_provider: ^2.1.4
  package_info_plus: ^9.0.0
  url_launcher: ^6.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.3

fonts:
  - CategoriesElegant
  - DMSans
  - GiveYouGlory
```
*(Exact locked dependency graphs are available in `pubspec.lock`)*.

## 10. Security Configuration (Only If Implemented)

No explicit security hardening configuration identified. Auth and Data access rules are abstracted completely by Firebase SDKs on the client-side. No API or custom middleware constraints exist on the client repository side.

## 11. Version Upgrade Policy

No explicit version upgrade policy documented in repository.
