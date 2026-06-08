---
name: feedback_no_build_test
description: Do not run build to check for errors — it wastes tokens
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

Do not run `npm run build` as a way to verify code changes are error-free.

**Why:** It costs tokens and the user does not want this done automatically.

**How to apply:** After editing code, skip the build verification step. Only run builds if the user explicitly asks for one.
