# main.dart

## Purpose
```main.dart``` is responsible for:
- Bootstrapping Flutter
- Initializing Firebase
- Deciding the app's entry point
- Setting up global configurations

It does NOT handle UI rendering or business logic.

---

## App Startup Flow
1. ```main()``` is the first function that runs.
2. ```WidgetsFlutterBinding.ensureInitialized()``` prepares flutter for async/native calls.
3. ```Firebase.initializeApp()``` connects the app to Firebase services.
4. ```runApp(DrunkDiaryApp())``` starts rendering the UI.

---

## Root Widget: ```DrunkDiaryApp```
- Extends ```StatelessWidget```, meaning it has no mutable state and app-level configs do not change.
- Uses ```MaterialApp``` as root container to set up:
  - App title
  - Theme (colors, fonts)
  - Home screen (initial route)

---

## Entry Point Logic
```dart
    home: AuthGate();
```
- AuthGate decides what the user sees first
  - Logged in -> HoneScreen
  - Not logged in -> LoginScreen -> OnboardingScreen
- This centralizes authentication logic and avoids messy checks across screens.

---

## Routing
- Named routes are defines using ```AppRoutes```.
- Prevents hardcoded strings and navigation bugs.
- enables clean navigation, logout flows, and future deep linking.

---

## Theme
```dart
    theme: AppTheme.darkTheme
```
- Global styling lives in one place. 
- Keeps UI consistent.

---

**main.dart starts the app, AuthGate controls access, routes handle navigation, theme controls branding.**