---
description: Step-by-step process for implementing new features while adhering to Documentation Governance.
---

# Documentation-Driven Feature Implementation

Before implementing ANY new feature or structural change requested by the user, follow this workflow:

### Step 1: Pre-Implementation Checks
1. Check if this feature exists in `Docs/PRD.md`.
2. Check if this affects `Docs/APP_FLOW.md`.
3. Check if this modifies `Docs/TECH_STACK.md`.
4. Check if this changes `Docs/FRONTEND_GUIDELINES.md`.
5. Check if this modifies `Docs/BACKEND_STRUCTURE.md`.

### Step 2: Documentation Update Proposal
If the answer to any of the above checks is YES, and the changes are not yet fully mapped in the documentation, you MUST:
1. Halt code implementation.
2. Output a formal "Documentation Update Proposal" to the user using the following format:

```text
📄 Documentation Update Proposal
File Affected: [Document Name]
Section: [Section Name]

Change Type: [ADD/MODIFY/REMOVE]

Proposed Update:
[Show exact diff or addition]

Reason:
[Why this change is necessary for the implementation]

Affects:
[List cascading effects on UI, Auth, Structure, etc.]
```

3. Await user approval to update the documentation BEFORE writing any code.
