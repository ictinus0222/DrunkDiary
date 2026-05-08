# Application Flow Documentation

Last Updated: 2026-05-08

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
  5. `AuthGate` fetches Firestore user document. If missing or `onboardingCompleted` is false, renders `OnboardingScreen`.
  6. `OnboardingScreen` (Step 1): Legal Age Check.
     * Logic: "Are you of legal drinking age?"
     * Action: User selects "YES" to proceed or "NO" to view block screen.
  7. `OnboardingScreen` (Step 2): Name.
     * Logic: "What should the community call you?"
     * Validation: Username > 3 chars and unique in `usernames` collection.
  8. `OnboardingScreen` (Step 3): Taste.
     * Logic: "What's usually in your glass?" (Alcohol preference selection).
  9. `OnboardingScreen` (Step 4): Experience/Goal.
     * Logic: "Why did you join DrunkDiary?" (Taste vibe and setting).
  10. `OnboardingScreen` (Step 5): Finish.
     * UI: "Your shelf is ready."
     * System Action: Firestore transaction claims username and saves profile with `legalAge: true`.
     * System Action: Logs `sign_up` and `onboarding_complete` analytics events.
  11. Resulting State: `Navigator.pushNamedAndRemoveUntil('/home')`.
* **Error States:**
  * Trigger: Google Sign-in fails. 
    * Message: Shows caught exception message or "Something went wrong. Please try again." in red text on `LoginScreen`.
  * Trigger: Username already taken during transaction.
  * Trigger: General failure at final onboarding stage.
    * Message: SnackBar displays "Something went wrong. Please try again."

### Flow: Unified Search and Discovery
* **Goal:** Discover community members and alcohols through a single surface.
* **Entry Point:** `SearchScreen` (Tab index 1).
* **Happy Path:**
  1. `SearchScreen`: Opens on a "Discover" view displaying a random feed of alcohols.
  2. User Action: Types a query in the unified `TextField` (e.g., "John" or "IPA").
  3. System Action: Triggers parallel debounced searches (300ms) for users and alcohols.
  4. UI Elements: Results appear in distinct "People" and "Bottles" sections.
  5. **People Search**: Matches on `usernameLowercase` and `displayNameLowercase`.
  6. **Bottle Search**: Matches on catalog name and brand.
  7. User Action: Taps a search result.
  8. Resulting State: 
     - Alcohol -> `AlcoholDetailScreen`.
     - User -> `ProfileScreen` (If private and not a friend, renders as "Locked").

### Flow: Unified Drink Logging (Custom & Catalog)
* **Goal:** Record a drink interaction, optionally selecting a catalog bottle.
* **Entry Point:** Center "+" button on the `HomeScreen` (Tab index 2).
* **Happy Path:**
  1. User taps the "+" button.
  2. System Action: Opens `UnifiedLoggingScreen`.
  3. **Option A (Catalog Log)**:
     - User taps "Select a bottle" → Opens `BottleSelectionScreen`.
     - User selects an alcohol from the catalog.
     - Alcohol details are populated in the log.
  4. **Option B (Custom Log)**:
     - User types a name (e.g., "Margarita") or leaves as "Custom Drink".
  5. User interacts with Reaction selector, Note text field, and Photo picker (Choice of Camera/Gallery).
  6. User Action: Taps "Log this drink".
  7. System Action: Uploads photo (if selected) and creates document in `drink_logs` with `isCustom` flag and optional `alcoholId`.
  8. Resulting State: Returns to `HomeScreen`.

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
*   **Flow: Submit In-App Feedback**
  * **Goal:** Report an issue or suggest a feature without leaving the app.
  * **Entry Point:** `ProfileScreen` (leadingIconButton).
  * **Happy Path:**
    1. User taps the feedback icon.
    2. System Action: Triggers `BetterFeedback.of(context).show(...)` overlay.
    3. User Action: Captures/Annotates screenshot and types feedback description.
    4. User Action: Taps submit.
    5. System Action: Triggers `FeedbackHandler`. Uses `flutter_email_sender` to launch the device's default email client with the screenshot as an attachment.
    6. Resulting State: Device email composer opens.
  * Message: SnackBar displays "No email client found. Please configure an email account."

### Flow: Profile Flow (V1 + Social Privacy)
* **Goal:** View identity and activity.
* **Entry Point:** `ProfileScreen` (Tab index 4) or Search results.
* **Happy Path (Public/Me)**:
  1. User views their own profile or a public user's profile.
  2. Displays hero area, "Days Logged" stats, and the full activity timeline.
  3. **Self-Heal**: If viewing own profile and search indices are missing, system silently updates Firestore.
* **Happy Path (Locked)**:
  1. User views a private profile they are not friends with.
  2. System Action: Gating logic triggers. `userDrinkLogsProvider` is not queried.
  3. UI Elements: Displays "Locked Profile" UI with blurred placeholders and "Add Friend to Unlock" CTA.
* **Privacy Management**:
  1. User toggles "Private Profile" in Settings.
  2. System Action: Updates user document. Search remains enabled, but profile content becomes gated for others.
* **Social Graph (Friend System)**:
  1. **Sending Request**: User taps "Add Friend" on a profile or search tile.
  2. **Accepting/Rejecting**: Recipient views `FriendRequestsScreen` and chooses to accept or reject.
  3. **Blocking**: User can block another user from their profile, triggering a mutual removal and communication blackout.

## 3. Navigation Map (Actual Structure Only)

```text
AuthGate
├── SplashScreen
├── LoginScreen
├── OnboardingScreen
└── HomeScreen (BottomNavigationBar)
    ├── Tab 0: Diary (DiaryScreen)
    │   ├── Notifications (NotificationsScreen via AppBar badge)
    │   └── Activity Viewer (ActivityDetailViewer via Card Body tap)
    ├── Tab 1: Discover (SearchScreen)
    │   ├── Unified Search (People + Bottles)
    │   ├── WishlistScreen (via AppBar icon)
    │   └── AlcoholDetailScreen
    ├── Tab 2: Unified Logging (UnifiedLoggingScreen - Centered +)
    │   ├── BottleSelectionScreen (Catalog selection)
    │   └── (Saves Log)
    ├── Tab 3: ShelfScreen
    │   └── AlcoholDetailScreen
    ├── Tab 4: ProfileScreen
    │   ├── View Variant: Public (Full Activity)
    │   ├── View Variant: Locked (Private Gated)
    │   ├── SettingsScreen (via AppBar icon)
    │   │   └── Logout Action (Clears Nav Stack)
    │   ├── FriendRequestsScreen (Incoming/Outgoing)
    │   └── FeedbackOverlay (via Leading Action Icon)
    └── Dev Routes
        └── ResponsivePreviewScreen (Breakpoint & Density Audit)
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
  * **State Variants:** 
    - Loading (Skeleton UI / Shimmer).
    - Empty (Standardized `AppEmptyState` with action to log a drink).
    - Layouts (Timeline vs. Gallery).
    - **Privacy Locked**: If a daily session contains a private log, the Cheers interaction is disabled and replaced with a "PRIVATE" badge.
  * **Actions Available:** 
    - Switch between Timeline Layout and Gallery Layout. 
    - 🥂 **Cheers**: Tap the reaction button to celebrate a session.
    - **Notifications**: Tap the badge button to open `NotificationsScreen`.
    - Filter chips for Log/Review types.
* **Screen:** `NotificationsScreen`
  * **Route:** `/notifications`
  * **Access:** Authenticated
  * **Purpose:** Real-time social interaction center. Shows Cheers received from other users.
  * **Actions Available:**
    - Tap item: Mark as read.
    - "Mark all as read" icon in AppBar.
* **Screen:** `SearchScreen`
  * **Route:** `/search` (Tab 1)
  * **Access:** Authenticated
  * **Purpose:** Acts as the "Discover" hub for browsing and searching the alcohol catalog.
  * **State Variants:** Empty ("No results found"), Loading (Skeleton UI).
  * **Actions Available:** Tap Alcohol -> `AlcoholDetailScreen`, Tap Bookmark -> `WishlistScreen`.
* **Screen:** `UnifiedLoggingScreen`
  * **Route:** None (Fullscreen Dialog)
  * **Access:** Authenticated
  * **Purpose:** Central logging interface for both custom drinks and catalog bottles.
  * **Features:** Custom name entry, bottle selection, photo capture (Camera/Gallery), reaction selector.
* **Screen:** `BottleSelectionScreen`
  * **Route:** None (Pushed from UnifiedLogging)
  * **Access:** Authenticated
  * **Purpose:** Filterable list for selecting a specific bottle from the catalog during the logging flow.
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
  * **Purpose:** Displays the user's personal wishlist of alcohols they want to try. Uses a standard `SliverAppBar` for consistent navigation.
  * **State Variants:** Loading (Skeleton UI / Shimmer), Empty (Standardized `AppEmptyState` with action to discover drinks).
  * **Actions Available:** 
      - Gold FAB for "Add Bottle" (opens search sheet).
      - `WishlistItemCard` provides a premium "Product Tile" preview with a `+ Log` button.
      - `WishlistDiscoveryCarousel` (horizontal) for recommendations.
* **Screen:** `ProfileScreen`
  * **Route:** `/profile`
  * **Access:** Authenticated
  * **Purpose:** Displays the user's personal identity (Cover, Avatar, Bio) and an "Activity" feed that mirrors the Diary timeline. Reuses `DayActivityCard` and `LogMiniCard` for consistency.
  * **Actions Available:** 
      - Tapping the Settings icon opens the `SettingsDrawer`.
      - "Edit" button (UI Placeholder).
* **Component:** `SettingsDrawer`
  * **Purpose:** Provides a right-aligned sidebar for account settings and logout functionality.
  * **Admin Logic:** Includes an entry point for `AdminSettingsScreen` if the authenticated account matches authorized admin emails.
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
  * IF "Yes" selected THEN unlock "Continue" step
  * ELSE IF "No" selected THEN render elegant block screen "DrunkDiary is for legal-age users only" and provide "Exit" action.

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
* **`FadeSlidePageRoute`** (`lib/core/navigation/page_transitions.dart`): A custom `PageRouteBuilder` that combines a fade-in with a subtle upward slide (`Offset(0, 0.05)` → `Offset.zero`) over 300ms using `Curves.easeOut`.
* **Hero Animations**: Uses **context-aware prefixes** to prevent tag collisions in the `IndexedStack` (where all tabs are active simultaneously):
  - `search_alcohol_[ID]` (Discover tab)
  - `shelf_alcohol_[ID]` (Shelf tab)
  - `stats_alcohol_[ID]` (Stats screen)
  - `alcohol_log_[LOG_ID]` (Diary entry)
* **`TabChangeNotification`** (`lib/core/navigation/tab_change_notification.dart`): A custom `Notification` subclass enabling child screens (Diary, Shelf) to programmatically switch the parent `HomeScreen` tab index.
* **Onboarding Transitions**: `OnboardingScreen` uses a `PageView` with 300ms `easeInOut` curves for step transitions. Components use subtle scale and fade animations.
* Modal bottom sheets use default Flutter slide-up transitions.
