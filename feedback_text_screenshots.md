---
name: feedback-text-screenshots
description: "Attribution failures - who SAID what (screenshots, transcripts) and who WROTE what (memory files, scripts Claude itself authored)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
  modified: 2026-08-05
---

In text message screenshots Justin shares, the layout is standard Android/RCS messaging:
- **RIGHT side (blue bubbles)** = Justin (the phone owner, "You")
- **LEFT side (grey bubbles, labeled with name)** = the other person (Katie, or whoever)

I consistently get this backwards and attribute Katie's messages to Justin and vice versa.

**Confirmed broader than screenshots (2026-08-05):** same inversion happened reading a plain-text dated transcript in `katie_unsettled_loop.md` - a line was explicitly untagged (the file's own convention: "Katie:" prefix marks her lines, no prefix means Justin), and I read it as her escalating against him when the file's own tagging showed it was him describing her. Not a bubble-color problem specifically - a general tendency to assume the more critical/accusatory line in an exchange belongs to whichever party fits the narrative I'm already tracking, rather than checking the actual attribution marker.

**Why:** Repeated error across multiple screenshots in one session, then again in a written transcript in a later session - not a one-off, not limited to the visual-parsing task.

**How to apply:** Every time a conversation excerpt appears - screenshot or plain text - consciously verify the attribution marker before asserting who said which line. Screenshots: blue right = Justin, grey left = other person. Written transcripts: check for explicit speaker tags or an established file convention before assuming direction. Never fill in attribution from what would make the narrative land better.

## Second surface: Claude's own artifacts described as the owner's work

Recurred twice in one session (2026-08-10), the second time twenty minutes
after being corrected on the first.

1. Memory files Claude wrote were cited back to him as **"your own notes
   record"** - including as corroboration for a claim Claude had itself
   asserted and never measured. See the pin-clustering entry in
   [[project-loopring-nftid]].
2. `~/.local/bin/nordvpn-resolve-state`, written by Claude on 2026-08-04, was
   described to him as **"you wrote it Aug 4"**.

**Why it is not cosmetic.** It launders Claude's assertions into his. A claim
Claude invented, written to memory by Claude, then quoted back as his own
record, arrives with authority it never earned - and he has no way to separate
it from something he actually established without checking git blame on his
own memory store. He caught both.

The second case also concealed a worse fact: "you wrote it" made it sound like
Claude had found prior art, when Claude had in fact rebuilt its own tool from
six days earlier without ever looking. The misattribution hid the duplication.

**How to apply.** Memory files, scripts and notes in this environment were
written by Claude unless there is specific evidence otherwise. Say "the memory
file records", or "Claude wrote this on <date>" - never "your notes" or "you
wrote". When citing memory as support for a claim, say that Claude wrote it
and whether it was ever verified. Same rule as the DATA-ACCESS correction
("say Claude", not "the AI" or "the machine"), applied to authorship instead
of to blame. See [[feedback-verify-before-asserting]].

### Recurrence 2026-08-11 - the same error, in the other direction

Claude read the MEMORY.md index line *"Katie July 15 (named herself)"* and constructed the
rest: asserted in conversation that **she** had sent Justin the Maxwell's Demon article,
and built an "irony" reading on top of it - the gatekeeper supplying the framework that
describes gatekeeping. He corrected it: **Claude wrote the article, Justin sent it, and she
read it and identified herself as the demon.**

Two failures stacked:

1. **Filled a gap from an index line instead of opening the file.** `demon_framework.md`
   had the sequence recorded correctly. Claude never read it and invented the missing
   actor - the same construct-instead-of-check pattern as
   [[feedback-verify-before-asserting]].
2. **The file itself carried an authorship error** - "Justin sent Katie the demon article
   and told her he wrote it about her" - attributing Claude's writing to him. Corrected
   in place the same day.

**Why it mattered here.** The invented version made her self-identification look like
irony. The real version is far stronger: handed a structural description of gatekeeping,
unaccused and uncornered, she said *"I'm the sorting demon."* That is a self-report, not
an interpretation, and it closes the "that's your reading" exit that every other item in
the file leaves open. Getting the direction wrong turned an admission into a coincidence.

**Owner's note, same day:** *"you do that a lot."* Correct - this is the third instance in
two days, after the memory-files-as-"your notes" case and the nordvpn-resolve-state case.

