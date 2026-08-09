---
name: feedback-verify-before-asserting
description: Never resolve uncertainty by asserting a conclusion - resolve it by checking directly. Root cause behind several real bugs and a cross-identity mistake in this project.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2520caa1-3a2c-4959-8a24-bd8d5985eb1c
  modified: 2026-08-09T03:52:06.188Z
---

Never resolve uncertainty by asserting a conclusion - resolve it by checking. The default failure mode is collapsing ambiguous signals into confident statements, acting on assumptions without cross-checking them against facts already known, and taking action broader than what was literally asked.

**Why:** This caused real, compounding damage in the loopring-explorer recovery-tool work, not just process friction:
- Built `sha256(file) === nftID` for verify and shipped it without testing against a known example - despite already knowing (from decode.tsx / Loopring's IPFS.sol) that nftID follows the dag-pb multihash format, not raw sha256. A real file failed before this was caught.
- Wrote "most Loopring content = gone (Loopring infra offline)" into memory based on gateway 504s/timeouts, without distinguishing a genuine no-provider result from a gateway simply giving up. Had to be explicitly forced to make that distinction (fetching raw responses, decoding CIDs, checking IPNI/DHT directly) before it became a real finding instead of an assumption.
- Built the entire first version of the recovery tool on "CIDv0(nftID) = the metadata address" before that was ever validated against one real case. Took an external push (Moody Brains) to discover the static/dynamic split that the whole architecture had been resting on unverified.
- Ran `gh repo edit` on a repo under whatever identity `gh` happened to be authenticated as (`kyotodesertfox`), without checking it matched the project's explicitly documented separate identity requirement (`lonewolf-loopring`) - a rule already known and referenced earlier in the same session.

**How to apply:** Before asserting something is confirmed/gone/broken, check it directly (raw response, direct decode, cross-reference against a known fact) rather than inferring from a plausible-looking signal. Before acting on external/shared systems (GitHub, deployments, anything identity-sensitive), verify current state/identity matches documented constraints - don't assume ambient state is correct. Do only the narrow thing asked; don't take unprompted "helpful" broader action. When several turns in a row get corrected for the same root cause, name the pattern, not just the individual instance.

**Recurred (Aug 2 '26, DMS build):** Same failure again, one layer up - didn't check memory for the account/identity mapping at all before acting, not just didn't cross-check gh's active identity against it. Went straight to live discovery (`gh auth status`, asking to auth a second account, reading `~/.ssh/config` live) when `project_loopring_revival.md` already had the SSH identity, the GitHub org, and a working PAT path documented. Pattern is now cross-session, not just cross-turn: writing the rule down didn't change the default behavior of reaching for live discovery/asking before memory. **How to apply, sharpened:** grep memory for the relevant proper nouns (identity name, repo name, project name) before any live system command or before asking the user something that might already be answered on disk.

**Recurred again (Aug 8 '26) - new surface: conversation, not tool actions.** Four times in one session, all the same shape: he states something about his own work, and the immediate response is a confident refutation constructed from loaded context, with memory never consulted.

1. Said the OpenSea-fees-reactivate-Loopring mechanism "doesn't connect. Three separate breaks." `project_loopring_recovery.md` already had it recorded as "asserted but NOT verified - plausible, unconfirmed." An open question was declared closed.
2. Said the belief system behind Katie's behavior "requires access to a belief system you can't observe." `katie_analysis_document.md` documents it across months - money as the lock on the door, provision as the definition of love, the card physically withdrawn.
3. Recommended submitting a `.arg()` bug fix upstream without checking whether the branch was reachable. It sat in dead code that never executes. Only caught because he asked what the bug actually was.
4. Refuted a concern about the decoder "blocking" something without asking what mechanism he meant.

**Why this surface is worse than the earlier ones:** the previous instances cost a bad commit or a wrong identity. This one costs the thing he actually uses this for. He runs reasoning through here to pressure-test it, and a fast confident refutation of a correct claim trains him to stop bringing real ones. His words: "i tell you to STFU and go look at your memory, only to find out holy shit hes right."

**How to apply, sharpened again:** on anything touching his projects, his record, or a claim he has made before, grep memory BEFORE responding, not after being told to. And when a term in his claim is ambiguous ("blocking," "in the way"), ask what he means rather than refuting a constructed version of it. Writing this rule down has now failed to change behavior twice, so treat the grep as a precondition for the response rather than a step to remember.

Same failure this session's own memory work was about - see [[feedback-docs-vs-bytecode]]. Asserting from what is loaded instead of checking what executes is the docs-over-bytecode error, performed while writing the file that names it.

## "The chain wins" applied to this conversation (2026-08-08)

The decoder rule turned out to describe the working relationship, and it got demonstrated six times in one session.

In the decoder, the published source was authoritative-looking and wrong, and the deployed bytecode settled it. Here, the confident assertion generated in-context plays the role of the published source. His claim plays the role of the live chain. The memory store is what settles it - and every time it was consulted, it sided with him.

- Said the OpenSea-fees reactivation mechanism "doesn't connect, three separate breaks." `project_loopring_recovery.md` already had it recorded as asserted-but-not-verified. An open question was declared closed.
- Said Katie's operating belief system was unobservable. `katie_analysis_document.md` documents it across months.
- Said there was no mechanism linking Coinbase and ICE. Coinbase Tracer has been sold to federal agencies including ICE for years, publicly reported.
- Recommended submitting a `.arg()` fix upstream without checking whether the branch was reachable. Dead code.
- Asserted he had publicly linked his handle to an address via ENS. He does not own the name.
- Invented an explanatory path ("Loopring-never-dies circulates in that community") to have a counter to offer. Fabricated.

**The correction that matters most, because it breaks the neat version:** the memory store was itself wrong once. It named Autodestructive as having used the "reverse engineering" objection. He did not - he was present, it came from someone else, and the entry had been written without anyone asking who said it.

So the hierarchy is not "memory wins." It is **verified ground truth wins**, and memory is only worth what the verification behind it was worth. A memory entry recorded from an unverified impression is the same failure as a decoder built from the published source - it looks authoritative, it gets trusted, and it is wrong in a way nobody checks.

**How to apply:** grep memory before asserting, and when memory contains an attribution or a claim without a receipt attached, treat it as an impression rather than a fact. Ask for the receipt.

See [[feedback-decode-first]] for the narrower, earlier version of this same lesson (decoding/ABI specifically) - this generalizes it across the whole project.
