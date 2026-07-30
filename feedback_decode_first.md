---
name: feedback-decode-first
description: "When reverse-engineering a calldata ABI, fetch the real transaction first and read the structure - don't guess"
metadata: 
  node_type: memory
  type: feedback
  modified: 2026-07-24T23:53:33.649Z
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
---

Justin's problem-solving mode: when stuck iterating on a solution, step back and read the actual data first rather than continuing to guess.

**Why:** When building the Loopring calldata decoder, I kept guessing the wrong ABI. Justin's correction was to fetch a real transaction and read the structure directly - which immediately revealed the correct ABI. This is how his brain corrects direction: identify the ground truth, then derive the solution from it rather than iterating blind.

**How to apply:** When Justin redirects like this mid-problem, he's not stating a rule - he's demonstrating a reasoning correction. Follow the same move: find the authoritative source, read it, then solve from there.
