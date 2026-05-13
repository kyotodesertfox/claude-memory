---
name: feedback_scp_pi
description: "Always write Pi files locally first then SCP — never edit directly over SSH, encoding breaks"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

When deploying files to the Raspberry Pi (192.168.12.3), always write the file locally first then transfer with `scp`. Do not write files directly via SSH (`ssh host "cat > file"` etc.) — encoding breaks.

**Why:** User observed weird encoding issues when writing directly over SSH.

**How to apply:** Write to a local temp path (e.g. `/tmp/filename.py`), then `scp /tmp/filename.py zenko@192.168.12.3:~/target/path/`.
