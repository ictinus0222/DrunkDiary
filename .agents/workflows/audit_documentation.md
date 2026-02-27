---
description: Weekly Auto-Sync audit to identify drift between codebase and documentation.
---

# Documentation Sync & Audit Workflow

When this workflow is executed, the agent MUST perform the following steps to ensure long-term repository health:

1. **Read Current State:** Read the current contents of the 5 core documents:
   - `Docs/PRD.md`
   - `Docs/APP_FLOW.md`
   - `Docs/TECH_STACK.md`
   - `Docs/FRONTEND_GUIDELINES.md`
   - `Docs/BACKEND_STRUCTURE.md`

2. **Audit Codebase:** Audit the actual codebase using grep searches and file inspection against these documents.

3. **Identify Drift:** Identify and list:
   - Undocumented features (code exists, docs missing)
   - Deprecated features still in docs (docs exist, code missing)
   - Mismatches between database/firestore schema and `BACKEND_STRUCTURE.md`
   - Navigation and routing differences from `APP_FLOW.md`
   - Missing dependencies or unmapped tools in `TECH_STACK.md`

4. **Generate Report:** Generate a synchronization report as an artifact and present it to the user. 
   - Ask the user which changes they would like to apply to synchronize the documentation with the code.
   - Do NOT apply changes automatically until approved.
