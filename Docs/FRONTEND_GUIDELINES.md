# Frontend Design System & Guidelines

Last Updated: 2026-04-03

## 1. Design Principles (Inferred From UI)
*   **High Contrast Dark UI:** The primary implementation centers entirely around a dark theme with a stark black background and high-visibility amber accents.
*   **Card-based Grouping:** Content (logs, shelf items, stats) is primarily grouped and elevated visually using distinct dark-grey surface containers.
*   **Modal-Driven Input:** Complex user interactions (e.g., logging a drink, writing a review, tagging people) are isolated in bottom-sheet modals to preserve context.

## 2. Design Tokens (Extracted, Not Generated)

### Color Palette
Extracted from `app_theme.dart` and inline widget styling:
*   `--color-primary`: `#FFC107` (Used for active chips and primary accents)
*   `--color-background`: `#0F0F0F` (Used for Scaffolds)
*   `--color-surface`: `#1A1A1A` (Used for Cards, TextFields, and Stats containers)
*   `--color-text-primary`: `#FFFFFF`
*   `--color-text-secondary`: `#B0B0B0` (Used for muted/secondary text)
*   `--color-success`: `Colors.green` (Used for positive username validation)
*   `--color-error`: `Colors.red` (Used for error text)

### Reaction Colors (DrinkReaction)
Defined in `lib/core/constants/reaction_config.dart` → `ReactionConfig.getColor()`:
*   `loved`: `Color(0xFFFFC107)` — Gold/Amber (heart icon)
*   `liked`: `Colors.white70` — Neutral white (thumbs up icon)
*   `nah`: `Color(0xFFE53935)` — Vibrant Red (broken heart icon)

### AppCustomColors (ThemeExtension)
Defined in `lib/app/app_theme.dart` as `ThemeExtension<AppCustomColors>`. Access via `Theme.of(context).extension<AppCustomColors>()!`.
*   `cardBackground`: `Color(0xFF1A1A1A)` — Standard card/container fill
*   `deepCardBackground`: `Color(0xFF0F0F0F)` — Deeper nested surfaces
*   `borderLight`: `Color(0xFFFFC107).withValues(alpha: 0.3)` — Amber accent borders
*   `borderDark`: `Color(0xFF333333)` — Subtle dark borders
*   `textMuted`: `Color(0xFFB0B0B0)` — Secondary/muted text
*   `success`: `Colors.green`
*   `error`: `Colors.red`
*   `warning`: `Color(0xFFFFC107)`

### Design Tokens
*   `APP_BAR_VISUAL_HEIGHT`: `28` (Source of truth for branding assets in AppBar)

### Typography
*   **Font Families:**
    - `CategoriesElegant`: Primary branding font (AppBar titles).
    - `Inter`: Primary body font (via `google_fonts` and `AppTextStyles`).
    - `DMSans`: Secondary UI font.
    - `GiveYouGlory`: Decorative font for greetings.
*   **Font Weights:** Regular (`w400`), `FontWeight.w500`, `FontWeight.w600`, `FontWeight.w700` (bold).

### AppTextStyles (Centralized Type Scale)
Defined in `lib/core/theme/app_text_styles.dart`. All styles use Google Fonts `Inter` unless noted.
*   `caption`: `12px`, `w400`, grey — Metadata, timestamps
*   `body`: `14px`, `w500` — Default text
*   `title`: `16px`, `w600`, `height: 1.2` — Card titles (alcohol names)
*   `subtitle`: `18px`, `w600` — Smaller section headers
*   `section`: `20px`, `w700` — Section headings ("Taste Identity", "Recent Activity")
*   `appBarTitle`: `22px`, `letterSpacing: 2.0`, `height: 1.0` — Uses `CategoriesElegant` font family

*   **AppBar Styling:**
    - Text: `fontSize: 22`, `letterSpacing: 2.0`, `height: 1.0`, with a `1px` downward optical shift.

### Spacing System
Spacing relies heavily on `EdgeInsets` and `SizedBox` implementations without a strict centralized scale token system.
*   **Padding/Margin Values found:** `8`, `12`, `14`, `16`, `24`, `32`.
*   **Gap/SizedBox Values found:** `4`, `6`, `8`, `12`, `16`, `20`, `24`, `32`.

### Border Radius
*   `BorderRadius.circular(12)`: Standard radius for Cards, TextFields, Buttons, and images.
*   `BorderRadius.circular(16)`: Standard radius for Timeline stat boxes and top edges of Bottom Sheets (`Radius.circular(16)`).
*   `BorderRadius.circular(20)`: Specifically used for selected/unselected `ChoiceChip` containers.

### Shadows
No explicit custom shadow scales or elevation configurations identified in the immediate code. Depth is achieved via color contrast (e.g., `Colors.grey.shade900` on a black background).

## 3. Layout System (As Implemented)
*   **Container Wrappers:** The majority of screens utilize a single column layout padded with `EdgeInsets.all(16)` or `EdgeInsets.all(24)`.
*   **Grids:** The `ShelfScreen` utilizes a `GridView` explicitly locked to 3 columns (`crossAxisCount: 3`) with a `childAspectRatio` of `0.7`.
*   **Breakpoints:** No explicit breakpoints are customized. Uses default framework layout behavior.

## 4. Component Inventory (Only Existing Components)

### Buttons
*   **ElevatedButton:** Often forced to `width: double.infinity` for full-width submit actions. On the Login screen, specifically hardcoded to `height: 50` with a `Colors.white` background and black text.
    *   *States:* Disabled (when `isLoading`, passes `null` to `onPressed`), Loading (displays `CircularProgressIndicator` instead of child widget).
*   **OutlinedButton:** Used for secondary actions (e.g., Like/Dislike).
*   **TextButton:** Used sparsely (e.g., "Add a note" toggle).

### Input Fields
*   **TextField:** Implemented uniformly with `filled: true` and an `OutlineInputBorder` set to `borderSide: BorderSide.none` with `borderRadius: BorderRadius.circular(12)`.
*   **ChoiceChip:** Used aggressively for multi-selection onboarding. When selected, the background turns `Colors.amber` with black text. When unselected, it relies on a transparent background with a grey border and white text.

### Cards
*   Implemented primarily using `Container` widgets wrapped with `decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12/16))`.
*   **Card Differentiation (Logs vs Reviews):** 
    *   Log Cards: Subtle grey border or flatter background (`Colors.grey.shade900`). Focus on icon indicator (thumbs up/down).
    *   Review Cards: Slightly elevated or distinct subtle accent (e.g. faint amber border/gradient or different shade of grey `Colors.grey.shade800`) to highlight a formal rating constraint.

### App Bar
*   **CustomAppBar:** All secondary screens utilize the `CustomAppBar` component which implements the project's branding standards:
    - **Branding:** Diary Screen uses `drunk_diary_logo.svg` (scaled to `APP_BAR_VISUAL_HEIGHT`).
    - **Header Formatting:** Other screens use ALL CAPS titles with a `Transform.translate(offset: Offset(0, 1))` shift for precise optical vertical centering.
    - **Branding Consistency:** Uses `CategoriesElegant` font for titles by default.
*   **BottomNavigationBar:** Fixed type (`BottomNavigationBarType.fixed`) containing exactly 5 tabs.
*   **Settings Drawer (Sidebar)**
    - **Description:** A right-aligned `Drawer` accessible from the Profile screen.
    - **Visuals:** Uses `--color-surface` and standard `ListTile` components. Maintains the project's dark theme and amber accents.
    - **Items:**
      - Header with Avatar + Username.
      - "Admin Settings" (list tile, conditional if user is admin).
      - "Logout" (list tile with `Icons.logout`).
    - **Interaction:** Opens when the user taps the settings icon in the Profile AppBar.

*   **Centered Action Icon:** The central navigation item (Index 2) is specifically highlighted as a circular action button with a golden glow/shadow and amber opacity background to denote it as the "Core Discovery Action."

### State Indicators
*   **Loading Spinner:** Relies on default `CircularProgressIndicator()`. Embedded inside buttons during async actions, sometimes passing `strokeWidth: 2`.
*   **Empty States:** A standardized `AppEmptyState` component used across all primary screens.
    *   **Visual Structure:** Centered Column with a circular icon container (low-opacity amber background), a headline (`fontSize: 20`, bold), a descriptive subtext (`fontSize: 14`, grey), and an optional primary action button (amber).
    *   **Icons:** 
        *   Wishlist: `Icons.bookmark_border`
        *   Shelf: `Icons.inventory_2_outlined`
        *   Diary: `Icons.history_edu_outlined`
        *   Search: `Icons.search_off_outlined`
*   **Error States:** Raw text messages rendered conditionally in UI trees (e.g., `Text(_error!, style: const TextStyle(color: Colors.red))`).

### Skeleton UI (Shimmer)
Used to represent loading states for content blocks.
*   **Colors:** baseColor: `Colors.grey[850]`, highlightColor: `Colors.grey[800]`.
*   **Implementation:** Replaces generic `CircularProgressIndicator` in list/grid views to keep layouts stable while filling data.

## 5. Accessibility (Only If Implemented)
No explicit accessibility enhancements identified beyond default Flutter semantics and Material framework behavior.

## 6. Animation & Transitions (If Present)
*   **`FadeSlidePageRoute`** (`lib/core/navigation/page_transitions.dart`): Custom `PageRouteBuilder` combining fade + subtle upward slide (`Offset(0, 0.05)` → `Offset.zero`, 300ms, `Curves.easeOut`).
*   **Hero Animations**: Uses **context-aware prefixes** to prevent tag collisions in the `IndexedStack` (where all tabs are active simultaneously):
    *   `search_alcohol_[ID]` (Discover tab)
    - `shelf_alcohol_[ID]` (Shelf tab)
    - `stats_alcohol_[ID]` (Stats screen)
    - `alcohol_log_[LOG_ID]` (Diary entry)
*   **BetterFeedback UI**:
    - Uses a custom dark theme (`Color(0xFF121212)`) and sheet color (`Color(0xFF1E1E1E)`).
    - Triggered from Profile Screen's leading action button.
    - Provides a full-screen screenshot annotation and text entry interface.
*   Modal bottom sheets use default Flutter slide-up transitions.

### Light Theme
A complete `lightTheme` and `lightCustomColors` definition exists in `app_theme.dart` (lines 131-190). It is **not currently applied** — `main.dart` only uses `darkTheme`. Available for future use.

## 7. Responsive Behavior (If Visible)
No explicit responsive differentiation implemented beyond default framework behavior. Viewports scale linearly.

## 8. Performance Guidelines
*   **Image Handling:** The repository imports `cached_network_image` in `pubspec.yaml`, though some screens still use fundamental `Image.network` loading.
*   No explicit frontend performance optimizations beyond native Flutter tree rendering identifiable.

## 9. Browser Support
Browser support policy not explicitly documented (Primary deployment architecture targets native mobile compilation).
