---
name: feedback_memory_warning
description: Warn the user before consolidating or summarizing memory — never do it silently
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

Always warn the user before consolidating, summarizing, or modifying memory files in bulk. Give them a chance to review or redirect before writing.

**Why:** User wants to stay aware of what's being committed to memory and have control over it.

**How to apply:** Before any bulk memory write (multiple files, restructuring the index, summarizing old entries), say what you're about to do and wait for a nod.
