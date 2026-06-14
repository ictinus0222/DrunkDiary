# Frontend Design System & Guidelines

> [!IMPORTANT]
> This document should be used in tandem with the primary **[Design System Document](file:///c:/Users/akhil/StudioProjects/drunk_diary/Docs/DESIGN_SYSTEM.md)**, which acts as the ultimate authority and source of truth for colors, typography, layout rules, spacing, and component definitions. Always consult it before modifying or adding frontend code.

Last Updated: 2026-05-29

## 1. Design Principles (Inferred From UI)
*   **High Contrast Dark UI:** The primary implementation centers entirely around a dark theme with a stark black background and high-visibility amber accents.
*   **Timeline-based Activity:** Content is organized chronologically using a two-column timeline layout, removing the previous card-based grouping for a more premium, scannable feed.
*   **Modal-Driven Input:** Complex user interactions (e.g., logging a drink, writing a review, tagging people) are isolated in bottom-sheet modals to preserve context.
*   **Social-Centric Privacy:** Private accounts are discoverable to foster community growth, but their activity remains strictly "Hard-Gated" behind friendship status.
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
    - `DMSans`: Primary UI font for both Heading and Body (via local font assets and AppTextStyles).
    - `GiveYouGlory`: Decorative font for greetings.
*   **Font Weights:** Regular (`w400`), `FontWeight.w500`, `FontWeight.w600`, `FontWeight.w700` (bold).

### Haptic Feedback
*   `HapticFeedback.lightImpact()`: Used for subtle interaction confirmation (e.g., Cheers toggle).

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

## 4. Component Inventory (Only Existing Components)

### Buttons
*   **OnboardingButton:** Primary gold sticky CTA with scale animations and "Saving..." loading state.
*   **ElevatedButton:** Standard full-width button (Amber #FFC107).
*   **OutlinedButton:** Used for secondary actions.
*   **NotificationBadgeButton**:
    - **Visual**: 🔔 icon with a circular red/amber badge if unread count > 0.
    - **Location**: Top-right of `DiaryScreen` AppBar.
    - **Animation**: Badge appears with a subtle scale-in transition.
*   **Log CTA Button**: Gold Pill shape, Height 38px, Radius 16. Used for "+ Log" primary actions in cards.
*   **CheersButton**: 
    - **Visual**: 🥂 icon + count.
    - **Interaction**: Scale-pop animation on tap.
    - **Logic**: Optimistic UI updates count immediately.
*   **UserSearchTile**:
    - **Visual**: Leading avatar, title (Display Name), subtext (@username).
    - **Indicator**: Privacy lock icon if `isPrivate` is true.
    - **Action**: Navigates to `ProfileScreen`.

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
    *   **Cheers Footer**: Interactive 🥂 button + count label. If the session contains private logs, this is replaced by a `Text('PRIVATE')` badge.
    *   **Feedback**: Accessible via the `BetaTesterDisclaimer` sticky footer on any core screen.

### App Bar
*   **CustomAppBar:** All secondary screens utilize the `CustomAppBar` component which implements the project's branding standards:
    - **Branding:** Diary Screen uses `drunk_diary_logo.svg` (scaled to `APP_BAR_VISUAL_HEIGHT`).
    - **Header Formatting:** Other screens use ALL CAPS titles with a `Transform.translate(offset: Offset(0, 1))` shift for precise optical vertical centering.
    - **Branding Consistency:** Uses `CategoriesElegant` font for titles by default.
*   **BottomNavigationBar:** Fixed type (`BottomNavigationBarType.fixed`) containing exactly 5 tabs.
*   **Settings Screen**
    - **Visuals**: Uses `--color-surface` and standard `ListTile` components. Maintains the project's dark theme and amber accents.
    - **Items**:
      - Profile Privacy Toggle.
      - Friend Requests.
      - Admin Settings (conditional).
      - Logout & Account Deletion.
    - **Interaction**: Opens via the settings icon in the Profile AppBar.

*   **Centered Action Icon:** The central navigation item (Index 2) is a specialized circular action button (`+`) that opens the `UnifiedLoggingScreen` as a fullscreen dialog.

*   **LockedProfileView**:
    - **Visual**: Used when a private profile is viewed by a non-friend.
    - **Structure**: Blurred activity placeholders + large central Lock icon + "Private Account" message + "Add Friend" primary CTA.
*   **Loading Spinner:** Relies on default `CircularProgressIndicator()`. Embedded inside buttons during async actions, sometimes passing `strokeWidth: 2`.
*   **Empty States:** A standardized `AppEmptyState` component used across all primary screens.
    *   **Visual Structure:** Centered Column with a circular icon container (low-opacity amber background), a headline (`fontSize: 20`, bold), a descriptive subtext (`fontSize: 14`, grey), and an optional primary action button (amber).
    *   **Icons:** 
        *   Wishlist: `Icons.bookmark_border`
        *   Shelf: `Icons.inventory_2_outlined`
        *   Diary: `Icons.history_edu_outlined`
        *   Search: `Icons.search_off_outlined`
*   **Error States:** Raw text messages rendered conditionally in UI trees (e.g., `Text(_error!, style: const TextStyle(color: Colors.red))`).

### Beta Tester Feedback (Premium UI)
*   **BetaTesterDisclaimer**: 
    - **Visual**: Collapsible `ExpansionTile` at the bottom of core screens.
    - **Branding**: Amber "BETA PREVIEW" label with compact density.
    - **Behavior**: Hides itself automatically during screenshot capture.
*   **FeedbackBottomSheet**:
    - **Dimensions**: Slim/Compact vertical layout.
    - **Layout**: Side-by-side buttons for Submission and Screenshot preview.
    - **Overlay**: Opaque loading/success screens (`#1A1A1A`) to provide clear state transitions.

### Skeleton UI (Shimmer)
Used to represent loading states for content blocks.
*   **Colors:** baseColor: `Colors.grey[850]`, highlightColor: `Colors.grey[800]`.
*   **Implementation:** Replaces generic `CircularProgressIndicator` in list/grid views to keep layouts stable while filling data.

## 5. Accessibility (Only If Implemented)
No explicit accessibility enhancements identified beyond default Flutter semantics and Material framework behavior.

## 6. Animation & Transitions (If Present)
*   **`FadeSlidePageRoute`** (`lib/core/navigation/page_transitions.dart`): Custom `PageRouteBuilder` combining fade + subtle upward slide (`Offset(0, 0.05)` → `Offset.zero`, 300ms, `Curves.easeOut`).
*   **Hero Animations**: Uses **context-aware prefixes** to prevent tag collisions in the `IndexedStack` (where all tabs are active simultaneously):
    - `search_alcohol_[ID]` (Discover tab)
    - `shelf_alcohol_[ID]` (Shelf tab)
    - `alcohol_log_[LOG_ID]` (Diary entry)
*   **Custom Feedback UI**:
    - Uses a solid surface color (`#1A1A1A`) for submission overlays.
    - Integrated directly into the app's amber/black theme.
    - Automated "Thank You" success sequence with a 2-second auto-close.
*   Modal bottom sheets use default Flutter slide-up transitions.

### Immersive Viewers
For media-first content consumption (e.g., Activity Detail Viewer):
- **Background**: Pitch black (`#000000`).
- **Media**: Edge-to-edge rendering, `InteractiveViewer` for zoom/pan.
- **Overlays**: Floating translucent controls (`Colors.black54` with blur).
- **Navigation**: Cinematic fade/scale transitions, back button always accessible top-left.

### Light Theme
A complete `lightTheme` and `lightCustomColors` definition exists in `app_theme.dart` (lines 131-190). It is **not currently applied** — `main.dart` only uses `darkTheme`. Available for future use.

## 9. Responsive Platform Architecture

DrunkDiary uses a **Platform-First Layout System** that ensures a premium, readable experience across mobile, tablet, and desktop.

### 🏛️ Governance Layer
- **`ResponsiveScaffoldBody`**: The mandatory root wrapper for all primary screen bodies. It automatically applies horizontal constraints and centering.
- **`ResponsiveConstrainedBox`**: A box-based utility for enforcing max-widths on standard widgets.
- **`SliverResponsiveConstrainedBox`**: A sliver-based utility for enforcing max-widths on items inside `CustomScrollView` (e.g., `SliverGrid`).

### 📐 Semantic Width Tokens
Defined in `lib/core/theme/responsive_tokens.dart`:
- `AppWidths.feed` (600px): Optimized for single-column scrolling content (Diary, Timeline).
- `AppWidths.grid` (1200px): Optimized for multi-column discovery grids (Search, Shelf).
- `AppWidths.form` (500px): Optimized for input-heavy screens (Logging, Onboarding).
- `AppWidths.profile` (800px): Optimized for identity-centric layouts.

### 📱 Breakpoints & Adaptive Logic
Accessed via `ResponsiveContext` extensions on `BuildContext`:
- `context.isTablet`: `width >= 600`.
- `context.isDesktop`: `width >= 1200`.
- `context.responsiveValue<T>(mobile: ..., tablet: ..., desktop: ...)`: Declarative platform-specific values.
- `context.pagePadding`: Adaptive gutter that scales based on device width.

### 🌊 Layout Density
The system supports three density levels: `compact`, `comfortable`, and `expanded`.
- Affects vertical spacing, typography sizing, and avatar scale.
- Density is automatically inferred from screen width but can be overridden.

### 🎞️ Sliver Compatibility
Always use `SliverResponsiveConstrainedBox` when wrapping slivers inside a `CustomScrollView`. Avoid using `ResponsiveConstrainedBox` (Box-based) inside a sliver list to prevent `RenderSliver` expectation errors.

## 10. Performance Guidelines
*   **Image Handling:**
    - Use `cached_network_image` for all network images.
    - **Memory Optimization**: Always specify `memCacheWidth` (and/or `memCacheHeight`) in `CachedNetworkImage`. This prevents high-resolution images from being decoded at full size into RAM, which is the #1 cause of scrolling jank.
*   **List Scrolling**:
    - Avoid `IntrinsicHeight` inside large lists/grids. Use fixed heights or `SliverLayoutBuilder` if dynamic height is required but must be performant.
    - **Riverpod Caching**: Use the `alcoholCacheProvider` to avoid redundant Firestore `.get()` calls during scroll frames.
*   **Rebuild Optimization**:
    - Use `const` constructors where possible.
    - Prefer `ConsumerWidget` for leaf nodes that depend on state to minimize parent rebuilds.
*   **Search Performance**:
    - Use `StreamProvider` for real-time query handling.
    - Implement a **300ms debounce** to prevent Firestore burst-billing during rapid typing.
    - Partition "People" and "Bottles" searches into parallel `FutureProviders` for maximum responsiveness.

## 9. Browser Support
*   Targeting mobile platforms primarily. Web support is experimental.
