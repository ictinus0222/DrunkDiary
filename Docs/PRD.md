# Product Requirements Document (PRD)

## 1. Product Overview
Project Title: DrunkDiary
Version: 1.0.6+8
Last Updated: 2026-04-18
Owner: Not explicitly identified in the repository metadata.

DrunkDiary is a Flutter-based mobile application that allows legal-age users to log or review the alcoholic beverages they consume for personal tracking. It securely authenticates users via Google, ensures they are 18+, and acts as a digital diary and tracking shelf for their drinking journey. The app provides a timeline of past drinks, aggregates statistics (like favorite drinks and average ratings) in a "Shelf" view, and enables discovery of beverages via a centralized search architecture.

## 2. Problem Statement
The application solves the problem of tracking and remembering one's experiences with different alcoholic beverages. The core user workflow enables users to log specific moments associated with drinks (noting the context and taking photos) alongside a system where they can review and rate alcohols for their personal records.

## 3. Goals & Objectives (Current State Only)
- Authenticate users securely into the ecosystem and enforce a safe user environment via a global Age Gate.
- Allow users to quickly capture a "Drink Log" (capturing a reaction — loved/liked/nah, photo, and note). **Unified Logging** supports both catalog bottles and custom drinks (mocktails, cocktails, or any unlisted drink).
- Allow users to write personal "Reviews" for catalog alcohols on a 0-5 scale. Reviews are formally distinct from logs and do not increment log counts.
- Aggregate user logs into a personal "Shelf" that showcases their history and average ratings.
- Enable discovery of alcohols via an integrated **Discover** hub, with logging as the primary global action (center `+` button).
- **Premium UX**: Utilize Skeleton UI (Shimmer) for all primary data-driven screens to provide stable and polished loading states.
- Manage global app features via a feature flag system to enable A/B testing and controlled rollouts.

## 4. Success Metrics
Core user engagement and feature usage are tracked via Firebase Analytics to measure retention and discover popular alcohols. Key metrics include:
- **Onboarding Completion:** Percentage of users who finish the 6-step perceived onboarding funnel and claim a unique identity.
- **Logging Velocity:** Average number of logs/reviews created per user per week.
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
- **Premium Identity Onboarding**
  - **Description:** Authenticates users and builds their drinking identity through a polished experience.
  - **User Story:** As a new user, I can sign in with my Google account, confirm my legal drinking age, and build my taste profile so my experience feels personal from the first screen.
  - **Acceptance Criteria:** 
    - Smooth 5-step perceived flow (Legal Age, Name, Taste, Goal, Final).
    - Identity confirmation: Users assert they are of legal drinking age via Yes/No interaction.
    - Blocks ineligible users with a graceful Exit screen.
    - Requires a unique identity name (username) > 3 characters via Firestore transaction.
  - **Edge Cases:** Handles taken usernames gracefully by reverting the transaction and showing a snackbar.
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
    - **Layouts:** Includes a layout switcher button that toggles between Timeline and Gallery views.
    - **Filtering:** Includes "All Activity", "Your Logs", and "Your Reviews" chips with full query logic.
  - **Edge Cases:** Empty state shows a prompt to "log your first drink".
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
- **Search & Discovery**
  - **Description:** Offers a "Discover" feed of all available alcohols with sorting/filtering capabilities and text-based search.
  - **User Story:** As a user, I can browse a random discover feed of alcohols, filter them by type, sort them by rating or review count, or explicitly search for an alcohol's name. I can also see if I've previously logged an alcohol directly from the list.
  - **Acceptance Criteria:** 
    - Default state queries all `alcohols` in random order.
    - Items are displayed as rich cards showing image, type, global rating, and a checkmark if logged/reviewed by the user.
    - Search bar includes a filter button, which opens a bottom sheet allowing sorting (A-Z, High-Low Rating, Most Reviewed) and type filtering (e.g. Whisky, Rum, Vodka).
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
    - **Edit Interaction (UI only)**:
      - Edit button visible
      - No backend integration in V1
  - **Out of Scope (V1)**:
    - Followers / Friends
    - Stats tab
    - Badges / Achievements
    - Profile customization backend

- **In-App Feedback System**
  - **Description:** Allows users to submit screenshots and text feedback directly from their profile.
  - **User Story:** As a user, I want to easily report bugs or suggest features without leaving the app.
  - **Acceptance Criteria:** 
    - Floating action button or icon in Profile triggers `BetterFeedback` overlay.
    - Captures a screenshot of the current screen.
    - Sends feedback via configured email client using `flutter_email_sender`.
    - Handles "No email client found" gracefully with a SnackBar.
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
- **Safe Logout Mechanism**
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
- **Data Storage Behavior:** Images are uploaded directly to Firebase Storage before document creation finishes.
- **Platform Limitations:** No local persistence caching logic is manually implemented extending beyond standard Firestore offline caching.

## 10. Timeline & Milestones
No historical milestone data or version history beyond "1.0.0+1" is identifiable in the current repository.

## 11. Risks & Assumptions
- **Hardcoded Logic:** The legal drinking age is hardcoded to 18, creating compliance risks depending on the region.
- **Performance Constraints:** The Shelf Screen fetches all user logs, groups them in memory, and subsequently fetches each alcohol document individually. This N+1 logic poses a scalability limit as user activity grows.
- **Validation Gaps:** The UI allows users to easily skip inputting notes or photos without explicit fallback content validation.

## 12. Non-Functional Requirements (From Code Only)
- **Security Mechanisms:** Firebase Auth restricts unauthenticated access; users assert age via DOB picker.
- **Storage Limits:** Images are compressed and resized via ImagePicker (`imageQuality: 80, maxWidth: 1080, maxHeight: 1350`) prior to uploading to Firebase Storage. 
- **Validation Rules:** Username creation is validated strictly with a threshold of $\ge 3$ characters and enforced natively with Firestore transactions.
