# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0+13] - 2026-06-01

### Added
- **Onboarding Overhaul**:
  - Global scroll-coupled parallax and cross-fading background stack.
  - Alternate "Not Drinking" Flow: Transitions the Polaroid to a specialized context card, letting users choose their favorite alcohol and write a star-rated review without photo uploads.
  - Dynamic Progress Checklist: Adaptively skips photo uploads and updates labels/indicators for photo-less entries.
  - Shelf Visualization: Displays database brand images or gold/amber fallback icons, with review rating bubbles showing star scores (`⭐ 4.5`).

### Fixed & Optimized
- **Performance**: Integrated `RepaintBoundary` around high-animation layouts to ensure a smooth 60fps experience on Impeller/Vulkan.
- **Onboarding Keyboard Dismissal**: Unfocuses keyboard on all onboarding page transitions.
- **Camera Stream Stabilization**: Fixed stream configuration errors on physical Android devices.
- **Camera Lifecycle Fix**: Resolved camera lifecycle pause/resume crash.

## [1.2.0+12] - 2026-05-29

### Added
- **Shared Logs (Tagging)**: Users can now tag friends directly in their drink logs, creating shared memories visible to both parties.
- **Paginated Diary Feed**: The main diary now loads in pages with infinite scroll — smoother performance at any diary size, and a loading indicator while fetching more.
- **Wishlist Stream Caching**: Wishlist state is now managed via a cached Riverpod provider, reducing redundant Firestore reads and improving responsiveness.

### Fixed & Optimized
- **Performance — Image Memory**: Applied `memCacheWidth` and `ResizeImage` across feed cards, avatars, and the activity detail viewer to significantly reduce RAM usage on high-density screens.
- **Performance — Stream Lifecycle**: Moved Firestore stream creation out of `build()` methods and into properly lifecycle-managed providers, reducing listener churn and network traffic.
- **Performance — Firestore Caching**: Alcohol catalog entries are now kept alive in memory via `ref.keepAlive()`, eliminating repeated reads when navigating to bottle detail pages.
- **Stability — DiaryScreen Crash**: Fixed a `LateInitializationError` that could crash the Diary screen during rapid navigation or hot-reload by converting the scroll controller to a nullable, safely-disposed field.
- **Memory Leak — FeedbackSheet**: Fixed a missing `_messageController.dispose()` call in the feedback bottom sheet.
- **Riverpod v3 Compatibility**: Migrated `PaginatedAllLogsNotifier` and `PaginatedFriendsFeedNotifier` from deprecated `StateNotifier` to the `Notifier` API.
- **Deprecations**: Replaced all `withOpacity()` calls with `withValues(alpha:)` across the codebase. Replaced `activeColor` with `activeThumbColor` in Switch widgets.
- **Code Cleanup**: Removed unused imports and local variables across 8 files, flagged by static analysis.

## [1.1.2+11] - 2026-05-09


### Added
- **Premium Account Deletion**: Implemented a "Right to be Forgotten" compliant deletion system.
  - Structure: Wipes User Document, Username Reservations, Drink Logs, Activity Sessions, Wishlists, Notifications, and Feedback.
  - Storage: Purges all associated media (Profiles, Drink Photos, Feedback Screenshots).
  - UI: Redesigned with a high-fidelity danger alert and impact breakdown.
- **In-App Beta Feedback**: Integrated a custom, Firestore-backed feedback triage system.
  - Features: Category selection, automatic clean screenshots (hiding UI overlays), and metadata collection (device/screen context).
- **Beta Tester Disclaimer**: Added a persistent, expandable disclaimer at the bottom of core screens for transparency and direct feedback access.

### Fixed & Optimized
- **Discover Grid Spacing**: Optimized the Discover feed for density by removing redundant card margins and tightening vertical grid spacing.
- **Search Navigation**: Resolved a navigation trap where users could get stuck on the login screen after re-authentication during deletion.
- **Security Rules**: Updated Firestore and Storage rules to permit total data removal while maintaining admin-only gates for the bottle catalog.
- **Storage Cleanup**: Fixed orphaned file issues by implementing recursive path-based deletion for user-generated media.

## [1.1.1+10] - 2026-05-08
- **Cinematic Onboarding**: Implemented a multi-step, visual education flow for new users.
- **Unified Search**: Launched "People + Bottles" unified discovery interface.
- **Social Privacy**: Introduced "Private Profile" mode to gate community feed visibility.

## [1.1.0+9] - 2026-05-07
- **Unified Logging**: Combined catalog bottles and custom drinks into a single logging flow.
- **Social Cheers**: Added real-time reaction support for daily activity sessions.
- **Notifications Center**: Centralized social interaction alerts.
