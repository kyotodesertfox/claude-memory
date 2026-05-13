---
name: feedback_no_autopush
description: Never git push unless the user explicitly says to push — commit only by default
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

Never run `git push` unless the user explicitly asks. Commit only, then stop and report the commit hash.

**Why:** User said "commit; but don't push" — they want control over when code goes to remote.

**How to apply:** When asked to "commit" or "commit changes", run `git add` + `git commit` only. Do not chain `&& git push`. Only push when the user says "push", "commit and push", or "go ahead and push".
