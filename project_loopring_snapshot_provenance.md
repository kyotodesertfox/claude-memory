---
name: project-loopring-snapshot-provenance
description: "Snapshot governance data used in lieu of L1 data because no L1 record of voting exists, not a substitute for calldata that could have been read instead"
metadata: 
  node_type: memory
  type: project
  originSessionId: cbbd03b1-8886-4e2d-9be8-08400e9c318d
  modified: 2026-08-14T17:04:48.401Z
---

Snapshot governance data is used in `loopring-proposals` / `/decode/proposals` in lieu of L1 calldata, not as a substitute for calldata that could have been read instead. Loopring's voting implementation never commits a vote to L1 - a Snapshot ballot is an EIP-712 signature proving who cast it and what they chose at cast time, but that signature is never submitted to the chain. No calldata path exists for this data, so reading it from Snapshot does not violate the calldata-only rule the way the [[project_decoder_community_reception]]-adjacent NFT-subgraph violation did (see [[project_loopring_revival]]).

**Why:** caught 2026-08-14 when he asked directly whether Snapshot or L1 data had been pulled for the proposals page. The earlier banner/README language ("NOT VERIFIED", "no signature recovered yet") was accurate but framed this as a pending-verification gap rather than a categorical one - implying signature recovery would bring it to parity with calldata. It can't: even a full signature check only proves authorship, not that Snapshot preserved/reported every ballot, since there's no on-chain commitment (no `publicDataHash` equivalent) to check totals against.

**How to apply:** on any future Loopring work touching Snapshot/governance, state plainly that this is Snapshot's account used because no L1 record exists to use instead - not "unverified pending signature recovery." Don't let language imply the two data domains could reach the same trust tier. Updated everywhere the trust state is stated: on-page banner (`SNAPSHOT DATA, NOT L1 DATA`), subtitle, file-header comment, both API doc comments (`pages/api/proposals.ts`, `pages/api/proposal-votes.ts`), the JSON `note` field, and `loopring-proposals/README.md`.
