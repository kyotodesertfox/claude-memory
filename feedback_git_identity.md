---
name: feedback-git-identity
description: Git identity and commit style rules for Homestead Exchange project
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

Never use "Lonewolf" in this project. Git identity is:
- name: Homestead
- email: 19782272+kyotodesertfox@users.noreply.github.com

Never add Claude AI branding to commits (no Co-Authored-By: Claude lines).

**Why:** User explicitly corrected this — "Lonewolf" is a different identity, Homestead is the project persona. Claude branding is unwanted in commit history.

**How to apply:** Every git commit in this project uses the Homestead identity with no co-author lines.
