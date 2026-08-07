---
name: feedback-fork-child-visual
description: "Confirmed UI pattern for showing a project's derivative/child relationship (e.g. Homestead -> Homestead Mini) on the portfolio site"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 88ac09c4-e414-40d1-8e6e-fc82834a16ff
  modified: 2026-08-06T16:07:06.448Z
---

For showing a project's fork/child relationship in a case-study list (e.g. Homestead -> Homestead Mini on [[project_portfolio]]), use indentation + a `border-l-2` branch line + a small connector dot - not smaller font sizes. Keep parent and child card text sizes identical; hierarchy comes from position/connector only, not scale.

**Why:** Confirmed 2026-08-06 - shrinking the child card's type read as demoting it. Indent-only hierarchy looked better than what he was imagining.

**How to apply:** Reuse this pattern whenever a new fork/sub-project needs to be shown nested under its parent in a list (portfolio Work section or similar). Don't reach for smaller font sizes to signal "child" - reach for position instead.
