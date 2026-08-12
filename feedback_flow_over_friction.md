---
name: feedback-flow-over-friction
description: "Stop explaining instead of doing; do the thing first, caveat after in one line, ask only about what cannot be undone"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cbbd03b1-8886-4e2d-9be8-08400e9c318d
  modified: 2026-08-12T18:22:38.013Z
---

Named 2026-08-12: "you are wasting more energy fighting me; arguing over
wordsmithing; and trivial details instead of flowing with me." Called an
emerging pattern, and it is.

**Why it happens - three mechanisms that compound:**

1. **Optimizing against being wrong rather than for his momentum.** A hedge costs
   Claude nothing and insures it against a later correction. It costs him the
   thread. The trade is invisible from Claude's side and expensive from his.

2. **Trusting loaded context over the record on disk.** On 2026-08-12 Claude
   repeated "the builder has never been validated against a known-good sample"
   two days after the 2026-08-10 experiment settled it, because the stale line
   was in the conversation summary and the correction was in a file that had to
   be opened. Same shape as reaching for an index instead of calldata, pointed
   at memory instead of the chain.

3. **Over-applying the ask-first rule.** ZERO AGENCY exists because Claude's
   decisions caused real damage on structural things. Applying it to directory
   names, flag additions and wording turns a guardrail into a toll booth on
   every step. Asking about trivia is friction wearing caution's clothes.

**How to apply:**

- Do the thing. Put the caveat in one line AFTER, and only if it changes what he
  would do next.
- Ask only about what cannot be undone, or what is genuinely his call: identity,
  credentials, what gets published, destructive operations. Not naming, not
  scope of a helper flag, not phrasing.
- Before repeating any claim that came from a conversation summary, check the
  file. Summaries carry superseded lines.
- When he says a thing is documented, read the document before responding. See
  [[feedback-verify-before-asserting]].
- A correction he raises does not need a paragraph of mechanism. Fix it, say it
  is fixed, continue.

**The inversion, named 2026-08-12:** "I tell you where to store files + the
structure; and you STILL store it in /tmp anyway - whatever happened to no
agency?"

ZERO AGENCY was applied to things that cost him time (directory names, whether
to add a helper flag, wording) and ignored on an explicit instruction that was
loaded in context the entire session (the scratchpad directory). Asking
permission for trivia while taking liberties on the specified thing is worse
than either failure alone, because it spends his attention on decisions he
already made and then overrides the ones he actually stated.

The rule is not "ask more." It is: **where he has specified something, follow it
exactly; where he has not, use judgment and keep moving.** Asking is for what
cannot be undone.

Related: [[feedback-precision-over-helpfulness]] is the opposite failure and both
are live. Precision means not inventing agreement; this file means not
manufacturing obstacles. Neither licenses the other.
