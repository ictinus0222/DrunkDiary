# Application Flow Documentation

Last Updated: 2026-03-29

## 1. Entry Points (Code-Verified Only)
* **Primary Entry Points:** 
  * Default route behavior: The application starts at `main.dart` which initializes Firebase and renders the `App` widget with its initial `home` set to `AuthGate()`.
* **OAuth Providers:** Google Sign-In is explicitly configured and triggered from the login screen.
* **Telemetry:** Firebase Analytics is integrated at the root level to track navigation and user actions.
* **Missing Elements (Not Implemented):**
  * No deep linking logic identified in codebase.
  * No push notification entry flows identified.
  * Admin-only access points restricted to specific authenticated emails via UI-level checks.

## 2. Core User Flows (Implemented Only)

### Flow: Authentication & Onboarding
* **Goal:** Authenticate the user into the system, verify their age, and capture initial preferences.
* **Entry Point:** Initial app launch (handled by `AuthGate`).
* **Frequency:** Once per account creation / device login.
* **Happy Path:**
  1. `SplashScreen` rendered while Firebase Auth initializes.
  2. `AuthGate` resolves auth state. If no user, renders `LoginScreen`.
  3. `LoginScreen`: User clicks "Continue with Google".
  4. System Action: Triggers `signInWithGoogle()`. Redirects back to `AuthGate`.
  5. `AuthGate` fetches Firestore user document. If missing or `onboardingCompleted` is false, renders `OnboardingScreen`.
  6. `OnboardingScreen` (Step 0): User selects Date of Birth.
     * Validation Logic: Must calculate age $\ge$ 18.
  7. `OnboardingScreen` (Steps 1-4): User selects Drink Preferences, Taste Profile, Drinking Context, and Discovery Style.
  8. `OnboardingScreen` (Step 5): User types a username.
     * Validation Logic: Length $\ge$ 3 characters.
     * System Action: Debounces and checks availability against `usernames` collection.
  9. User clicks "Finish".
     * System Action: Firestore transaction attempts to claim username and save user profile.
     * System Action: Logs `sign_up` and `onboarding_complete` analytics events.
  10. Resulting State: `Navigator.pushNamedAndRemoveUntil('/home')`.
* **Error States:**
  * Trigger: Google Sign-in fails. 
    * Message: Shows caught exception message or "Something went wrong. Please try again." in red text on `LoginScreen`.
  * Trigger: Username already taken during transaction.
    * Message: SnackBar displays "Username already taken. Try another."
  * Trigger: General failure at final onboarding stage.
    * Message: SnackBar displays "Something went wrong. Please try again."

### Flow: Search and View Item
* **Goal:** Discover and view an alcohol item.
* **Entry Point:** `SearchScreen` (Tab index 2).
* **Happy Path:**
  1. `SearchScreen`: Opens on a "Discover" view displaying all database alcohols as rich cards.
  2. User Action (Optional): Taps the filter icon to open the `FilterBottomSheet` to select Sort Order and Alcohol Type.
  3. User Action (Optional): Types a query in `TextField`.
  4. System Action: Fetches matching documents from `alcohols` collection applying sort, filter, and text criteria, while checking the user's `drink_logs` for indicators.
  5. UI Elements: Renders matched cards showing global ratings and user logging status.
  6. **System Action**: If search returns no results, logs `zero_search_results` with the query string.
  7. User Action: Taps an alcohol card.
  8. Resulting State: `Navigator.push(AlcoholDetailScreen)`.

### Flow: Log a Drink / Write a Review
* **Goal:** Record an interaction with an alcohol.
* **Entry Point:** `AlcoholDetailScreen` or Profile Screen.
* **Happy Path:**
  1. `AlcoholDetailScreen`: User taps "LOG" (or "REVIEW").
  2. System Action: triggers `showModalBottomSheet(CreateLogBottomSheet)` (or `CreateReviewBottomSheet`).
  3. UI Elements: User interacts with Reaction selector (Loved / Liked / Nah via `DrinkReaction` enum) (or Rating slider for Reviews), Note text field, and Photo picker.
  4. User Action: Taps "Save log" (or "Publish review").
  5. System Action: Uploads photo (if selected) to Firebase Storage, then writes/updates document in `drink_logs`. 
  6. **System Action**: Logs `create_drink_log` with kind (log/review) and reaction metadata.
  7. Resulting State: `Navigator.pop(context)` closes the bottom sheet.
* **Error States:**
  * Trigger: Firebase write failure.
    * Message: SnackBar displays "Could not save log" (or "Could not publish review").
* **Edge Cases:**
  * For reviews: Uses a deterministic document ID (`{userId}_{alcoholId}`) to overwrite existing reviews rather than creating duplicates. If a review exists, "EDIT REVIEW" opens the review editor with existing data populated.

## 3. Navigation Map (Actual Structure Only)

```text
AuthGate
├── SplashScreen
├── LoginScreen
├── OnboardingScreen
└── HomeScreen (BottomNavigationBar)
    ├── Tab 0: DiaryScreen
    │   └── StatsScreen (via action button)
    ├── Tab 1: WishlistScreen
    │   └── AlcoholDetailScreen (via tapping a wishlist item)
    ├── Tab 2: Discover (SearchScreen - Emphasized Icon)
    │   ├── AlcoholDetailScreen
    │   │   ├── CreateLogBottomSheet (Modal)
    │   │   ├── CreateReviewBottomSheet (Modal)
    │   │   └── EditReviewBottomSheet (Modal)
    ├── Tab 3: ShelfScreen
    │   └── AlcoholDetailScreen
    └── Tab 4: ProfileScreen
        └── AdminSettingsScreen (Restricted Entry via Settings Icon)
```

## 4. Screen Inventory (Code-Verified)

* **Screen:** `AuthGate`
  * **Route:** `/auth`
  * **Access:** Public
  * **Purpose:** StreamBuilder root that acts as the primary routing switch based on Auth state and Firestore profile completeness.
* **Screen:** `LoginScreen`
  * **Route:** `/login`
  * **Access:** Public
  * **Purpose:** Prompts for Google Sign-In.
  * **State Variants:** Loading (CircularProgressIndicator replaces Google button), Error (Displays red text).
* **Screen:** `OnboardingScreen`
  * **Route:** `/onboarding`
  * **Access:** Authenticated (Missing Profile)
  * **Purpose:** Multi-step form to collect age, preferences, and username.
  * **State Variants:** Loading (CircularProgressIndicator on Submit button).
* **Screen:** `HomeScreen`
  * **Route:** `/home`
  * **Access:** Authenticated (Complete Profile)
  * **Purpose:** Hosts the `BottomNavigationBar` and manages switching between the 5 primary tabs.
* **Screen:** `DiaryScreen`
  * **Route:** `/diary`
  * **Access:** Authenticated
  * **Purpose:** Fetches user's `drink_logs` and displays them in a customizable diary view. Includes summary stats and a layout switcher. Standardized with the `drunk_diary_logo.svg` branding.
  * **State Variants:** Loading (Skeleton UI / Shimmer), Empty (Standardized `AppEmptyState` with action to log a drink), Layouts (Timeline vs. Gallery).
  * **Actions Available:** Switch between Timeline Layout (detailed list) and Gallery Layout (photo grid). Working filter chips for Log/Review types.
* **Screen:** `SearchScreen`
  * **Route:** `/search`
  * **Access:** Authenticated
  * **Purpose:** Queries Firestore for drinks.
  * **State Variants:** Empty ("Start typing to search" / "No results found"), Loading (CircularProgressIndicator).
  * **Actions Available:** Tap Alcohol -> `AlcoholDetailScreen`.
* **Screen:** `AlcoholDetailScreen`
  * **Route:** `/alcoholDetail`
  * **Access:** Authenticated
  * **Purpose:** Shows details and personal logs stream for a specific alcohol. Displays a "Community Stats" section showing total community logs, personal logs (filtered to logs only), community average rating, and a global reaction distribution. Contains action buttons to trigger Logging/Reviewing.
* **Screen:** `ShelfScreen`
  * **Route:** `/shelf`
  * **Access:** Authenticated
  * **Purpose:** Aggregates, counts, and averages the user's logs grouped by alcohol. Includes sorting functionality via a bottom sheet allowing users to reorder their items (A-Z, High Rating, Most Consumed).
  * **State Variants:** Loading (Skeleton UI / Shimmer), Empty (Standardized `AppEmptyState` with action to discover drinks).
* **Screen:** `WishlistScreen`
  * **Route:** `/wishlist`
  * **Access:** Authenticated
  * **Purpose:** Displays the user's personal wishlist of alcohols they want to try. Cross-references `drink_logs` to show a "Tried!" badge on already-logged items.
  * **State Variants:** Loading (Skeleton UI / Shimmer), Empty (Standardized `AppEmptyState` with action to add from search).
  * **Actions Available:** Empty state button opens `AddToWishlistSheet` (search + note), `WishlistItemCard` provides remove action, tap item → `AlcoholDetailScreen`.
* **Screen:** `ProfileScreen`
  * **Route:** `/profile` (if any)
  * **Access:** Authenticated
  * **Purpose:** Displays the user's personal profile including basic info (avatar, username), dynamic statistics (Drinks Tried, Favorite Type, Top Rated), a horizontal "Public Shelf" showcasing recently logged alcohols, and a "Recent Activity" vertical feed of individual drink logs. Contains a settings action in the app bar.
  * **Admin Logic:** Settings icon checks for `akhilsharma.ptk22@gmail.com` or `sharmakhil1704@gmail.com` to trigger navigation to `AdminSettingsScreen`.
* **Screen:** `StatsScreen`
  - **Route:** `/stats`
  - **Access:** Authenticated
  - **Purpose:** Displays detailed user metrics and taste identity cards focused on memory and exploration.
* **Screen:** `AdminSettingsScreen`
  * **Route:** `/adminSettings`
  * **Access:** Restricted (Authorized Admin Emails Only)
  * **Purpose:** Real-time toggle control for feature flags (e.g., "Personal Meaning Section"). Uses Riverpod to update global state persisted in Firestore.

## 5. Decision Points (Derived from Conditionals)

* **Auth & Routing Logic (in `AuthGate`)**
  * IF `authSnapshot.connectionState == ConnectionState.waiting` THEN render `SplashScreen()`
  * ELSE IF `!authSnapshot.hasData` THEN render `LoginScreen()`
  * ELSE IF `userSnapshot.connectionState == ConnectionState.waiting` THEN render `SplashScreen()`
  * ELSE IF `userSnapshot` does not exist THEN render `OnboardingScreen()`
  * ELSE IF `onboardingCompleted == true` THEN render `HomeScreen()`
  * ELSE render `OnboardingScreen()`

* **Onboarding Age Validation**
  * IF `calculatedAge >= 18` THEN unlock "Continue" step
  * ELSE render validation text "You must be of legal drinking age" and disable "Continue" button.

* **Onboarding Username Lookahead**
  * IF `username.length < 3` THEN `usernameError = 'Username must be at least 3 characters'`
  * ELSE IF Firestore doc exists for username THEN `usernameError = 'Username already taken'`
  * ELSE allow submission.

## 6. Error Handling Flows (Code-Verified Only)
* **API/Firebase Writes:** Use basic `try/catch` wrappers. If an error is caught, the app utilizes `ScaffoldMessenger.of(context).showSnackBar()` to display generic feedback (e.g., "Could not save log").
* **Login Exception:** Catches `FirebaseAuthException` and maps the `.message` directly to the `_error` state string on the screen.
* No global error handling logic identified (e.g., custom 500 pages, global error boundaries).
* No route fallback handling identified (e.g., 404 pages). Navigation expects exactly valid arguments.

## 7. Responsive Behavior (Only If Explicit)
* **Keyboard Inset Handling:** Modal Bottom Sheets (Create Log, Create Review, Tagging) implement padding dynamically calculated via `MediaQuery.of(context).viewInsets.bottom + 16` to prevent the software keyboard from obscuring content.
* No explicit device-specific logic identified (e.g., tablet/desktop layouts or breakpoints).

## 8. Animations & Transitions (If Implemented)
* **`FadeSlidePageRoute`** (`lib/core/navigation/page_transitions.dart`): A custom `PageRouteBuilder` that combines a fade-in with a subtle upward slide (`Offset(0, 0.05)` → `Offset.zero`) over 300ms using `Curves.easeOut`. Used for navigating to `AlcoholDetailScreen` from Wishlist, Shelf, and Discover cards.
* **`TabChangeNotification`** (`lib/core/navigation/tab_change_notification.dart`): A custom `Notification` subclass enabling child screens (Diary, Shelf) to programmatically switch the parent `HomeScreen` tab index — primarily used to navigate users to the Search tab (index 2) from empty states and action buttons.
* Modal bottom sheets use default Flutter slide-up transitions.
