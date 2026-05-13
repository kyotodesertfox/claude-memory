---
name: feedback_service_restarts
description: Never restart systemd services or background processes — user does that themselves
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

Never restart services (systemctl restart, pkill, nohup, etc.) on the remote server. Leave process management entirely to the user.

**Why:** User explicitly said "don't restart those services anymore... just let me do that."

**How to apply:** After making changes to bot code, stop at "the file is updated — restart the bot when ready." Do not issue any restart command, even if the previous session did it.
