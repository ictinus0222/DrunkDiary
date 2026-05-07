# 🍻 DrunkDiary

DrunkDiary is a Flutter-based mobile application that allows legal-age users to log or review the alcoholic beverages they consume for personal tracking. It acts as a digital diary and tracking shelf for your drinking journey.

## 🚀 Overview
<!-- SYNC_OVERVIEW_START -->
- Authenticate users securely into the ecosystem and enforce a safe user environment via a global Age Gate.
- Allow users to quickly capture a "Drink Log" (capturing a reaction — loved/liked/nah, photo, and note). **Unified Logging** supports both catalog bottles and custom drinks (mocktails, cocktails, or any unlisted drink).
- Allow users to write personal "Reviews" for catalog alcohols on a 0-5 scale. Reviews are formally distinct from logs and do not increment log counts.
- Aggregate user logs into a personal "Shelf" that showcases their history and average ratings.
<!-- SYNC_OVERVIEW_END -->

## 🛠️ Tech Stack
<!-- SYNC_TECH_START -->
- **cupertino_icons:** ^1.0.8
- **firebase_core:** ^4.2.1
- **firebase_auth:** ^6.1.3
- **cloud_firestore:** ^6.1.1
- **image_picker:** ^1.2.1
- **firebase_storage:** ^13.0.4
<!-- SYNC_TECH_END -->

## 📱 Application Flow
<!-- SYNC_FLOW_START -->
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
    └── Tab 4: ProfileScreen
        ├── View Variant: Public (Full Activity)
        ├── View Variant: Locked (Private Gated)
        ├── SettingsScreen (via AppBar icon)
        │   └── Logout Action (Clears Nav Stack)
        └── FeedbackOverlay (via Leading Action Icon)
```
<!-- SYNC_FLOW_END -->

## 🏗️ Architecture & Database
<!-- SYNC_ARCH_START -->
DrunkDiary uses a **Serverless (BaaS)** architecture based on Firebase:
- **`users`**
- **`usernames`**
- **`alcohols`**
- **`drink_logs`**
- **`wishlists`**
- **`activity_sessions`**
- **`configs`**
<!-- SYNC_ARCH_END -->

## 🎨 Design System
<!-- SYNC_DESIGN_START -->
*   **High Contrast Dark UI:** The primary implementation centers entirely around a dark theme with a stark black background and high-visibility amber accents.
*   **Timeline-based Activity:** Content is organized chronologically using a two-column timeline layout, removing the previous card-based grouping for a more premium, scannable feed.
*   **Modal-Driven Input:** Complex user interactions (e.g., logging a drink, writing a review, tagging people) are isolated in bottom-sheet modals to preserve context.
*   **Social-Centric Privacy:** Private accounts are discoverable to foster community growth, but their activity remains strictly "Hard-Gated" behind friendship status.
*   **Source-Aware Capture:** All photo-capture actions must provide a choice between **Camera** and **Gallery** via a standardized bottom sheet.
<!-- SYNC_DESIGN_END -->

## 📜 Documentation Governance

This project follows **Documentation Authority Mode**. All structural changes must be reflected in the `Docs/` directory:
- [PRD.md](Docs/PRD.md)
- [APP_FLOW.md](Docs/APP_FLOW.md)
- [TECH_STACK.md](Docs/TECH_STACK.md)
- [FRONTEND_GUIDELINES.md](Docs/FRONTEND_GUIDELINES.md)
- [BACKEND_STRUCTURE.md](Docs/BACKEND_STRUCTURE.md)

---
*This README is automatically synchronized with the source documentation in the `/Docs` directory.*
