---
name: feedback_check_existing_files
description: Always run find before creating new files in this repo — contracts and structure may already exist
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

Before writing any new file (especially smart contracts), run `find ~/github/homestead -name "FileName*"` first to confirm it doesn't already exist.

**Why:** Tried to create Treasury.sol in the wrong location. It already existed at `contracts/treasury/Treasury.sol`, not `contracts/marketplace/` as assumed. User had to intervene.

**How to apply:** Any time a task involves creating a new contract, script, or config file — `find` first, then read what's there before deciding to create vs. upgrade. Saves a wasted Write call and user correction.
