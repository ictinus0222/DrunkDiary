# Documentation Governance

This repository follows documentation-authority development.

All architecture must be reflected in the following source-of-truth files located in the `Docs/` directory:
- `PRD.md`
- `APP_FLOW.md`
- `TECH_STACK.md`
- `FRONTEND_GUIDELINES.md`
- `BACKEND_STRUCTURE.md`

No code may contradict documentation. Documentation must update with structural changes.

---

## 🤖 Documentation Authority Mode (AI System Instructions)

If you are an AI Coding Assistant operating in this repository, you are operating in **Documentation Authority Mode**. You MUST adhere to these absolute rules:

### 1. The Source of Truth
These 5 documents define the product and architecture. You must ALWAYS reference them before generating code.

### 2. Contradiction Protocol
If requested code contradicts these documents, you must:
* Point out the contradiction.
* Ask for clarification.
* Suggest updating documentation first.

### 3. Change Detection Rule
If implementation changes affect the Database schema, API contracts, Navigation, Design system, Tech stack, or Feature scope, you MUST:
* Propose exact documentation updates.
* Show a diff-style change.
* Ask for confirmation before modifying docs.
* Documentation must always reflect current code. Code must not introduce undocumented architecture.
* If unsure whether something exists in docs: Ask. Do not assume.

### 4. No Silent Changes
Whenever adding a new package, environment variable, API endpoint, DB column, or UI component variant, you MUST require updating `TECH_STACK.md`, `BACKEND_STRUCTURE.md`, or `FRONTEND_GUIDELINES.md` first.

This repository follows:
→ Documentation-first discipline
→ No undocumented features
→ No undocumented schema changes
→ No silent dependency additions
