# Frontend Design System & Guidelines

Last Updated: 2026-05-03

## 1. Design Principles (Inferred From UI)
*   **High Contrast Dark UI:** The primary implementation centers entirely around a dark theme with a stark black background and high-visibility amber accents.
*   **Timeline-based Activity:** Content is organized chronologically using a two-column timeline layout, removing the previous card-based grouping for a more premium, scannable feed.
*   **Modal-Driven Input:** Complex user interactions (e.g., logging a drink, writing a review, tagging people) are isolated in bottom-sheet modals to preserve context.
*   **Source-Aware Capture:** All photo-capture actions must provide a choice between **Camera** and **Gallery** via a standardized bottom sheet.

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

### Typography
*   **Font Families:**
    - `CategoriesElegant`: Primary branding font (AppBar titles).
    - `DMSans`: Primary UI font for both Heading and Body (via `google_fonts` and `AppTextStyles`).
    - `GiveYouGlory`: Decorative font for greetings.
*   **Font Weights:** Regular (`w400`), `FontWeight.w500`, `FontWeight.w600`, `FontWeight.w700` (bold).

### AppTextStyles (Centralized Type Scale)
Defined in `lib/core/theme/app_text_styles.dart`. All styles use Google Fonts `DM Sans`.
*   `caption`: `12px`, `w400`, grey — Metadata, timestamps
*   `body`: `14px`, `w500` — Default text
*   `title`: `16px`, `w600`, `height: 1.2` — Card titles (alcohol names)
*   `subtitle`: `18px`, `w600` — Smaller section headers
*   `section`: `20px`, `w700` — Section headings ("Taste Identity", "Recent Activity")
*   `appBarTitle`: `22px`, `letterSpacing: 2.0`, `height: 1.0` — Uses `CategoriesElegant` font family

**AppBar Styling:**
- Text: `fontSize: 22`, `letterSpacing: 2.0`, `height: 1.0`, with a `1px` downward optical shift.

### Spacing System (AppSpacing Tokens)
Defined in `lib/core/theme/app_spacing.dart`. All spacing MUST use these tokens to maintain a consistent 8pt grid.
*   `xs`: `4` — Micro spacing
*   `sm`: `8` — Tight spacing
*   `md`: `12` — Compact spacing
*   `lg`: `16` — Default component gap
*   `xl`: `20` — Medium spacing
*   `xxl`: `24` — Large spacing / Page gutter
*   `hero`: `32` — Hero spacing

**Standardized Layout Padding:**
*   `pagePadding`: `EdgeInsets.symmetric(horizontal: lg, vertical: lg)` (16px)
*   `radiusDefault`: `16` (lg)
*   `radiusProduct`: `14` — Specific radius for bottle images and product tiles.
*   `buttonHeight`: `56`

### Border Radius
*   `BorderRadius.circular(12)`: Standard radius for TextFields and Buttons.
*   `BorderRadius.circular(14)`: Premium radius for product/alcohol images.
*   `BorderRadius.circular(16)`: Standard radius for Cards, Timeline stat boxes, and top edges of Bottom Sheets (`Radius.circular(16)`).
*   `BorderRadius.circular(20)`: Specifically used for selected/unselected `ChoiceChip` containers.

### Shadows
No explicit custom shadow scales or elevation configurations identified in the immediate code. Depth is achieved via color contrast (e.g., `Colors.grey.shade900` on a black background).

## 3. Layout System (As Implemented)
*   **Container Wrappers:** The majority of screens utilize a single column layout padded with `EdgeInsets.all(16)` or `EdgeInsets.all(24)`.
*   **Grids:** The `ShelfScreen` utilizes a `GridView` explicitly locked to 3 columns (`crossAxisCount: 3`) with a `childAspectRatio` of `0.7`.
*   **Breakpoints:** No explicit breakpoints are customized. Uses default framework layout behavior.

## 4. Component Inventory (Only Existing Components)

### Buttons
*   **OnboardingButton:** Primary gold sticky CTA with scale animations and "Saving..." loading state.
*   **ElevatedButton:** Standard full-width button (Amber #FFC107).
*   **OutlinedButton:** Used for secondary actions.
*   **Log CTA Button:** Gold Pill shape, Height 38px, Radius 16. Used for "+ Log" primary actions in cards.

### Alcohol/Product Tile (Premium Container)
*   **Dimensions:** 84x84px (in Wishlist/Discovery).
*   **Radius:** 14px.
*   **Surface:** `deepCardBackground` (Color(0xFF0F0F0F)).
*   **Image Alignment:** Centered within the container using `boxFit.contain` to ensure the whole bottle is visible.

### Onboarding Components
Located in `lib/features/auth/widgets/onboarding_components.dart`:
*   **OnboardingProgressBar:** Horizontal segmented bar with animated fill.
*   **OnboardingChoiceCard:** Premium tapped selection card with gold accent glow and haptic feedback.
*   **OnboardingLayout:** Wrapper for Top (Progress), Mid (Content), and Bottom (Sticky CTA) structure.

### Input Fields
*   **TextField:** Implemented uniformly with `filled: true` and an `OutlineInputBorder` set to `borderSide: BorderSide.none` with `borderRadius: BorderRadius.circular(12)`.
*   **ChoiceChip:** Used aggressively for multi-selection onboarding. When selected, the background turns `Colors.amber` with black text. When unselected, it relies on a transparent background with a grey border and white text.

### Cards
*   Implemented primarily using `Container` widgets wrapped with `decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12/16))`.
*   **DayActivityCard** (Diary/Profile → Timeline Layout):
    *   **Timeline Structure**: A two-column grid.
        *   **Left Column (56px)**: Date anchor (Large day number, Small-caps month abbreviation).
        *   **Right Column**: Content stream (Identity, Activity, Summary).
    *   **Horizontal Log Scroll**: `SizedBox(height: 120)` + `ListView.separated(Axis.horizontal)` of `LogMiniCard` widgets.
    *   **Edge-to-Edge Bleed**: The scroll area is unconstrained, allowing media to scroll across the entire screen width while maintaining grid alignment.
    *   **Footer**: "X LOGS" label + Interaction buttons (More, Share).
    *   **Spacing**: 24px vertical padding between day groups (`xxl`).
    *   **Separation**: Hairline `Divider` (thickness: 1.0, height: 8.0) after each day group.
*   **LogMiniCard** (used inside DayActivityCard scroll row):
    *   **Dimensions**: `width: 170`, `height: 120`.
    *   **Background**: `deepCardBackground` (#0F0F0F), `radius: radiusProduct` (14px), `borderDark` border.
    *   **Top Badge**: Reaction icon (log) OR `⭐ + numeric rating` (review) in top-left.
    *   **Center**: `alcoholName` bold, max 2 lines, `TextOverflow.ellipsis`.
    *   **Subtext**: `⭐ X.X` (review) OR reaction label string (log) in `textMuted`.
    *   **Bottom**: Formatted time string (e.g. `3:24 PM`) in muted caption.
    *   **Tap**: Opens `LogDetailBottomSheet`.
*   **Interaction Placeholders**:
    *   **Username**: Prefixed with `@` (e.g., `@sharmakhil`).
    *   **More Menu**: `Icons.more_horiz` in the top-right header.
    *   **Share Button**: `Icons.ios_share` in the bottom-right footer.
    *   **Feedback**: All buttons trigger a "Coming Soon" SnackBar.

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

*   **Centered Action Icon:** The central navigation item (Index 2) is a specialized circular action button (`+`) that opens the `UnifiedLoggingScreen` as a fullscreen dialog.

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
*   **Image Handling:**
    - Use `cached_network_image` for all network images.
    - **Memory Optimization**: Always specify `memCacheWidth` (and/or `memCacheHeight`) in `CachedNetworkImage`. This prevents high-resolution images from being decoded at full size into RAM, which is the #1 cause of scrolling jank.
*   **List Scrolling**:
    - Avoid `IntrinsicHeight` inside large lists/grids. Use fixed heights or `SliverLayoutBuilder` if dynamic height is required but must be performant.
    - **Riverpod Caching**: Use the `alcoholCacheProvider` to avoid redundant Firestore `.get()` calls during scroll frames.
*   **Rebuild Optimization**:
    - Use `const` constructors where possible.
    - Prefer `ConsumerWidget` for leaf nodes that depend on state to minimize parent rebuilds.

## 9. Browser Support
*   Targeting mobile platforms primarily. Web support is experimental.
