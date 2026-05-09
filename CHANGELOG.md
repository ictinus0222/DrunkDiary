# Changelog

All notable changes to this project will be documented in this file.

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
