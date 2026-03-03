# Backend Architecture & Database Structure

## 1. Architecture Overview (As Implemented)
Architecture pattern not explicitly defined; inferred from folder organization. The application operates on a "Serverless / Backend-as-a-Service (BaaS)" architecture using Firebase directly from the Flutter client. There is no dedicated API server, Node.js/Python backend, or centralized controller layer in this repository. All database reads/writes and authentication flows are executed directly from the client application using the Firebase SDK.

## 2. Database Schema (Exact, Not Idealized)
The application uses Cloud Firestore (NoSQL). The schema below is inferred exactly from the Data Transfer Objects (DTOs) and Models implemented in Dart (`UserModel`, `DrinkLogModel`, `AlcoholModel`).

### Collection: `users`
Source of Truth: `lib/features/profile/models/user_model.dart`
*   `id`: String (Document ID)
*   `displayName`: String (Default: '')
*   `photoUrl`: String? (Nullable)
*   `ageVerified`: Boolean (Default: false)
*   `createdAt`: Timestamp (Mapped to DateTime)
*   `bio`: String? (Nullable)
*   `username`: String (Default: '')

### Collection: `usernames`
Source of Truth: `lib/features/auth/screens/onboarding_screen.dart` (Transaction logic)
*   Document ID: String (The exact chosen lowercase username)
*   `uid`: String (The User ID claiming the username)

### Collection: `alcohols`
Source of Truth: `lib/features/alcohol/models/alcohol_model.dart`
*   `id`: String (Document ID)
*   `name`: String
*   `type`: String
*   `brand`: String
*   `abv`: Number (Mapped to double)
*   `origin`: String
*   `description`: String
*   `imageUrl`: String

### Collection: `drink_logs`
Source of Truth: `lib/features/drink_logs/models/drink_model_dto.dart`
*   `id`: String (Document ID)
*   `userId`: String (Default: '')
*   `alcoholId`: String (Default: '')
*   `username`: String (Default: 'Unknown')
*   `userPhotoUrl`: String? (Nullable)
*   `alcoholName`: String (Default: 'Unknown drink')
*   `alcoholType`: String (Default: 'unknown')
*   `rating`: Number? (Nullable, mapped to double. Used exclusively for Reviews.)
*   `isLiked`: Boolean? (Nullable. Used exclusively for Logs to indicate thumbs up/down.)
*   `note`: String? (Nullable)
*   `logKind`: String (Enum mapped to string: 'log' or 'review')
*   `createdAt`: Timestamp (Mapped to DateTime)
*   `consumedAt`: Timestamp? (Nullable, Mapped to DateTime)
*   `photoUrl`: String? (Nullable)
*   `photoUploadedAt`: Timestamp? (Nullable, Mapped to DateTime)
*   `createdByUserId`: String? (Nullable)

### Collection: `wishlists`
Source of Truth: `lib/features/wishlist/models/wishlist_item_model.dart`
*   `id`: String (Document ID, auto-generated)
*   `userId`: String (Owner of the wishlist item, references `users.id`)
*   `alcoholId`: String (References `alcohols.id`)
*   `alcoholName`: String (Denormalized from `alcohols` for display without extra reads)
*   `alcoholType`: String (Denormalized from `alcohols`)
*   `alcoholImageUrl`: String (Denormalized from `alcohols`)
*   `note`: String? (Nullable — optional personal note, e.g., "heard about this at Jake's party")
*   `addedAt`: Timestamp (When the item was added)

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
*   Hashing strength not explicitly visible in code (managed by Google/Firebase).

## 6. Data Validation Rules (Code-Verified Only)
Validation is implemented exclusively in the client-side `.dart` files:
*   **Age Validation:** During onboarding, `Date of Birth` must calculate to $\ge$ 18 years compared to the device's current date.
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
No structured migration system identified. Schema updates appear to be handled entirely via Dart-side model mapping fallbacks (e.g., `data['photoUrl'] ?? ''`).

## 12. Backup & Recovery
Backup strategy not documented in repository.

## 13. API Versioning
No explicit API versioning strategy implemented.
