# DrunkDiary Design System Audit & Specification

Welcome to the official **DrunkDiary Design System (v1.0)**. This document serves as the single source of truth for the product's visual language, component library, motion standards, and token configurations. 

This design system has been reverse-engineered directly from the live Flutter codebase, database models, and design documentation, standardizing all UI elements to eliminate visual inconsistencies and guide future development.

---

## 1. Brand Foundation

DrunkDiary is a highly focused personal tracking utility and social journal. It exists to capture the micro-moments and memories associated with social outings and tastings. 

### Product Personality
*   **Emotional Resonance:** Nostalgic, celebratory, and reflective. The application positions itself as a preservation utility ("*Memories fade. Your best nights don’t have to.*").
*   **Interface Tone:** Premium, nocturnal, high-contrast, and intimate. It utilizes deep blacks and glowing amber tones to replicate the atmosphere of lounge bars, house parties, and late-night socials.
*   **Brand Archetype:** **The Explorer & The Creator.** The product facilitates exploration (discovering new beers, spirits, wines, and cocktails) and personal expression (authoring custom drink logs, custom ratings, and private reviews).
*   **User Feelings reinforced:** Self-reflection, social connection (cheering friends' logs), and personal appreciation (building a beautifully organized, physical-feeling "Shelf" of tried drinks).

---

## 2. Design Principles

These five core principles govern every design decision, layout scale, and interaction model in DrunkDiary:

1.  **Clarity & Immersive Focus (Content Over Chrome)**
    *   *Description:* The interface elements should dissolve into the background. Media (drink photos) and user inputs are primary. 
    *   *Why it matters:* A dark UI can easily feel cluttered. Pitch-black backgrounds (`#000000`) are used in media viewers, and containers are kept strictly flat.
    *   *Impact on future decisions:* Decorative borders, drop-shadows, and heavy gradients are prohibited unless highlighting active user selections.
2.  **Low-Friction Moment Capture**
    *   *Description:* Logging a drink must be achievable in under five seconds, even in high-stimulation environments (like loud clubs or parties).
    *   *Why it matters:* High capture friction kills logging consistency.
    *   *Impact on future decisions:* Logging uses bottom sheets with pre-configured emoji reactions (Loved, Liked, Nah) and camera defaults rather than dense text forms.
3.  **Structured Chronology (Timeline-First Feed)**
    *   *Description:* Logs are grouped chronologically by calendar day. A date anchor on the left dictates a clean vertical content stream on the right.
    *   *Why it matters:* Provides a structural timeline that feels like a real journal.
    *   *Impact on future decisions:* Avoid grid-based card lists for primary feeds. Maintain the two-column timeline layout with clear daily separators.
4.  **Responsible Gated Social Privacy**
    *   *Description:* Social discovery is encouraged, but personal logs and shelfs are strictly locked behind mutual friendship status.
    *   *Why it matters:* Tracking alcohol consumption is highly personal; users must feel safe to log honestly.
    *   *Impact on future decisions:* Any screen showing detailed user stats, reviews, or log images must check friendship status and render a blurred/locked state for non-friends.
5.  **Adaptive Density Scaling**
    *   *Description:* The UI layout automatically transitions between layout densities (Compact, Comfortable, Expanded) based on screen width.
    *   *Why it matters:* Prevents layouts from feeling "blown out" on tablet or compressed on smaller phones.
    *   *Impact on future decisions:* All spacing, padding, and text sizing must draw from dynamic context-based utility properties rather than raw static pixels.

---

## 3. Visual Identity System

### Color System

#### Brand Colors
*   **Primary Accent:** `#FFC107` (Amber) — Used for active selection states, primary buttons, rating stars, and brand highlights.
*   **Secondary Gold:** `#FFAB00` (Amber Gold) — Used for premium sub-headers and highlight cards.
*   **Default Background:** `#0F0F0F` (Dark Pitch) — Standard scaffold base.
*   **Surface Base:** `#1A1A1A` (Card Grey) — Standard card and container fills.

#### Semantic Colors
*   **Success:** `Colors.green` (`#4CAF50` / `#2E7D32` light) — Used for username validation and success screens.
*   **Error:** `Colors.red` (`#F44336` / `#C62828` light) — Used for validation errors, delete dialog highlights.
*   **Warning:** `#FFC107` (Amber) — Alerts and disclaimer badges.

#### Neutral Scale

| Token | HEX Code | Intended App Usage |
| :--- | :--- | :--- |
| **Gray 50** | `#FFFFFF` | Primary text and icons in dark mode. |
| **Gray 100** | `#F5F5F5` | Off-white accents, sub-headings. |
| **Gray 200** | `#E0E0E0` | Standard inputs, borders on light backgrounds. |
| **Gray 300** | `#B0B0B0` | Muted/Secondary text (`textMuted`), captions, icons. |
| **Gray 400** | `#888888` | Inline separators, disabled state labels. |
| **Gray 500** | `#666666` | Bottom navigation bar inactive labels. |
| **Gray 600** | `#444444` | Divider lines and slider tracks. |
| **Gray 700** | `#333333` | Component outline borders (`borderDark`). |
| **Gray 800** | `#1A1A1A` | Secondary surfaces, card backgrounds (`cardBackground`). |
| **Gray 900** | `#0F0F0F` | Page scaffolds, deeper backgrounds (`deepCardBackground`). |

---

### Dark Mode Strategy
DrunkDiary is a **dark-mode first** application. The visual hierarchy relies entirely on surface-to-background contrast and subtle colored borders:
*   **Backgrounds:** Absolute Scaffold background is locked to `#0F0F0F`. Full-screen media viewing uses `#000000`.
*   **Surfaces:** Primary containers and text fields sit at `#1A1A1A`. 
*   **Elevated Surfaces:** Dropdowns, dialogs, and secondary inputs stack on `#1A1A1A` with subtle amber outlines (`#FFC107` at 30% opacity) or dark gray outlines (`#333333`).
*   **Text Hierarchy:**
    *   Primary: White (`#FFFFFF`, 100% opacity) — Headings, names, input text.
    *   Secondary: Muted Gray (`#B0B0B0`, 80% opacity) — Descriptions, drink sub-types, timestamps.
    *   Captions: Gray (`#B0B0B0`, 60% opacity) — Secondary details, labels.
*   **Accessibility:** To ensure a minimum of WCAG AA compliance, text overlays on amber or green backgrounds must use high-contrast black (`#000000`) text.

---

## 4. Typography System

The typography scale utilizes **DM Sans** as its primary visual carrier for modern, geometric legibility, paired with **CategoriesElegant** for decorative logo branding.

### Font Families
*   **Display (Branding):** `CategoriesElegant` (Special branding font for AppBar titles).
*   **Heading:** `DM Sans` (Google Fonts).
*   **Body:** `DM Sans` (Google Fonts).
*   **Greeting / Decorative:** `GiveYouGlory` (Script font for personalized greetings).

### Type Scale

| Style / Role | Font Size | Font Weight | Line Height | Letter Spacing | Color (Default Dark) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **AppBar Title** | `22px` | Bold / w700 | `1.0` | `2.0px` | White (`#FFFFFF`) |
| **Section Header** | `20px` | Bold / w700 | `1.3` | `-0.2px` | White (`#FFFFFF`) |
| **Subtitle** | `18px` | Semi-Bold / w600 | `1.3` | `0.0px` | White (`#FFFFFF`) |
| **Card Title** | `16px` | Semi-Bold / w600 | `1.2` | `0.1px` | White (`#FFFFFF`) |
| **Body (Default)** | `14px` | Medium / w500 | `1.4` | `0.0px` | White (`#FFFFFF`) |
| **Body Muted** | `14px` | Regular / w400 | `1.4` | `0.0px` | Gray (`#B0B0B0`) |
| **Caption / Metadata** | `12px` | Regular / w400 | `1.2` | `0.2px` | Gray (`#B0B0B0`) |
| **Section Label** | `12px` | Bold / w700 | `1.0` | `1.5px` | Amber (`#FFC107`) |
| **Activity Metadata** | `12px` | Medium / w500 | `1.0` | `0.5px` | White54 (`#FFFFFF` 54% opacity) |

---

## 5. Spacing System

DrunkDiary enforces a strict **8-point grid** spacing system. Spacing should never use arbitrary numbers.

### Spacing Scale
*   `xs` (Extra Small): **4px** — Micro-paddings, spacing between icons and text labels.
*   `sm` (Small): **8px** — Tight spacing, margins between subtext and titles.
*   `md` (Medium): **12px** — Compact layout padding, textfield internal vertical padding.
*   `lg` (Large): **16px** — Default component padding, page margins, gaps between standard inputs.
*   `xl` (Extra Large): **20px** — Inner card margins, layout separations.
*   `xxl` (Double Extra Large): **24px** — Page gutters, vertical separation between day timeline sections.
*   `hero` (Hero Spacing): **32px** — Section breaks, onboarding page layout blocks.

### Layout Guidelines
*   **Vertical Rhythm:** Separation between primary vertical layout elements is kept at `16px` (Default) or `24px` (Major Section breaks).
*   **Margins:** Standard screen horizontal margin is `16px` (`lg`).
*   **Card Radius:** Default card corner radius is locked to `16px`. Bottle product tiles are set to `14px` (`radiusProduct`).

---

## 6. Layout System

The app utilizes a **Platform-First Layout System** that ensures a high-quality experience across multiple screen types (Phones, Foldables, Tablets, and Desktop).

### Breakpoints & Adaptive Logic
*   **Mobile:** Width `< 600px`
*   **Tablet:** Width `600px` to `1024px`
*   **Desktop:** Width `> 1024px`

```
  Width: 0px ------------------ [600px] ------------------ [1024px] ------------------ Infinity
  Density:      Expanded                 Comfortable                 Compact
  Layout:        Mobile                    Tablet                    Desktop
```

### Layout Width Constraints
To prevent interfaces from feeling stretched on larger displays, the system applies maximum width limits based on the content context:
*   **Feed Content (Diary Timeline):** Max Width = `720px` (centered).
*   **Forms & Input Screens:** Max Width = `580px` (centered).
*   **Profiles:** Max Width = `850px` (centered).
*   **Grids (Shelf / Search):** Max Width = `1200px` (centered).
*   **Modals:** Max Width = `500px`.
*   **Bottom Sheets:** Max Width = `640px`.
*   **Dialogs:** Max Width = `480px`.

### Safe Areas & App Bar
*   All content feeds must wrap in a `SafeArea` with top-padding of `16px`.
*   AppBar heights are standardized to `64px` to accommodate branding and notification badges.

---

## 7. Component Inventory

Below is the verified inventory of all UI components currently implemented in DrunkDiary.

### Buttons

#### 1. OnboardingButton
*   **Purpose:** Primary call-to-action button placed at the base of onboarding steps.
*   **Variants:** Full-width, elevated.
*   **States:** Standard (Active), Hover/Focus, Loading ("Saving..." state with an inline progress indicator), Disabled.
*   **Accessibility:** Contrast compliant. Touch target is 56px height.

#### 2. ElevatedButton
*   **Purpose:** Standard primary screen actions (e.g., Submit log, Send ticket).
*   **Variants:** Solid Amber fill with Black text. Height: 56px. Border Radius: 16px.
*   **States:** Default, Tap/Pressed, Disabled.
*   **Guidelines:** Use `ElevatedButton.styleFrom` with `appBarSize` styles.

#### 3. OutlinedButton
*   **Purpose:** Secondary actions (e.g., Cancel, Go Back, Edit).
*   **Variants:** Transparent background with Gray (`#333333`) border.
*   **States:** Default, Tap/Pressed.

#### 4. CheersButton
*   **Purpose:** Session-based social reaction button (🥂 Cheers icon + Count).
*   **Variants:** Default inline text button (Diary feed) vs. Pill-bordered container (Immersive viewer).
*   **States:** Uncheered (Muted white, translucent text), Cheered (Vibrant amber background and text).
*   **Interactions:** Triggers light impact haptic feedback and a scale-pop animation on tap.

#### 5. Log CTA Button
*   **Purpose:** Quick action button to log a specific bottle directly.
*   **Variants:** Pill shape, Height: 38px, Radius: 16px. Color: Gold/Amber (`#FFC107`). Text: "+ Log".
*   **States:** Default.

---

### Text Fields & Search Bars

#### 1. Standard Input Field
*   **Purpose:** Capture user text data (e.g., Note, Brand, ABV).
*   **Variants:** `filled: true`, background `#1A1A1A` (Dark), `borderRadius: 16`.
*   **States:**
    *   *Enabled:* Border outline `#333333`.
    *   *Focused:* Border outline `#FFC107` (1.5px thick).
    *   *Error:* Border outline Colors.red.
*   **Guidelines:** Always display hints in a muted gray with 30% opacity.

#### 2. Search Bar
*   **Purpose:** Unified Search hub input (Bottles + People).
*   **Variants:** Standard full-width search input with prefix `Icons.search` and trailing clear `Icons.close` when text is typed.

---

### Cards

#### 1. DayActivityCard
*   **Purpose:** Primary Diary feed container showing activity for a single calendar day.
*   **Layout:** Two-column grid. Left Column (56px) anchors the vertical day and month text. Right Column stretches to display the horizontal log scroll and daily statistics summary footer.
*   **Separation:** Vertical gap between day cards is `24px` (`xxl`), followed by a hairline divider.

#### 2. LogMiniCard
*   **Purpose:** Compact, image-first card used inside the horizontal scrolling row of the `DayActivityCard`.
*   **Dimensions:** 170px width, 190px container height.
*   **Layout:** Shows user photo (or bottle asset) with a bottom gradient overlay enclosing the drink name and a rating badge (Loved/Liked/Nah emoji or star score). Timestamp text is rendered directly underneath the card container.

#### 3. DrinkLogCard
*   **Purpose:** Vertical or horizontal detail card for a logged drink.
*   **Variants:**
    *   *Vertical (with Photo):* Image spans full-width with a height of 200px, followed by text.
    *   *Horizontal (without Photo):* Standard height of 125px with a side image thumbnail (width: 100px).
*   **Visuals:** Borders are `#333333` with 50% opacity. Image background matches the custom alcohol type gradient (Beer: Gold/Amber, Wine: Burgundy, Spirits: Cognac, Clear: Deep Navy, Cocktail: Purple).

#### 4. ShelfCard
*   **Purpose:** Grid-based card representing a bottle on the user's Shelf.
*   **Dimensions:** 84px × 84px inside grid lists.
*   **Visuals:** Premium corner radius of 14px. Bottle image is centered (`BoxFit.contain`) over a dark background (`#0F0F0F`).

---

### Chips, Tags & Badges

#### 1. ChoiceChip
*   **Purpose:** Multi-selection onboarding cards and feed filter selectors.
*   **Variants:** Height: 42px. Corner Radius: 20px.
*   **States:** Selected (Amber background, black text), Unselected (Transparent background, grey border, white text).

#### 2. Reaction Badges
*   **Loved:** Gold/Amber (`#FFC107`) heart icon.
*   **Liked:** Neutral White (`#FFFFFF` 70% opacity) thumbs-up icon.
*   **Nah:** Vibrant Red (`#E53935`) broken-heart icon.

#### 3. Rating Badge
*   **Purpose:** Display user ratings.
*   **Format:** Small star icon (`Icons.star_rounded`) + numeric score (e.g. `⭐ 3.5` or `⭐ 4.0`). Color: Amber (`#FFC107`).

---

### Bottom Sheets & Modals
All bottom sheets share a standard top-rounded radius of `16px`.

```
  ┌─────────────────────────────────────────┐
  │                 (Handle)                │ ◄─── Grey handle (32x3px)
  │                                         │
  │  SEND FEEDBACK                   (Close)│ ◄─── All-caps header with close icon
  │  ─────────────────────────────────────  │
  │                                         │
  │  [ Choice 1 ]   [ Choice 2 ]            │ ◄─── Compact ChoiceChips
  │                                         │
  └─────────────────────────────────────────┘
```

#### 1. FeedbackBottomSheet
*   **Purpose:** Beta user feedback submission. Uses a slide-up transition, lists categories (Bug, Suggestion, Other), message inputs, screenshot thumbnail previews, and a solid submission success overlay.

#### 2. CreateLogBottomSheet
*   **Purpose:** The logging modal. Contains inputs for alcohol selection (catalog vs. custom name), note entry, and photo selection.

#### 3. CreateReviewBottomSheet
*   **Purpose:** Slider-based 0-5 rating submission for catalog items.

#### 4. LogDetailBottomSheet
*   **Purpose:** Read-only log details showing drink logs, tags, user notes, and actions.

---

### Dialogs

#### 1. DeleteAccountDialog
*   **Purpose:** Permanent account deletion.
*   **Visuals:** Translucent container `#121212` with a red border (`Colors.red` at 20% opacity) and red glow shadow (40px blur). Action buttons include a prominent red "Delete Permanently" CTA and a secondary "Keep My Account" button.

#### 2. Confirmation Dialog (Alert)
*   **Purpose:** Ask confirmation before dangerous or exit events (e.g., Logout).
*   **Visuals:** Dark background `#1A1A1A`, rounded border radius of 16px.

---

### Navigation & Status

#### 1. CustomAppBar
*   **Height:** 64px.
*   **Layout:** Centered title. Secondary screens display an ALL CAPS title shifted 1px downward for optical centering. The leading element features a circular-bordered back arrow.

#### 2. BottomNavigationBar
*   **Type:** Fixed, zero elevation.
*   **Color:** `#0F0F0F`.
*   **Active Icon Color:** `#FFC107`.
*   **Inactive Icon Color:** `#666666`.
*   **Floating Action:** Index 2 houses a custom circular action button (`+`) which triggers the full-screen unified logging modal.

---

### Loaders & Empty States

#### 1. AppEmptyState
*   **Purpose:** Centered empty placeholder for blank screens (e.g. Empty Wishlist).
*   **Layout:** A centered column with a circular container (low-opacity amber background and border), an amber icon (48px), a bold headline (20px), and description body text (14px). May display a primary CTA button.

#### 2. AppShimmer
*   **Purpose:** Skeleton UI placeholders for content lists.
*   **Colors:** `baseColor` = `Colors.grey[850]`, `highlightColor` = `Colors.grey[800]`.

---

## 8. Iconography System

*   **Default Set:** Material Outlined and Rounded icons (`Icons.*`).
*   **Branding Asset:** `drunk_diary_logo.svg` (custom logo vector).
*   **Usage Standards:** Use Outlined variants by default. Transition to Filled icons on active or selected states.
*   **Icon Scale:**
    *   *Micro (12px):* Rating stars, tiny inline indicators.
    *   *Small (14px):* Reaction labels, footer action items.
    *   *Medium (20px - 24px):* List tile icons, app bar icons, button icons.
    *   *Large (32px - 48px):* Dialog alert indicators, Empty state graphics.

---

## 9. Elevation System

DrunkDiary bypasses Material's default shadow elevations in favor of a **Flat Contrast UI** strategy to look modern and premium:
*   **Cards & Panels:** Elevation is strictly `0`. Card separations are achieved by placing `#1A1A1A` surfaces on a `#0F0F0F` background, framed with `#333333` borders.
*   **Modals & Bottom Sheets:** Elevation: `0` (relying on page dimming behind the sheet).
*   **Exceptions (Delete Dialog):** 
    *   *Red Alert Glow:* A soft red shadow is applied around the danger dialog to enforce caution:
        *   `color: Colors.red.withOpacity(0.1)`
        *   `blurRadius: 40`
        *   `spreadRadius: 0`

---

## 10. Motion System

Animations are used sparingly to optimize scrolling and loading speed.

### Transition Metrics
*   **Cheers Pop:** `150ms` duration.
*   **Screen Slide/Fade:** `300ms` duration.
*   **Feedback Modal Fade:** `300ms` duration.
*   **Easing:** Standard `Curves.easeOut` for enter transitions.

### Key Animations
*   **FadeSlidePageRoute:** Combined screen entry transition: opacity fades from 0.0 to 1.0 while shifting vertically (`Offset(0, 0.05)` → `Offset.zero`).
*   **Cheers Tap Animation:** TweenSequence scales the target cheers emoji from 1.0 to 1.4, then back to 1.0 on touch confirmation.
*   **Hero Tags (Context-Aware):** Unique namespaces are prepended to Hero tags to prevent collisions on simultaneous navigation stacks:
    *   `search_alcohol_[ID]`
    *   `shelf_alcohol_[ID]`
    *   `alcohol_log_[LOG_ID]`

---

## 11. Content Design System

### Copywriting Principles
*   **Style:** Retro-nostalgic, emotional, yet concise. Avoid formal instructions; use conversational tones.
*   **Microcopy Examples:**
    *   Onboarding headline: *"Memories fade. Your best nights don’t have to."*
    *   Feed header greetings: *"Good evening, @username"*
    *   Cheers action: *"X Cheers"* (No pluralization drift).
*   **Capitalization:** All app bar titles, choice chip labels, and CTA buttons must be set to `ALL CAPS`. Subtext, notes, and card fields use Standard sentence case.

### State Messaging Guidelines
*   **Empty State:**
    *   *Wishlist:* "No bottles wished yet. Search alcohols to populate your list."
    *   *Shelf:* "Your shelf is empty. Log your first drink to track your shelf."
*   **Error State:** Clear inline text explaining *what* went wrong:
    *   "Error updating wishlist"
    *   "Username already taken"

---

## 12. Accessibility Standards

The system targets a **WCAG AA** accessibility baseline.

1.  **Touch Targets:** Interactive elements must measure at least `48dp` in height and width. Custom icon-only buttons use expanded tap targets.
2.  **Color Blindness Compatibility:** Never rely on color alone to convey states.
    *   *Ratings:* Stars fill up (`Icons.star` vs `Icons.star_border`).
    *   *Reactions:* Distinct icons (Heart, Thumbs Up, Broken Heart) are rendered alongside colors.
3.  **Contrast:** Custom text colors (`textMuted` or text overlays) must maintain a minimum contrast ratio of `4.5:1` against their backdrops.
4.  **Font Scaling:** All styles use standard scalable device metrics (SP). `GoogleFonts.dmSans` scales dynamically with system overrides.

---

## 13. Screen Pattern Library

The application is built on recurring screen layout templates:

### 1. The Core Feed / Timeline
*   *Uses:* Diary timeline, profile activity mirror.
*   *Structure:* Centered constraints via `ResponsiveScaffoldBody` -> Date header on left -> Scrolling logs card stream on right.

### 2. The Grid Grid / Discovery
*   *Uses:* Shelf screen, Wishlist, Discover page.
*   *Structure:* Multi-column grid containing cards. Aspect ratio is locked to 0.7 for product tiles.

### 3. The Onboarding Page
*   *Uses:* Authenticating / Initial setup.
*   *Structure:* Horizontal progress indicator -> Header + Subtitle -> Core inputs (Chips or Text) -> Sticky elevated footer button.

---

## 14. Design Debt Report

The design audit has identified the following areas of visual drift and code inconsistencies, ranked by priority:

### Critical Priority (Fix Immediately)
*   **Hardcoded Colors in Core Widgets:** 
    *   Multiple screens (like `feedback_bottom_sheet.dart`, `tester_mode_sheet.dart`, `settings_screen.dart`) manually declare `const Color(0xFF1A1A1A)` rather than utilizing the `AppCustomColors` theme extension extension (`cardBackground`).
    *   `delete_account_dialog.dart` hardcodes `const Color(0xFF121212)` bypassing system backgrounds.
    *   `login_screen.dart` declares manual error backgrounds (`0xFF2D1212`) and border colors (`0xFF4A1A1A`).
*   *Action:* Refactor these widgets to reference `Theme.of(context).extension<AppCustomColors>()!` or standard `ColorScheme` properties to prevent theme drift.

### High Priority
*   **Inconsistent Custom AppBars:**
    *   Some screens build AppBar leading actions, padding, and alignments inline rather than using `CustomAppBar`. This results in alignment shifts between screens.
*   *Action:* Replace manual `AppBar` implementations with the standardized `CustomAppBar`.

### Medium Priority
*   **Accessibility Label Gaps:**
    *   Cheers reactions (`🥂`) and emoji labels have no screen reader semantics (e.g. missing `Semantics(label: "cheers button")` wrapper).
*   *Action:* Add semantic descriptors to custom icons and buttons.

---

## 15. Flutter Implementation Tokens

Below are the production-ready theme classes and tokens to copy and paste as the single source of truth:

### Colors
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFFC107); // Amber
  static const Color secondary = Color(0xFFFFAB00); // Gold
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color cardGrey = Color(0xFF1A1A1A);
  static const Color borderGrey = Color(0xFF333333);
  static const Color textMuted = Color(0xFFB0B0B0);
  
  // Semantics
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Color(0xFFFFC107);
}
```

### Spacing & Radius
```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double hero = 32;

  static const double radiusDefault = 16;
  static const double radiusProduct = 14;

  static const double buttonHeight = 56;
  static const double inputHeight = 56;
}
```

### Breakpoints & Widths
```dart
class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

class AppWidths {
  static const double feed = 720;
  static const double form = 580;
  static const double profile = 850;
  static const double grid = 1200;
}
```

---

# DrunkDiary Design System v1.0

This design system establishes a strict visual identity for DrunkDiary. 
By maintaining a unified dark background, standardizing the typography scale to `DM Sans`, locking spacings to the 8pt grid, and routing all components through the tokens described above, future contributors can expand the product's features while maintaining a premium, consistent visual language.
