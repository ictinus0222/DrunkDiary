# Frontend Design System & Guidelines

## 1. Design Principles (Inferred From UI)
*   **High Contrast Dark UI:** The primary implementation centers entirely around a dark theme with a stark black background and high-visibility amber accents.
*   **Card-based Grouping:** Content (logs, shelf items, stats) is primarily grouped and elevated visually using distinct dark-grey surface containers.
*   **Modal-Driven Input:** Complex user interactions (e.g., logging a drink, writing a review, tagging people) are isolated in bottom-sheet modals to preserve context.

## 2. Design Tokens (Extracted, Not Generated)

### Color Palette
Extracted from `app_theme.dart` and inline widget styling:
*   `--color-primary`: `Color.fromARGB(1, 255, 193, 7)` / `Colors.amber` (Used for active chips and primary accents)
*   `--color-background`: `Color.fromARGB(1, 14, 14, 14)` / `Colors.black` (Used for Scaffolds)
*   `--color-surface`: `Colors.grey.shade900` (Used for Cards, TextFields, and Stats containers)
*   `--color-text-primary`: `Colors.white`
*   `--color-text-secondary`: `Colors.grey` / `Colors.grey.shade600` / `Colors.grey.shade700`
*   `--color-success`: `Colors.green` (Used for "Like" thumbs up icon and positive username validation)
*   `--color-error`: `Colors.red` (Used for "Dislike" thumbs down icon and error text)

### Typography
*   **Font Family:** `Roboto` (Defined explicitly in `app_theme.dart`).
*   **Font Weights:** Regular (default), `FontWeight.w500`, `FontWeight.w600`, `FontWeight.bold`.
*   **Font Sizes (Explicitly hardcoded values found in codebase):** `12`, `13`, `14`, `16`, `18`, `20`, `22`, `24`, `28`.
*   *Note: Text themes fall back to Material 3 defaults (`titleLarge`, `headlineSmall`, `bodyMedium`) where explicit font sizes are not declared.*

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

### Bottom Navigation
*   **BottomNavigationBar:** Fixed type (`BottomNavigationBarType.fixed`) containing exactly 5 tabs.

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

## 5. Accessibility (Only If Implemented)
No explicit accessibility enhancements identified beyond default Flutter semantics and Material framework behavior.

## 6. Animation & Transitions (If Present)
No explicit custom animation system identified. Relies entirely on implicit Material 3 default transitions (e.g., Bottom Sheet slide-up).

## 7. Responsive Behavior (If Visible)
No explicit responsive differentiation implemented beyond default framework behavior. Viewports scale linearly.

## 8. Performance Guidelines
*   **Image Handling:** The repository imports `cached_network_image` in `pubspec.yaml`, though some screens still use fundamental `Image.network` loading.
*   No explicit frontend performance optimizations beyond native Flutter tree rendering identifiable.

## 9. Browser Support
Browser support policy not explicitly documented (Primary deployment architecture targets native mobile compilation).
