# 🤖 Antigravity AI Prompting Guide

This guide defines the optimal prompting format for the **Drunk Diary** codebase. Following these templates ensures minimal back-and-forth, adherence to established architectural patterns (Riverpod + Feature-First), and consistent UI/UX.

---

## 🏛️ Project Pillars (Always Consider)

1.  **Architecture**: Feature-First Clean Architecture (`lib/features/[feature_name]`).
2.  **State Management**: `flutter_riverpod` (v3+). Use providers for logic; views for UI.
3.  **UI/UX**: High-contrast dark theme (#0F0F0F), Amber accents (#FFC107), and `CategoriesElegant` branding.
4.  **Governance**: **Doc-Driven Implementation**. Documentation must be updated *before* code logic changes significantly.

---

## ⚡ 1. The "Quick Task" Template
*Best for: UI tweaks, minor bug fixes, or small utility additions.*

```markdown
**Task:** [Short description]
**Module:** [e.g., features/alcohol, core/theme]
**Goal:** [What is the specific goal?]
**Standards:** [e.g., Use AppTextStyles.caption, Check lints]
**Docs:** [None / Update Changelog]
```

---

## 🚀 2. The "Full Feature" Template
*Best for: New screens, complex business logic, or cross-module integrations.*

> [!IMPORTANT]
> This project uses the **Documentation-Driven Workflow**. For any full feature, I will first check the `Docs/` directory and propose a **Documentation Update Proposal** before writing any code.

```markdown
# 🛠️ [Feature Name]
**Workflow:** `/implement_feature`
**Context:** [Why are we building this? Goal & background.]
**Module:** [Target feature directory]
**Logic:** [Explain data layer: Firebase query? New Riverpod provider?]
**UI Requirements:** [CustomAppBar title? Modal-driven input? Shimmer required?]
**Analysis:** [Deep (analyze patterns first) / Shallow (just build it)]

**Consistency Constraints:**
* Hero animations must use unique tags (e.g., `feature_alcohol_[id]`).
* Follow `FRONTEND_GUIDELINES.md` for spacing and colors.
* Avoid hardcoded strings; use localized constants if applicable.

**Docs Check:**
- [ ] Update Docs/PRD.md
- [ ] Update Docs/APP_FLOW.md
- [ ] Update Docs/BACKEND_STRUCTURE.md (if data layer changes)
```

---

## 🤖 3. Using Agent Workflows
This repository contains specialized workflows in `.agents/workflows/`. You can trigger them by name:

*   **/implement_feature**: (Recommended for features) Triggers the "Documentation-Driven" flow. I will:
    1. Check `PRD.md`, `APP_FLOW.md`, etc.
    2. Provide a **Documentation Update Proposal**.
    3. Wait for your approval before writing any code.
*   **/audit_documentation**: Use this to analyze drift between the code and the `Docs/` folder.

---

## 📝 Example Prompts

### Example: Small UI Adjustment
> **Task:** Fix alignment on Profile settings
> **Module:** `features/profile`
> **Goal:** The Logout button is slightly off-center on narrow screens. Wrap it in a `SafeArea` and ensure it uses the full-width button pattern.
> **Standards:** Use `Theme.of(context).extension<AppCustomColors>()?.error` for the logout icon.

### Example: Major New Feature (Using Workflow)
> # 🛠️ Drunk Diary Anniversary Stats
> **Workflow:** `/implement_feature`
> **Context:** Show users a "Year in Review" style summary.
> **Module:** `features/activity`
> **Logic:** Create an `AnniversaryRepository` that aggregates Firestore logs from the last 365 days. 
> **UI Requirements:** Use a specialized `PageTransition` and custom gradients. Show a "Share to Socials" button.
> **Analysis:** Deep. Review `features/alcohol/repositories` for optimized Firestore aggregation patterns.
> **Docs Check:** [X] Update PRD.md [X] Update APP_FLOW.md.

