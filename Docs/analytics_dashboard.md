# DrunkDiary Analytics & Telemetry Dashboard

## 📊 Strategy Overview
DrunkDiary uses a production-grade telemetry system designed to measure **Behavior**, **Friction**, and **Reliability** during the open testing phase.

### Naming Conventions
- **Events**: `snake_case` (e.g., `drink_logged`)
- **Parameters**: `snake_case` (e.g., `drink_type`)
- **Screens**: `PascalCase` matching the widget name (e.g., `ProfileScreen`)

---

## 🛠️ System Architecture
The system is modularized into specialized trackers to ensure maintainability:

| Component | Responsibility |
|-----------|----------------|
| `AnalyticsService` | Main facade, environment guards, breadcrumbs. |
| `SessionTracker` | Engagement depth, duration, screens per session. |
| `FunnelTracker` | Flow persistence (Onboarding, First Log). |
| `FrictionTracker` | Rage taps, rapid back, search abandonment. |
| `PerformanceTracker` | Firestore latency, operation duration. |

---

## 🌪️ Key Funnels

### 1. Onboarding Funnel
Tracks user conversion from signup to first entry.
- `onboarding_started`
- `onboarding_step_viewed` (Params: `step_index`, `step_name`)
- `onboarding_completed`
- `onboarding_abandoned` (Saved locally via SharedPreferences)

### 2. First Drink Funnel
Measures "Time-to-Value".
- `log_draft_started`
- `drink_photo_uploaded`
- `rating_added`
- `drink_logged`

---

## 🛑 Friction & Pain Signals
We track negative UX signals to identify where users struggle:
- `rage_tap_detected`: 5+ taps on same widget within 1s.
- `rapid_back_press`: Multiple back presses within 500ms.
- `search_zero_results`: High volume indicates alcohol database gaps.
- `search_abandoned`: Users clearing search without clicking results.

---

## 🛡️ Reliability & Stability
- **Crashlytics**: Global fatal and non-fatal error reporting.
- **Breadcrumbs**: Intent-based logging before major operations.
- **Categorized Failures**: Errors are tagged with categories (e.g., `permission_denied`) for easier triaging.

---

## 🔐 Privacy Standards
1. **No PII in Parameters**: Never log user names, emails, or review body text.
2. **Safe Metadata**: Device info is limited to model and OS version.
3. **Environment Guards**: Tracking is disabled in `development` mode by default.

---

## 🧪 Tester Mode
Access: **Long-press on Profile Avatar**.
Features:
- View current app version & environment.
- Force test crash.
- Quick access to debug logs.
