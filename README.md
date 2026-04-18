# 🍻 DrunkDiary

DrunkDiary is a Flutter-based mobile application that allows legal-age users to log or review the alcoholic beverages they consume for personal tracking. It acts as a digital diary and tracking shelf for your drinking journey.

## 🚀 Overview
<!-- SYNC_OVERVIEW_START -->
- Authenticate users securely into the ecosystem and enforce a strict age gate (18+).
- Allow users to quickly capture a "Drink Log" (capturing a reaction — loved/liked/nah, photo, tags, and context). These are the only entries counted as "Personal Logs".
- Allow users to write personal "Reviews" for alcohols on a 0-5 scale. Reviews are formally distinct from logs and do not increment log counts.
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
        ├── SettingsDrawer (Sidebar)
        │   ├── AdminBottleManagerScreen (via Admin Bottle Manager Tile)
        │   └── Logout Action
        └── FeedbackOverlay (via Feedback Icon)
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
- **`configs`**
<!-- SYNC_ARCH_END -->

## 🎨 Design System
<!-- SYNC_DESIGN_START -->
*   **High Contrast Dark UI:** The primary implementation centers entirely around a dark theme with a stark black background and high-visibility amber accents.
*   **Card-based Grouping:** Content (logs, shelf items, stats) is primarily grouped and elevated visually using distinct dark-grey surface containers.
*   **Modal-Driven Input:** Complex user interactions (e.g., logging a drink, writing a review, tagging people) are isolated in bottom-sheet modals to preserve context.
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
