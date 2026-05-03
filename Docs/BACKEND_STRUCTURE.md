# Backend Architecture & Database Structure

Last Updated: 2026-04-18

## 1. Architecture Overview (As Implemented)
Architecture pattern not explicitly defined; inferred from folder organization. The application operates on a "Serverless / Backend-as-a-Service (BaaS)" architecture using Firebase directly from the Flutter client. There is no dedicated API server, Node.js/Python backend, or centralized controller layer in this repository. All database reads/writes and authentication flows are executed directly from the client application using the Firebase SDK.

## 2. Database Schema (Exact, Not Idealized)
The application uses Cloud Firestore (NoSQL). The schema below is inferred exactly from the Data Transfer Objects (DTOs) and Models implemented in Dart (`UserModel`, `DrinkLogModel`, `AlcoholModel`).

### Collection: `users`
Source of Truth: `lib/features/profile/models/user_model.dart` + `lib/features/auth/services/google_auth_service.dart`
*   `id`: String (Document ID)
*   `email`: String (Set once during initial Google Sign-In, sourced from `FirebaseAuth.user.email`)
*   `displayName`: String (Default: '')
*   `photoUrl`: String? (Nullable)
*   `ageVerified`: Boolean (Default: false)
*   `createdAt`: Timestamp (Mapped to DateTime)
*   `bio`: String? (Nullable)
*   `username`: String (Default: '')
*   `role`: String (Default: 'user', Options: 'admin', 'moderator')
*   `legalAge`: Boolean (Default: true. Set during onboarding after manual confirmation.)
*   `authProvider`: String (Set once during initial Google Sign-In. Value: `'google'`)
*   `onboardingCompleted`: Boolean (Default: false. Set to `true` after onboarding finishes.)
*   `drinkPreferences`: List<String> (Captured during onboarding Stage 3)
*   `tasteProfile`: List<String> (Captured during onboarding Stage 4)
*   `drinkingContext`: List<String> (Captured during onboarding Stage 4)

> **Note:** `email`, `authProvider`, and `onboardingCompleted` are written directly in `google_auth_service.dart` and `onboarding_screen.dart` via raw Firestore maps. They are **not** part of `UserModel.fromFirestore()` — `onboardingCompleted` is accessed via raw map indexing in `AuthGate`.

### Collection: `usernames`
Source of Truth: `lib/features/auth/screens/onboarding_screen.dart` (Transaction logic)
*   Document ID: String (The exact chosen lowercase username)
*   `uid`: String (The User ID claiming the username)

### Collection: `alcohols`
Source of Truth: `lib/features/alcohol/models/alcohol_model.dart`
*   `id`: String (Document ID)
*   `name`: String
*   `type`: String
*   `subType`: String (e.g., "Single Malt")
*   `brand`: String
*   `abv`: Number (Mapped to double)
*   `country`: String (Replacing `origin` for mapping consistency)
*   `volumeMl`: Number
*   `description`: String
*   `imageUrl`: String
*   `tags`: List<String>
*   `avgRating`: Number (Default: 0.0)
*   `ratingCount`: Number (Default: 0)
*   `logCount`: Number (Default: 0)
*   `isVerified`: Boolean (Default: true)
*   `isActive`: Boolean (Default: true)
*   `searchKeywords`: List<String> (Auto-generated trigrams or words for discovery)
*   `nameLowercase`: String (Lowercase version of name for exact match search optimization)
*   `createdBy`: String (uid of the admin)
*   `createdAt`: Timestamp

### Collection: `drink_logs`
Source of Truth: `lib/features/drink_logs/models/drink_model_dto.dart`
*   `id`: String (Document ID)
*   `userId`: String (Default: '')
*   `alcoholId`: String? (Nullable. Null if `isCustom` is true)
*   `isCustom`: Boolean (Default: false. True if logged without a catalog bottle.)
*   `customName`: String? (Name entered by user for custom drinks)
*   `customImageUrl`: String? (Storage URL for custom drink photo if no catalog bottle is linked)
*   `username`: String (Default: 'Unknown')
*   `userPhotoUrl`: String? (Nullable)
*   `alcoholName`: String (Default: 'Unknown drink')
*   `alcoholType`: String (Default: 'unknown')
*   `rating`: Number? (Nullable, mapped to double. Used exclusively for Reviews.)
*   `reaction`: String? (Enum mapped to string: 'loved', 'liked', 'nah'. Used for Logs.)
*   `note`: String? (Nullable)
*   `logKind`: String (Enum mapped to string: 'log' or 'review')
*   `createdAt`: Timestamp (Mapped to DateTime)
*   `consumedAt`: Timestamp? (Nullable, Mapped to DateTime)
*   `photoUrl`: String? (Nullable)
*   `photoUploadedAt`: Timestamp? (Nullable, Mapped to DateTime)

### Collection: `wishlists`
Source of Truth: `lib/features/wishlist/models/wishlist_item_model.dart`
*   `id`: String (Document ID, auto-generated)
*   `userId`: String (Owner of the wishlist item, references `users.id`)
*   `alcoholId`: String (References `alcohols.id`)
*   `alcoholName`: String (Denormalized from `alcohols` for display without extra reads)
*   `alcoholBrand`: String (Denormalized from `alcohols`)
*   `alcoholType`: String (Denormalized from `alcohols`)
*   `alcoholImageUrl`: String (Denormalized from `alcohols`)
*   `note`: String? (Nullable — optional personal note)
*   `addedAt`: Timestamp (When the item was added)

### Collection: `configs`
Source of Truth: `lib/core/flags/feature_flags.dart`
* Document ID: `app_flags`
- (Add future flags here)


**Indexes (Only If Defined):**
No explicit secondary indexes defined in the repository (Firestore handles single-field indexing automatically; no composite index configurations like `firestore.indexes.json` are present).

**Relationships:**
*   `drink_logs.userId` references `users.id` (Implied foreign key, enforced loosely by client code mapping).
*   `drink_logs.alcoholId` references `alcohols.id` (Implied foreign key, enforced loosely by client code mapping).
*   *Note: Because this is NoSQL, these are soft references; there are no DB-level foreign key constraints preventing orphaned records upon deletion.*

## 3. Entity Relationship Description
*   A **User** can create many **Drink Logs**.
*   An **Alcohol** can have many **Drink Logs** associated with it.
*   A **User** owns exactly one unique **Username** identifier.

## 4. API Endpoints (Route-Verified Only)
No explicit API server routes exist in this repository. All data fetching operates via direct Firestore RPC calls triggered within Flutter `StreamBuilder` and `FutureBuilder` widgets.

## 5. Authentication & Authorization (Only If Implemented)
*   **Provider:** Google OAuth explicitly implemented (`signInWithGoogle()`).
*   **SDK Usage:** `FirebaseAuth.instance` is accessed globally.
*   **Guards:** `AuthGate` acts as a primary client-side router, actively guarding the `/home` route behind a non-null `FirebaseAuth.instance.authStateChanges()` stream AND verifying that `onboardingCompleted` is true in the `users` Firestore document.
*   **Session cookies / JWT:** Managed internally by the Firebase Auth SDK. Token expiry and refresh logic are not manually handled in the codebase.
*   **Permission Logic:** Restricted Firestore write access implemented in Security Rules for specific collections:
    *   `match /configs/{document}` write access restricted to specific verified email tokens (`akhilsharma.ptk22@gmail.com` or `sharmakhil1704@gmail.com`).
*   **Analytics Layer:** Operates as a write-only interface via `firebase_analytics` SDK. Data is processed by Google's backend and visualized in the Firebase Console. No direct database access or read logic for analytics is required on the client side.
*   Hashing strength not explicitly visible in code (managed by Google/Firebase).

## 6. Data Validation Rules (Code-Verified Only)
Validation is implemented exclusively in the client-side `.dart` files:
*   **Age Validation:** During onboarding, users must manually confirm they are of legal drinking age in their country (Yes/No choice). "No" selection triggers a hard block screen.
*   **Username Validation:** `username` field is checked for `length >= 3`. Submissions are sanitized to lowercase and verified for uniqueness via a Firestore `runTransaction` covering the `usernames` collection.
*   **Review Duplication Prevention:** When a user creates a public review for an alcohol, the codebase manually dictates a deterministic Document ID (`${userId}_${alcoholId}`) to natively prevent duplicate reviews per alcohol via Firestore overwrite logic.
*   No explicit server-side content sanitization identified (relies on Firestore Security Rules which are not visible in this repository).

## 7. Error Handling Structure
No unified error format. 
*   **Client side:** Errors during authentication or database writes are caught in local `try/catch` blocks.
*   **UI Reflection:** Failures trigger `ScaffoldMessenger.of(context).showSnackBar()` with localized plain-text strings (e.g., "Username already taken.", "Could not save log").

## 8. Caching (Only If Implemented)
No caching layer identified outside of the default offline persistence built into the `cloud_firestore` SDK and `cached_network_image`.

## 9. Rate Limiting (Only If Implemented)
No rate limiting middleware identified.

## 10. Background Jobs / Scheduled Tasks
No background job system identified.

## 11. Database Migrations
No structured migration system identified. Schema updates are handled via Dart-side model mapping fallbacks (e.g., `data['photoUrl'] ?? ''`).

### Active Migration: `isLiked` → `DrinkReaction`
The `DrinkLogModel.fromFirestore()` factory in `drink_model_dto.dart` contains a **live migration fallback** for the legacy `isLiked` boolean field:
```dart
reaction: data['reaction'] != null
    ? DrinkReaction.fromString(data['reaction'] as String)
    : (data['isLiked'] == true
        ? DrinkReaction.liked
        : (data['isLiked'] == false ? DrinkReaction.nah : null)),
```
This converts old `isLiked: true` → `DrinkReaction.liked` and `isLiked: false` → `DrinkReaction.nah` at read time. New documents write the `reaction` field as a string (`'loved'`, `'liked'`, `'nah'`) and do not write `isLiked`.

## 12. Backup & Recovery
Backup strategy not documented in repository.

## 13. API Versioning
No explicit API versioning strategy implemented.
