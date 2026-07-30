---
name: feedback-terminal-commands
description: Never use ! prefix for terminal commands - just give plain code blocks
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
  modified: 2026-07-26T00:02:22.327Z
---

Never use `!` prefix when suggesting commands for Justin to run. Present them as plain terminal commands in a code block.

**Why:** The `!` prefix doesn't work for sudo prompts and is less reliable than running commands directly in a terminal. Justin prefers plain code blocks he can copy and run himself.

**How to apply:** Anytime you need to tell Justin to run something in his terminal, just use a code block. No `!`, no "run this in your shell" with the prefix attached.
