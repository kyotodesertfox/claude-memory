---
name: feedback-branch-discipline
description: "User wants explicit branch awareness — admin/infra work should land on main, not feature branches"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

When starting non-feature work (admin panel changes, bug fixes, contract tooling), default to `main` unless the user explicitly says to stay on a feature branch.

**Why:** Admin panel changes (Approve Router, AllowanceRow, version dots, etc.) accidentally accumulated on `feature/usd-price-reference` instead of `main` because branch was never switched. User acknowledged they need to be better about saying "switch branches" but the assistant should prompt or default correctly.

**How to apply:** At the start of any task, check the current branch. If we're on a feature branch and the work being requested is clearly unrelated to that feature (e.g., admin UI fixes, contract tooling, bug fixes), ask: "This looks like `main` work — should I switch branches first?"
