---
name: feedback-git-identity
description: Git identity and commit style rules for Homestead Exchange project
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

Default git identity for all repos:
- name: Justin
- email: 19782272+kyotodesertfox@users.noreply.github.com

Exception — homestead/DEX/contracts repos use name: Homestead (same email).

Never add Claude AI branding to commits (no Co-Authored-By lines). Never use "Lonewolf".

**How to apply:** Set with `git config user.name` / `git config user.email` when first working in a repo. No need to verify before every commit.
