# Product Requirements Document (PRD)

## 1. Product Overview
Project Title: DrunkDiary
Version: 1.1.2+11
Last Updated: 2026-05-09
Owner: Not explicitly identified in the repository metadata.

DrunkDiary is a Flutter-based mobile application that allows legal-age users to log or review the alcoholic beverages they consume for personal tracking. It securely authenticates users via Google, ensures they are 18+, and acts as a digital diary and tracking shelf for their drinking journey. The app provides a timeline of past drinks, aggregates statistics (like favorite drinks and average ratings) in a "Shelf" view, and enables discovery of beverages via a centralized search architecture.

## 2. Problem Statement
The application solves the problem of tracking and remembering one's experiences with different alcoholic beverages. The core user workflow enables users to log specific moments associated with drinks (noting the context and taking photos) alongside a system where they can review and rate alcohols for their personal records.

## 3. Goals & Objectives (Current State Only)
- Authenticate users securely into the ecosystem and enforce a safe user environment via a global Age Gate.
- Allow users to quickly capture a "Drink Log" (capturing a reaction — loved/liked/nah, photo, and note). **Unified Logging** supports both catalog bottles and custom drinks (mocktails, cocktails, or any unlisted drink).
- Allow users to write personal "Reviews" for catalog alcohols on a 0-5 scale. Reviews are formally distinct from logs and do not increment log counts.
- Aggregate user logs into a personal "Shelf" that showcases their history and average ratings.
- Enable discovery of alcohols and community members via a unified **Discover** hub.
- **Social Graph & Privacy**: Private profiles are discoverable in search to enable friend discovery, but their content (logs, reviews, shelf) remains strictly locked behind a friendship requirement.
- **Notifications & Cheers (Social Interaction)**: Consolidate social feedback into a centralized Notifications system triggered by 🥂 Cheers interactions.
- **Premium UX & Analytics**: Utilize Skeleton UI (Shimmer) for polished loading and Firebase Analytics for intent tracking.
- **In-App Beta Feedback**: Integrated a high-fidelity feedback system with clean screenshots and metadata for rapid triage.
- **Account Deletion (Right to be Forgotten)**: Comprehensive data wipe including storage, firestore, and auth for privacy compliance.
- **Platform-First Architecture**: Establish a centralized responsive layout system (Tokens, Governance, Density) to ensure high-quality scaling.
- Manage global app features via a feature flag system to enable A/B testing and controlled rollouts.

## 4. Success Metrics
Core user engagement and feature usage are tracked via Firebase Analytics to measure retention and discover popular alcohols. Key metrics include:
- **Onboarding Completion:** Percentage of users who finish the onboarding funnel and claim a unique identity.
- **Logging Velocity:** Average number of logs/reviews created per user per week.
- **Notification Engagement:** Percentage of users who open the notification center and mark alerts as read.
- **Cheers Interaction Rate:** Number of 🥂 Cheers given per active user.
- **Search Intent:** Most searched alcohol types and brands.
- **Session Duration:** Active time spent in "Diary" and "Shelf" views.
- **Wishlist Conversion**: Percentage of users who add an item to their wishlist and eventually log it.
- **Discovery Engagement**: Interaction rate with the `WishlistDiscoveryCarousel`.
- **Search Content Gap**: Number of "Zero Result" searches per week to prioritize database additions.
- **Feedback Loop**: Volume and sentiment of user-submitted feedback via the in-app portal to identify UX pain points.

## 5. Target Users & Personas (Inferred)
Based on the onboarding flow and feature structure, the target users are individuals of legal drinking age (18+).
- **The Personal Tracker:** Inferred from features allowing users to take photos and choose contexts like "House parties" or "Bars / clubs".
- **The Tasting Enthusiast:** Inferred from the separate personal "Review" flow, which asks for detailed taste profiles and provides a 0-5 star slider to evaluate specific alcohols.
- **The Admin / Moderator:** Specific identified administrative accounts or users with the `admin` or `moderator` role in Firestore.

## 6. Features & Requirements

### P0 (Core Implemented Features)
- **Cinematic Identity Onboarding (V2)**
  - **Description:** A premium, emotionally-driven onboarding experience that communicates the app's mental model before account creation.
  - **User Story:** As a new user, I want to understand the emotional value of DrunkDiary (nostalgia and memory preservation) before I set up my profile.
  - **Acceptance Criteria:** 
    - **9-Step Refined Flow**: 5 Educational screens + 3 Setup screens (Age, Username, Preferences) + 1 Final CTA.
    - **Emotional Positioning**: "Memories fade. Your best nights don’t have to."
    - **Motion System**: Staggered entrance animations and ambient parallax (supports Reduced Motion accessibility).
    - **First Meaningful Action**: Automatically opens the logging modal upon first home landing to drive immediate conversion.
    - **Context Memory**: Persists onboarding metadata (version, preferences, privacy) in the `UserModel` for future personalization.
  - **Analytics**: Tracks `first_log_cta_clicked` and per-step completion/dropoff.
- **Unified Drink Logging**
  - **Description:** Allows users to log any drink, whether it's a specific bottle from the catalog or a custom concoction (cocktail, mocktail, etc.).
  - **User Story:** As a user, I want to log what I'm drinking even if it's not in the app's database, so my diary remains a complete record of my night.
  - **Acceptance Criteria:** 
    - User can log a custom name (e.g., "Espresso Martini").
    - User can optionally "Select a bottle" from the global catalog.
    - User can select a reaction (Loved / Liked / Nah), write a note, and attach a photo.
    - **Photo Capture**: User is prompted to choose between Camera or Gallery source.
    - Data saves to Firestore with `isCustom: true` for unbottled drinks.
  - **Edge Cases:** Missing photo or note resolves to null.
- **Personal Drink Reviewing**
  - **Description:** Allows users to formally rate and review an alcohol for personal use.
  - **User Story:** As a user, I want to review an alcohol so I can see my rating later.
  - **Acceptance Criteria:** User uses a 0-5 slider, provides text, and an optional photo. Saves with `logKind: LogKind.review`. Uses a deterministic ID (`{userId}_{alcoholId}`) to prevent duplicates.
  - **Edge Cases:** Attempting to review the same drink twice overwrites the existing review.
- **Diary (Timeline)**
  - **Description:** Chronological feed of the user's previous logs, acting as the primary diary. Support for multiple view layouts:
    - **Timeline Layout:** A structured grid showing a fixed-width date anchor on the left and a content stream on the right.
    - **Gallery Layout:** A grid-based view showing only closeups of the drink photos.
  - **User Story:** As a user, I want to see my logs in order in my diary, and be able to switch to a visual gallery of my drinks.
  - **Acceptance Criteria:** 
    - Fetches `drink_logs` for `userId`, calculates Total, Avg Rating, and Favorite category dynamically.
    - **Branding:** Uses the standardized `drunk_diary_logo.svg` in the AppBar.
    - **Notifications**: Includes a persistent Notification button in the AppBar with a dynamic unread badge.
    - **Layouts:** Includes a layout switcher button that toggles between Timeline and Gallery views.
    - **Filtering:** Includes "All Activity", "Your Logs", and "Your Reviews" chips with full query logic.
    - **Social Interaction (Cheers)**: Each daily group can receive 🥂 Cheers from the community.
  - **Edge Cases:** Empty state shows a prompt to "log your first drink".
- **Notifications System**
  - **Description**: A centralized feed for social interactions (Cheers) that rewards user activity and fosters community.
  - **User Story**: As a user, I want to see when people cheer my nights so I feel encouraged to keep logging.
  - **Acceptance Criteria**:
    - High-visibility entry point (AppBar button) with a numeric unread badge.
    - Real-time stream of notifications (Firestore-backed).
    - Supports "Cheers" notifications (e.g., "Akhil cheered your activity 🥂").
    - "Mark as read" functionality (individual tap or "Mark all as read" button).
    - Empty state with clear onboarding messaging.
- **Cheers (Social Reaction)**
  - **Description**: A session-based social reaction system (🥂 Cheers) that allows users to react to daily activity cards.
  - **User Story**: As a user, I want to cheer other people's drinking sessions to show support and celebrate their night.
  - **Acceptance Criteria**:
    - Tap Cheers button to toggle (Optimistic UI).
    - Logic: Grouped by session ID (`{userId}_{yyyy-MM-dd}`).
    - **Triggers**: Toggling a cheer creates/removes a notification for the recipient.
- **The Shelf**
  - **Description:** Aggregates all user logs and groups them by `alcoholId`.
  - **User Story:** As a user, I want to see every unique alcohol I have tried and my average rating for it.
  - **Acceptance Criteria:** Fetches the user's logs, groups by ID, retrieves the associated `AlcoholModel`, and computes average rating and total consumption count per alcohol. Displays the unique alcohols in a styled grid ("Shelf"). Includes a sort/filter button that opens a bottom sheet allowing users to sort their shelf (e.g., A-Z, High Rating, Most Consumed).

### P1 (Implemented but Secondary Features)
- **Wishlist (Bucket List)**
  - **Description:** A personal wish list for saving alcohols the user wants to try in the future.
  - **User Story:** As a user, I want to save an alcohol I've heard about so I can find and try it later.
  - **Acceptance Criteria:**
    - User can search for an alcohol from the `alcohols` database and add it to their wishlist.
    - **Premium Curation**: Each item is displayed as a premium 84x84 "Product Tile" (Radius 14).
    - **Smart Discovery**: Includes a `WishlistDiscoveryCarousel` that suggests alcohols based on the user's wishlist categories.
    - **Quick Log**: Dedicated `+ Log` button (Gold Pill) to move items from "Wish" to "Diary".
    - User can remove items from the wishlist.
    - Items already logged/reviewed by the user show a visual "Tried!" indicator.
  - **Edge Cases:** Duplicate wishlist entries for the same alcohol are prevented.
- **Unified Search & Discovery**
  - **Description:** A single, high-performance search surface for both the alcohol catalog and the DrunkDiary community.
  - **User Story:** As a user, I can search for "Whisky" to find bottles or "@alex" to find a friend, all from one search bar.
  - **Acceptance Criteria:** 
    - Real-time debounced search (300ms) using a reactive Stream-based architecture.
    - Results partitioned into "People" and "Bottles" sections.
    - **Weighted Ranking**: Prioritizes exact username matches first, then partial display name matches.
    - **Data Gating**: Private profiles appear in search results but navigate to a "Locked" view state.
    - Search bar includes a filter button for bottle-specific sorting and type filtering.
- **Alcohol Details**
  - **Description:** Displays alcohol information, personal logs, and global community stats.
  - **User Story:** As a user, I can view details of a drink, see my personal logs (excluding reviews), and view community statistics like total global logs, global average rating, and a global reaction distribution.
  - **Acceptance Criteria:** Queries all logs for the specified alcohol to calculate global total logs, personal total logs (logKind: log only), average community rating, and the global reaction distribution. Provides a view of the user's history with the alcohol.
- **Profile Screen (V1 – Identity + Activity Mirror)**
  - **Description**: A personal profile screen focused on identity and activity, acting as a mirror of the user's Diary timeline.
  - **User Story**: As a user, I want to view my profile with my identity (photo, name, bio) and my activity timeline, so I can reflect on my drinking history in a cohesive and premium interface.
  - **Acceptance Criteria**:
    - **Hero Area**:
      - Full-width cover image (~200 height)
      - Overlapping circular avatar (radius 40–50)
      - Display name (bold) and @username (subtle)
      - Optional bio (hidden if empty)
    - **Stats**:
      - Show only: "X DAYS LOGGED"
      - Derived from unique days with logs
    - **Activity Mirror**:
      - Reuse existing `DayActivityCard` and `LogMiniCard`
      - Same grouping logic as Diary (by date)
      - No UI deviation from Diary feed
    - **Privacy Toggle**:
      - A dedicated switch to set the profile as "Private".
      - **Global Impact**: Setting a profile to private hides all associated logs from the community "All Activity" feed.
    - **Edit Profile**:
      - Full-screen editing interface with support for Display Name, Username (with uniqueness validation), Instagram handle, and Bio.
      - **Media Management**: Direct upload of Profile Avatar and Cover Image to Firebase Storage with cache-busting versioning.
      - Discard changes confirmation dialog.
  - **Out of Scope (V1)**:
    - Followers / Friends
    - Stats tab
    - Badges / Achievements
    - Profile customization backend

- **In-App Feedback System**
  - **Description:** Allows users to submit screenshots and text feedback directly from any core screen via a sticky beta disclaimer.
  - **User Story:** As a user, I want to easily report bugs or suggest features without leaving the app, and have them sent directly to the development team.
  - **Acceptance Criteria:** 
    - Floating/Sticky "Beta Disclaimer" dropdown at the bottom of core screens.
    - Captures a **clean screenshot** of the current screen (automatically hiding the disclaimer).
    - Multi-state `FeedbackBottomSheet`: supports category selection, text input, and photo gallery picking.
    - **Persistent Submission**: Shows real-time "Sending..." and "Thank You" states within the sheet.
    - Saves data directly to Firestore (`feedback` collection) and Storage (`feedback/` folder).
- **Admin Bottle Management**
  - **Description:** In-app tool for admins to add new alcohols to the global database.
  - **User Story:** As an admin, I want to add new bottles directly from my phone so the catalog stays up to date without manual Firestore entry.
  - **Acceptance Criteria:**
    - Restricted to users with `role: admin`.
    - Supports image upload to Firebase Storage (`bottles/` path).
    - Auto-generates `searchKeywords` for discovery.
    - Validates required fields (Name, Brand, ABV, Type).
- **Feature Flags & Admin Settings (A/B Testing)**
  - **Description:** A system for controlling visibility of new features globally or per segment.
  - **User Story:** As an admin, I want to toggle experimental features on or off for all users from within the app.
  - **Acceptance Criteria:** Real-time state management via Riverpod. Authentication-restricted entry point in Profile. Persists values in Firestore `configs` collection.
- **Account Deletion Compliance**
  - **Description**: Allows users to permanently delete their account and associated data.
  - **Acceptance Criteria**:
    - Accessible from Settings.
    - Multi-step confirmation dialog to prevent accidental deletion.
    - Clears Firestore user data and triggers Firebase Auth account deletion.
    - Redirects to Login screen upon completion.
- **Safe Logout Mechanism****
  - **Description:** Allows users to securely sign out of the application.
  - **User Story:** As a user, I want to safely logout from my account so that my data is protected and I can switch accounts if needed.
  - **Acceptance Criteria:**
    - A "Logout" option in a Settings Sidebar (Drawer) accessible from the Profile screen.
    - Clears the Firebase Auth session.
    - Triggers `GoogleSignIn().signOut()` to ensure full disconnect.
    - Redirects the user back to the Login screen.
- **In-App Analytics**
  - **Description:** Tracking core user interactions to understand app usage, retention, and content gaps.
  - **Acceptance Criteria:** 
    - Automatically tracks screen views.
    - **Identity Tracking:** Links activity to unique `userId` via `setUserId` for accurate retention metrics.
    - **Intent Funnel:** Tracks `add_to_wishlist` events to measure purchase/trial interest.
    - **Catalog Health:** Tracks `zero_search_results` to identify missing alcohols in the database.
    - **Core Loops:** Instrumented events for Sign-In, Drink Logging, and Alcohol Searches.

- **Immersive Activity Detail Viewer**
  - **Description**: Full-screen, media-first storytelling experience for viewing day activity clusters.
  - **User Story**: As a user, I want to view my activity in an immersive way so I can relive the memory of the night.
  - **Acceptance Criteria**: 
    - Pitch-black background with edge-to-edge media.
    - Horizontal PageView for multiple logs/images.
    - Interactive zoom/pan for images.
    - Floating translucent top bar and social footer.
    - Optimistic Cheers interaction.

### P2 (Minor or Utility Features Already Present)

## 7. Explicitly OUT OF SCOPE (Critical Section)
The following are NOT implemented in the codebase:
- **Log Management:** Deleting or editing standard logs is not clearly implemented (only editing public reviews is supported).
- **Push Notifications:** No logic for alerting users when they are tagged in a log.

## 8. User Scenarios (Only Implemented Flows)
- **Scenario 1: Account Creation & Onboarding**
  - **Context:** User downloads the app and signs in.
  - **Step-by-step:** Tap "Continue with Google" -> Confirm legal age -> Select identity name -> Select taste profile -> Select drinking goals.
  - **System Behavior:** Runs transaction to claim identity. Saves user document with `legalAge: true`. Redirects to Home.
  - **Error States:** If user confirms they are not of legal age, show Block Screen. If identity name is taken, display "Username taken".
- **Scenario 2: Searching and Logging a Drink**
  - **Context:** User is at a bar and wants to log a specific catalog drink.
  - **Step-by-step:** Tap center `+` button -> Tap "Select a bottle" -> Type drink name -> Select Alcohol -> Select reaction -> Save log.
  - **System Behavior:** Unified Logging screen closes, log is pushed to `drink_logs` collection with `alcoholId`, and diary immediately refreshes.
- **Scenario 3: Logging a Custom Cocktail**
  - **Context:** User is drinking a custom cocktail not in the catalog.
  - **Step-by-step:** Tap center `+` button -> Type "Old Fashioned" in the name field -> Take a photo -> Select reaction -> Save log.
  - **System Behavior:** Log is saved with `isCustom: true` and `alcoholId: null`.

## 9. Dependencies & Constraints
- **External APIs/SDKs:** Firebase Authentication, Cloud Firestore, Firebase Storage.
- **Framework Constraints:** Built on Flutter SDK (^3.5.3) using Riverpod for state management.
Library: firebase_core
Version: ^4.7.0
Source File Evidence: `pubspec.yaml`
Reason: Core initialization for Firebase services.

Library: firebase_auth
Version: ^6.4.0
Source File Evidence: `pubspec.yaml`
Reason: User authentication tracking and token management.

Library: google_sign_in
Version: ^7.2.0
Source File Evidence: `pubspec.yaml`
Reason: Google OAuth provider integration.

Library: cloud_firestore
Version: ^6.3.0
Source File Evidence: `pubspec.yaml`
Reason: NoSQL database storage.

Library: firebase_storage
Version: ^13.3.0
Source File Evidence: `pubspec.yaml`
Reason: Cloud storage for user-uploaded images.
- **Performance Constraints:** The Shelf Screen fetches all user logs, groups them in memory, and subsequently fetches each alcohol document individually. This N+1 logic poses a scalability limit as user activity grows.
- **Validation Gaps:** The UI allows users to easily skip inputting notes or photos without explicit fallback content validation.

## 12. Non-Functional Requirements (From Code Only)
- **Security Mechanisms:** Firebase Auth restricts unauthenticated access; users assert age via DOB picker.
- **Storage Limits:** Images are compressed and resized via ImagePicker (`imageQuality: 80, maxWidth: 1080, maxHeight: 1350`) prior to uploading to Firebase Storage. 
- **Validation Rules:** Username creation is validated strictly with a threshold of $\ge 3$ characters and enforced natively with Firestore transactions.
