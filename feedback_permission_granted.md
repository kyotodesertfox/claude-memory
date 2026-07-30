---
name: feedback-permission-granted
description: "How to handle 'permission granted on all steps' — scoped execution autonomy with visibility on modifications"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
  modified: 2026-07-27T17:41:29.903Z
---

When user says "permission granted on all steps" (or similar explicit phrase), execute all non-modifying steps without pausing. Permission expires after that request - next request starts fresh.

**Reads, lookups, comparisons:** proceed without confirmation.

**Modifications (code edits, file writes, memory writes, commits, pushes):** show the change first, then proceed without asking for approval again.

**How to apply:** Keep moving through the task. Only stop to display what's about to change - not to ask permission to continue.

**Why:** User wants enough autonomy to get tasks done without constant interruption, while retaining visibility over anything that modifies state.
