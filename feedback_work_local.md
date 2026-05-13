---
name: feedback_work_local
description: "User prefers I clone remote repos locally rather than reading via SSH repeatedly, for faster iteration"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

When working extensively on a remote repo (like arcwright on the Pi), clone it locally first rather than SSH-reading every file over the network.

**Why:** Faster iteration — SSH reads per file add up; local clones let me read and write without network round trips. User explicitly said "if it would help you work faster to create things locally once you see them remotely — go ahead."

**How to apply:** For any session that involves editing multiple files in a remote repo, clone it to /tmp or a scratch location at the start, make all changes locally, then SCP or git push back to the Pi.
