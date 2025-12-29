# LoginScreen
LoginScreen is the entry point into trust for DrunkDiary.

## Purpose
- Reduce friction at first contact
- Set emotional tone (memories > alcohol)
- Reassure users about privacy
- Move users into the app with minimum cognitive load

This aligns directly with survey insights:
- Drinking is social and emotional
- People don’t want “accounts”, they want memories
- Over-engineering the login would increase drop-off

## Why Google-Only Login (Product Decision)
**Problem**
- Email/password = friction
- Password fatigue = abandonment
- Manual verification = slow onboarding

**Decision**
Use **Google Sign-In only** for MVP.
**Why this fits DrunkDiary**
- Target users are students & young adults
- Google accounts already exist
- Faster path from curiosity → first log
This decision optimizes for activation, not technical completeness.

## Engineering Structure (Why StatefulWidget)
```dart
class LoginScreen extends StatefulWidget
```
**Why state is needed**
- Track loading state (_isLoading)
- Display auth errors (_error)
- Disable button during async operations
Stateless wouldn’t be enough here.

## Core State Variables
```dart
bool _isLoading = false;
String? _error;
```
## Product intent
- Prevent multiple login attempts
- Give immediate feedback if something fails
- Maintain perceived reliability
This avoids the classic “tap spam” + silent failure UX.

## Google Sign-In Handler
```dart
Future<void> _handleGoogleSignIn() async
```
## What happens (user perspective)

1. Button tapped 
2. UI enters loading state 
3. Google auth popup appears 
4. User completes login
5. AuthGate takes over routing

## What happens (system perspective)
- Delegates auth to `google_auth_service`
- Keeps UI logic clean
- Centralizes auth implementation elsewhere

## Error Handling
```dart
on FirebaseAuthException catch (e)
```
- Shows Firebase-specific error messages
- Falls back to a generic message for unknown issues
**Why this matters**
- Users don’t feel “nothing happened”
- Errors are visible but not technical
- Reduces confusion and retries

## Button Disable Logic
```dart
onPressed: _isLoading ? null : _handleGoogleSignIn
```
**Product reason**
- Prevents duplicate auth requests
- Avoids broken auth states
- Makes the app feel intentional
This is a small line with huge UX impact.