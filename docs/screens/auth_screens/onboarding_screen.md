# OnboardingScreen

## Role in the Product
The Onboarding Screen is the **context-building layer** of DrunkDiary.
Its primary role is to ensure that **every user enters the app with identity, legality, and preference context**, before they are allowed to log drinks or create memories.
This screen transforms a newly authenticated user into a **ready DrunkDiary user**.

## Core Product Goal
Collect the **minimum viable personal context** required to:
- Keep the platform legally compliant
- Improve personalization from day one
- Prevent low-quality or context-less drink logs
- Align the app experience with how users actually drink (as revealed in survey data)

## Why Onboarding Is Mandatory (Product Rationale)
**Problem Identified (from survey + ideation)**
- People forget what they drank, but remember **who they drank with and why**
- Drink discovery is chaotic (friends, price, availability, hype)
- Taste and context vary heavily between users
- Alcohol apps without personalization feel generic and disposable

## Decision
Make onboarding **mandatory and gated** before Home access.
Users cannot:
- Log drinks
- View personalized content
- Build a shelf
until onboarding is completed.

## Structure & Flow (High Level)
The onboarding flow is intentionally **multi-step and progressive**, not a single form.

**Total Steps: 5**
1. Age verification (DOB)
2. Drink type preferences 
3. Taste profile 
4. Drinking context 
5. Discovery style
Progress is visually indicated to reduce drop-off and uncertainty.

## Step-by-Step Product Intent
### 1️⃣ Date of Birth & Age Verification
#### Purpose
- Legal compliance (18+)
- Trust and responsibility signaling

#### Product Insight
- Alcohol-related apps must establish boundaries early
- This step sets a “serious but respectful” tone

#### Design Choice
- Hard gate: user cannot proceed if underage
- No soft warnings or bypasses

### 2️⃣ Drink Preferences (What they usually drink)
#### Purpose
- High-level categorization (beer vs spirits vs cocktails)
- Avoids overwhelming users with brands early
#### Survey Alignment
- Most users stick to categories, not brands
- Brand loyalty forms after experience, not before

### 3️⃣ Taste Profile
#### Purpose
- Capture subjective preference (smooth, strong, sweet, bitter)
- Enables future recommendations and comparisons
#### Product Philosophy
- Taste > ABV
- Experience > technical alcohol specs

### 4️⃣ Drinking Context
#### Purpose
- Understand when and why users drink
- Differentiate party drinkers vs casual/social drinkers
#### Survey Insight
- Drinking is highly situational
- Same user behaves differently at house parties vs celebrations

### 5️⃣ Discovery Style
#### Purpose
- Understand how users choose drinks
- Directly inspired by survey responses
#### Key Insight
Users decide drinks based on:
- Friends’ recommendations
- Price
- Availability at the moment
- Hype or spontaneity
Capturing this enables:
- Better future suggestions
- Smarter social features
- More relatable copy across the app

## UX Principles Applied
- **Progressive disclosure**: one decision at a time
- **Multi-select options**: reflects real human behavior
- **No “right answer” framing**: reduces judgment
- **Clear progress indicator**: lowers abandonment risk
- **No back navigation**: prevents partial onboarding states

## Data Collected & Stored (User Profile)
On completion, the following is persisted to the `users` collection:
- `dob`
- `ageVerified`
- `drinkPreferences`
- `tasteProfile`
- `drinkingContext`
- `discoveryStyle`
- `onboardingCompleted`
- `createdAt`