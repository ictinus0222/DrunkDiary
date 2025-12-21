# SplashScreen

## Purpose (Product View)
`SplashScreen` acts as a neutral holding state while DrunkDiary decides what to do with the user.

It is **not a feature screen**.
It exists to **buy time safely** while background decisions happen.

In DrunkDiary’s context, this screen appears when:
- Firebase Auth state is being resolved
- User profile is being fetched from Firestore
- Onboarding status is being evaluated

## Why This Screen Exists (Problem → Decision)
### Problem
At app launch:
- Auth state is asynchronous
- Firestore reads take time
- Routing decisions cannot be made instantly

Without a splash screen:
- UI flickers between screens
- Users briefly see the wrong screen
- App feels unstable and unpolished

### Decision
Use a minimal, neutral SplashScreen during all loading states.

## Engineering Design (How It Works)
```dart
class SplashScreen extends StatelessWidget
```
- Stateless because:
    - No interaction 
    - No local state 
    - Purely presentational

```dart
static const routeName = '/splash';
```

- Allows:
    - Named routing 
    - Programmatic navigation if needed later
- Keeps navigation consistent with the rest of the app

```dart
return Scaffold(
body: Center(
child: Text('DrunkDiary 🍻')
),
);
```

### Intentional minimalism
- No loaders
- No animations (for now)
- No distractions

This avoids:
- Performance overhead
- Visual noise during critical logic execution

## How SplashScreen Fits in the Overall Flow
```text
App Launch
↓
SplashScreen
↓
AuthGate decision
↓
Login / Onboarding / Home
```
It is **never user-driven** — only system-driven.