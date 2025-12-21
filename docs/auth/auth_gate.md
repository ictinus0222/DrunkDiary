# AuthGate 

## Purpose

`AuthGate` is the **single source of truth for user access** in DrunkDiary.

It's job is to decide, at app launch and at every auth change:
- **Who the user is**
- **What stage they are in**
- **Which screen are they allowed to see**

This directly supports DrunkDiary's product goals:
- Frictionless entry (Google login)
- Proper onboarding before logging drinks
- Clean separation between first-time users and returning users

---

## Why AuthGate Exists (Problem → Decision)

### Problem

Without a centralized gate:
- Auth checks get scattered across screens 
- Login / logout flows become buggy 
- Onboarding logic becomes inconsistent 
- Product flow breaks as features grow

### Decision

Use a dedicated AuthGate widget as the app’s entry point that:
- Reacts to authentication state 
- Fetches user profile once 
- Routes users deterministically 

---

## High-Level Flow (User Journey)

1. App launches 
2. Firebase Auth state is checked 
3. If not logged in → Login 
4. If logged in → Fetch user profile 
5. If onboarding incomplete → Onboarding 
6. If onboarding complete → Home

This mirrors the intended product funnel:
   Access → Context → Intent → Core Experience

---

## Engineering Design (How It Works)
### 1. Auth state listener (real-time)
````dart
   StreamBuilder<User?>(
   stream: FirebaseAuth.instance.authStateChanges(),
   )
````
**Why this matters**
- Listens continuously for login/logout 
- Automatically rebuilds UI on auth changes 
- No manual navigation logic needed

**Product impact**
- Instant logout handling 
- Seamless re-entry after login 
- Reliable session behavior

### 2. Loading states handled explicitly
```dart
  if (authSnapshot.connectionState == ConnectionState.waiting)
```
**Decision**
Show `SplashScreen` during:
- Auth resolution 
- Firestore fetch

**Why**
- Prevents UI flicker
- Avoids premature screen rendering
- Creates a controlled, calm entry experience

### 3. Logged-out users → Login
```dart   
   if (!authSnapshot.hasData) {
   return LoginScreen();
   }
```
**Product reasoning**
- Login is the first meaningful action
- No partial access before authentication
- Keeps data integrity intact

### 4. Firestore user profile fetch (one-time)
```dart   
FirebaseFirestore.instance
   .collection('users')
   .doc(user.uid)
   .get()
```
**Key decision**
- Uses `FutureBuilder`, not `StreamBuilder`

**Why**
- User profile changes rarely
- Onboarding status doesn’t need real-time updates
- Reduces Firestore reads (cost + performance)

### 5. Onboarding gate (product-critical)
```dart   
if (!userSnapshot.hasData || !userSnapshot.data!.exists)
```
and
```dart
final onboardingCompleted =
data['onboardingCompleted'] ?? false;
```

**Product insight (from survey & vision)**
- Users should not log drinks without context
- Preferences, intent, and framing matter more than raw logging
- Onboarding ensures:
  - Better recommendations later 
  - Cleaner logs 
  - Higher long-term retention

**Fail-safe design**
- Missing field defaults to false
- Missing document → onboarding
- No undefined state

### 6. Final routing decisions
- `onboardingCompleted == true` → `HomeScreen`
- Otherwise → `OnboardingScreen`

This guarantees:
- No user bypasses onboarding
- Home always represents a “ready” user

## Architectural Principles This File Enforces
- **Single responsibility:** AuthGate only decides access
- **No business logic in UI screens**
- **Centralized flow control**
- **Firestore reads only when necessary**
- **Safe defaults over assumptions**