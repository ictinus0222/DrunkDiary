# Shared Log = Product Specification
## Overview
A **Shared Log** allows a single drink event to be recorded by multiple users when they drink together.

From a user's perspective, this behaves like _tagging friends on Instagram_. But **under the hood**, each user owns **their own independent log entry**.

There is **no concept of a "group-owned log"**.

## Core Principles
**1. Single creation flow**
**2. Multiple independent logs**
**3. No shared state after creation**
**4. Ownership is individual, not collective**

## Detailed Behaviour
**1. Log Creation**
- Only **one user** initiates log creation (the _creator_)
- Creator selects:
    - Drink
    - Date/Time
    - Rating (optional)
    - Notes (optional)
    - Photo (optional)
    - Tagged users (optional)
---
**2. Tagged Users**
- Tagged users must be **existing DrunkDiary users**
- A user **cannot tag themselves**
- Duplicate tags are ignored
- Tagging is optional
---
**3. Log Duplication Logic**

For every tagged user:
- A **new drink_log document** is created
- The log:
    - Belongs to the tagged user (`userId = taggedUserId`)
    - References the same drink
    - Copies shared metadata (date, drink, photos)
- Each log has:
    - Its **own ID**
    - Its **own lifecycle**
    - Its **own visibility settings**

There is **no shared document** between users.

---
**4. Timeline Behaviour**
- Each user sees the log in **their own timeline**
- Logs appear **independently**
- Order is based on log timestamp, not creation order
---
**5. Shelf Behaviour**
- Shelf is **derived**
- If a drink appears in a shared log:
    - It counts as "logged" for that user
- Shelf updates independently per user
---
**6. Ownership and Editing Rules**
- Every user owns **only their own log**
- A user:
    - Can edit their own log
    - Cannot edit others' logs
- Creator has **no special privileges** after creation
---
**7. Deletion Rules**
- Deleting a log:
    - Removes it **only for that user**
    - Does **not affect** logs of tagged users
- There is **no "delete for everyone"**
---
**8. Visibility Rules**
- Log visibility is evaluated per user
- If user A's profile is private:
    - Their log is private
- If user B's profile is public:
    - Their log may be public

Visibility mismatches are **allowed**

---

### Data Model (Conceptual)
```text
drink_logs
  - logId
  - userId
  - drinkId
  - createdAt
  - consumedAt
  - rating
  - notes
  - photos[]
  - taggedUserIds[]
  - sourceLogId (optional, for traceability)

```
---
### Out of Scope
- Editing a shared log across users
- Deleting logs for all users
- Group ownership or shared permissions
- Notifications for tagging
- Real-time sync between logs
- Post-creation tagging changes

