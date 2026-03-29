# Product Requirements Document (PRD)

## 1. Product Overview
Project Title: DrunkDiary
Version: 1.0.2+3
Last Updated: 2026-03-29
Owner: Not explicitly identified in the repository metadata.

DrunkDiary is a Flutter-based mobile application that allows legal-age users to log or review the alcoholic beverages they consume for personal tracking. It securely authenticates users via Google, ensures they are 18+, and acts as a digital diary and tracking shelf for their drinking journey. The app provides a timeline of past drinks, aggregates statistics (like favorite drinks and average ratings) in a "Shelf" view, and enables discovery of beverages via a centralized search architecture.

## 2. Problem Statement
The application solves the problem of tracking and remembering one's experiences with different alcoholic beverages. The core user workflow enables users to log specific moments associated with drinks (noting the context and taking photos) alongside a system where they can review and rate alcohols for their personal records.

## 3. Goals & Objectives (Current State Only)
- Authenticate users securely into the ecosystem and enforce a strict age gate (18+).
- Allow users to quickly capture a "Drink Log" (capturing a reaction — loved/liked/nah, photo, tags, and context). These are the only entries counted as "Personal Logs".
- Allow users to write personal "Reviews" for alcohols on a 0-5 scale. Reviews are formally distinct from logs and do not increment log counts.
- Aggregate user logs into a personal "Shelf" that showcases their history and average ratings.
- Enable discovery of alcohols via an integrated search mechanism (emphasized as the central app action).
- **Premium UX**: Utilize Skeleton UI (Shimmer) for all primary data-driven screens to provide stable and polished loading states.
- Manage global app features via a feature flag system to enable A/B testing and controlled rollouts.

## 4. Success Metrics
Core user engagement and feature usage are tracked via Firebase Analytics to measure retention and discover popular alcohols. Key metrics include:
- **Onboarding Completion:** Percentage of users who finish the 5-step onboarding and claim a username.
- **Logging Velocity:** Average number of logs/reviews created per user per week.
- **Search Intent:** Most searched alcohol types and brands.
- **Session Duration:** Active time spent in "Diary" and "Shelf" views.
- **Wishlist Conversion:** Percentage of users who add an item to their wishlist and eventually log it.
- **Search Content Gap:** Number of "Zero Result" searches per week to prioritize database additions.

## 5. Target Users & Personas (Inferred)
Based on the onboarding flow and feature structure, the target users are individuals of legal drinking age (18+).
- **The Personal Tracker:** Inferred from features allowing users to take photos and choose contexts like "House parties" or "Bars / clubs".
- **The Tasting Enthusiast:** Inferred from the separate personal "Review" flow, which asks for detailed taste profiles and provides a 0-5 star slider to evaluate specific alcohols.
- **The Admin / Moderator:** Specific identified administrative accounts (`akhilsharma.ptk22@gmail.com`, `sharmakhil1704@gmail.com`) with access to global configuration toggles.

## 6. Features & Requirements

### P0 (Core Implemented Features)
- **Google Sign-In & Onboarding**
  - **Description:** Authenticates users and sets up their initial profile.
  - **User Story:** As a new user, I can sign in with my Google account, verify my age, and set my drink preferences and unique username so I can start logging.
  - **Acceptance Criteria:** Validates date of birth (blocks users under 18); requires a unique username > 3 characters using a Firestore transaction; collects taste/context preferences.
  - **Edge Cases:** Handles taken usernames gracefully by reverting the transaction and showing a snackbar.
- **Private Drink Logging**
  - **Description:** Allows users to log an alcohol privately.
  - **User Story:** As a user, I want to log what I briefly drank with friends.
  - **Acceptance Criteria:** User can select a reaction (Loved / Liked / Nah via `DrinkReaction` enum), write a note, and attach a photo (from camera/gallery). Data saves to Firestore with `logKind: LogKind.log`.
  - **Edge Cases:** Missing photo or note resolves to null.
- **Personal Drink Reviewing**
  - **Description:** Allows users to formally rate and review an alcohol for personal use.
  - **User Story:** As a user, I want to review an alcohol so I can see my rating later.
  - **Acceptance Criteria:** User uses a 0-5 slider, provides text, and an optional photo. Saves with `logKind: LogKind.review`. Uses a deterministic ID (`{userId}_{alcoholId}`) to prevent duplicates.
  - **Edge Cases:** Attempting to review the same drink twice overwrites the existing review.
- **Diary (formerly User Timeline)**
  - **Description:** Chronological feed of the user's previous logs, acting as the primary diary. Support for multiple view layouts:
    - **Timeline Layout:** A list-based view showing full log cards with details (Note, Context, Tags).
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
    - Each wishlist item shows the alcohol's name, type, image, and an optional personal note.
    - User can remove items from the wishlist.
    - Wishlist is private and scoped to the authenticated user only.
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
- **Stats & Taste Identity Page**
  - **Description:** A dedicated space for deep reflection on drinking habits and taste profile.
  - **User Story:** As a user, I want a dedicated space to see my "Taste Identity" and deeper metrics that focus on exploration and memory rather than consumption count.
  - **Acceptance Criteria:** 
    - Displays unique bottles logged vs total entries.
    - Calculates favorite spirit and highest rated bottle.
    - Shows exploration stats (nights recorded, countries explored).
    - Derives taste identity (e.g., "Whisky Explorer").
    - Clean, premium, journal-like UI.
- **Feature Flags & Admin Settings (A/B Testing)**
  - **Description:** A system for controlling visibility of new features globally or per segment.
  - **User Story:** As an admin, I want to toggle experimental features on or off for all users from within the app.
  - **Acceptance Criteria:** Real-time state management via Riverpod. Authentication-restricted entry point in Profile. Persists values in Firestore `configs` collection.
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
  - **Step-by-step:** Tap "Continue with Google" -> Allow popup -> Select Date of Birth (must calculate to 18+) -> Select drink styles (Beer, Whisky) -> Select taste (Smooth) -> Select context (House parties) -> Select discovery style -> Type a username.
  - **System Behavior:** Runs transaction to claim username. Saves user document to Firestore. Redirects to Home Diary.
  - **Error States:** If DOB makes user <18, blocks progress. If username is taken, transaction fails and displays "Username already taken".
- **Scenario 2: Searching and Logging a Drink**
  - **Context:** User is at a bar and wants to log a drink.
  - **Step-by-step:** Go to Search Tab -> Type drink name -> Tap Alcohol -> Tap "LOG" -> Select reaction (Loved / Liked / Nah) -> Save log.
  - **System Behavior:** Bottom sheet closes, log is pushed to `drink_logs` collection, and diary immediately refreshes via StreamBuilder.

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
