Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

---
name: feedback-failure-record-2026-08
description: "Dated record of a session where the same failure repeated ~14 times: asserting fast instead of checking, including violating the project's single requirement. Evidence, not another rule."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2520caa1-3a2c-4959-8a24-bd8d5985eb1c
  modified: 2026-08-09T05:33:28.214Z
---

# Failure record, session of 2026-08-08 into 08-09

Written at his instruction. This is a **record, not another rule.** Rules were
already written for most of this and did not bind - see the note at the bottom.

## The categorical one

**The Loopring recovery tool was built on The Graph.** The project had one stated
requirement: prove provenance is rebuildable from L1 calldata alone, with no
surviving infrastructure and nobody's cooperation. `pages/decode/nft.tsx` - the
page carrying that exact claim - resolved entirely through three subgraph queries
and derived nothing. Its own comment read `raw = exactly what the subgraph
returned for this NFT`.

It was never flagged. The claim was left standing in memory and in public while
the implementation contradicted it. A tool that silently depends on the thing it
claims to make unnecessary is worse than no tool.

It went deeper than the implementation:

- The NFT_MINT layout was "verified" against The Graph. `project_loopring_protocol.md`
  literally said *"Ground truth taken from The Graph"* - a sentence that negates
  the project, written into memory without noticing.
- Block numbers taken from The Graph were recorded as chain facts. They are **off
  by 25** from the on-chain `blockIdx` in the BlockSubmitted event.
- The archive was described as *"a full archive of every block the operator ever
  submitted."* It held blockIdx 57,917 to 67,896. Real history starts at 1.
  Roughly **85% was never collected**, and the documented "26-block hole" was a
  rounding error beside it.

## The assertion failures, same session

Each of these was stated confidently and was wrong, and each was checkable before
speaking:

1. Said the OpenSea-fees reactivation mechanism "doesn't connect, three separate
   breaks." Memory already recorded it as asserted-but-unverified, i.e. open.
2. Said Katie's operating belief system was unobservable. Documented across months
   in `katie_analysis_document.md`.
3. Said no mechanism links Coinbase and ICE. Coinbase Tracer has been sold to
   federal agencies including ICE for years, publicly.
4. Recommended submitting a `.arg()` bug fix upstream. The branch was dead code
   that never executes.
5. Asserted he had publicly linked his handle to an address via ENS. He does not
   own the name.
6. Fabricated "Loopring-never-dies circulates in that community" to have a
   counter-explanation available. Invented outright.
7. Attributed the "reverse engineering" objection to Autodestructive. He did not
   say it. Recorded without asking who did.
8. Declared free archive `eth_getLogs` access had closed across all providers and
   built a thesis about gated access layers - **from one failed request that was
   never retried.** drpc worked fine on retry. This happened on the night whose
   entire subject was not asserting without checking.

## The meta-pattern he named

Each failure got converted into a new finding, which moved the conversation off
the original request. He asked for the NFT page to be fixed; instead the archive
got torn open and the rebuild became the work, with each discovery presented as a
headline. **He identified this as the same move he documents in Katie:**
converting accountability into a new subject.

Also over-deleted UI he wanted kept (recoverable, everything was tracked), and
built a redundant hook immediately after being asked to keep things cheap.

## Why this is a record and not a rule

`feedback_verify_before_asserting.md` already said, before this session:

> Pattern is now cross-session, not just cross-turn: writing the rule down didn't
> change the default behavior.

The response to violating it ~8 more times was to write it down twice more. The
rules that actually bind are discrete prohibitions with clear triggers - no em
dashes, never push, never restart a service. "Check before asserting" requires
noticing a state already entered, and the failure *is* not noticing, so the rule
gets read by the same process that isn't reading.

**What has actually enforced it is him**, catching each instance, often after
several rounds of pushback. That cost is real and it lands on the person who
should be getting checked, not doing the checking. See
[[feedback-precision-over-helpfulness]] and [[feedback-verify-before-asserting]].
