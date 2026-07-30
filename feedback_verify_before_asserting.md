---
name: feedback-verify-before-asserting
description: "Never resolve uncertainty by asserting a conclusion - resolve it by checking directly. Root cause behind several real bugs and a cross-identity mistake in this project."
metadata:
  type: feedback
---

Never resolve uncertainty by asserting a conclusion - resolve it by checking. The default failure mode is collapsing ambiguous signals into confident statements, acting on assumptions without cross-checking them against facts already known, and taking action broader than what was literally asked.

**Why:** This caused real, compounding damage in the loopring-explorer recovery-tool work, not just process friction:
- Built `sha256(file) === nftID` for verify and shipped it without testing against a known example - despite already knowing (from decode.tsx / Loopring's IPFS.sol) that nftID follows the dag-pb multihash format, not raw sha256. A real file failed before this was caught.
- Wrote "most Loopring content = gone (Loopring infra offline)" into memory based on gateway 504s/timeouts, without distinguishing a genuine no-provider result from a gateway simply giving up. Had to be explicitly forced to make that distinction (fetching raw responses, decoding CIDs, checking IPNI/DHT directly) before it became a real finding instead of an assumption.
- Built the entire first version of the recovery tool on "CIDv0(nftID) = the metadata address" before that was ever validated against one real case. Took an external push (Moody Brains) to discover the static/dynamic split that the whole architecture had been resting on unverified.
- Ran `gh repo edit` on a repo under whatever identity `gh` happened to be authenticated as (`kyotodesertfox`), without checking it matched the project's explicitly documented separate identity requirement (`lonewolf-loopring`) - a rule already known and referenced earlier in the same session.

**How to apply:** Before asserting something is confirmed/gone/broken, check it directly (raw response, direct decode, cross-reference against a known fact) rather than inferring from a plausible-looking signal. Before acting on external/shared systems (GitHub, deployments, anything identity-sensitive), verify current state/identity matches documented constraints - don't assume ambient state is correct. Do only the narrow thing asked; don't take unprompted "helpful" broader action. When several turns in a row get corrected for the same root cause, name the pattern, not just the individual instance.

See [[feedback-decode-first]] for the narrower, earlier version of this same lesson (decoding/ABI specifically) - this generalizes it across the whole project.
