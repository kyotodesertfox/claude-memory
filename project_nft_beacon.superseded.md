---
name: project_nft_beacon
description: "Decision to migrate NFT collections to beacon proxy pattern — why, tradeoffs, lifecycle intent, and timing rationale"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4fca475b-7391-4d9c-925e-3a7e146c1864
---

## Decision: Migrate NFT collections to UpgradeableBeacon pattern

**Status:** Decided, not yet implemented. Flagged for next contract deployment cycle (Release 1 or alongside it).

**Why:** Scaffolding, not permanent structure. While nftTemplate is still being iterated on, one beacon upgrade fixes all collections simultaneously. Once the implementation is stable and battle-tested, beacon ownership transfers to a timelock or gets renounced. The beacon served its purpose and collections become effectively immutable.

**Why now is the right time:** Only one collection exists (BEER NFT, 5 tokens, none sold, all held by owner). No live listings, no active Treasury batches, nothing meaningful pointing at the old address. Lowest-cost migration window. Every collection added after this point raises the cost of switching.

**Migration path for existing collection:**
1. Burn all 5 tokens on old UUPS proxy
2. Deploy UpgradeableBeacon pointing at current nftTemplate impl
3. Redeploy nftDeployer to use BeaconProxy instead of ERC1967Proxy
4. Redeploy BEER NFT collection as BeaconProxy
5. Rewire: setMinter(Treasury), setRedemptionOperator(Marketplace), update contracts.js + .env

**Why it fits the model:**
- Product differences live entirely in NFT metadata, not contract logic. Beer, eggs, honey, services — same redemption flow, same contract. The beacon doesn't foreclose anything real.
- Existing contracts (non-deployer-registered) are already blocked by TokenDeployer/NFTDeployer isRegistered checks.
- Regulatory compliance is a fiat-layer problem, not a contract-layer problem.

**Tradeoffs accepted:**
- Blast radius: a bad beacon push breaks all collections simultaneously. Mitigated by: careful testing before any upgrade, timelock before renouncement.
- Centralized control during bootstrap: accepted. Beacon ownership transfers to DAO/timelock as platform matures. Not permanent.

**Custom collections - decided, tied to tier system:**
- Standard producers: BeaconProxy (platform-managed). Homestead upgrades, producer owns the tokens.
- High-tier attested producers: custom collection, self-governed. Producer owns the implementation and upgrade authority. Can extend beyond the standard template - royalty logic, burn mechanics, metadata extensions - without waiting on a beacon upgrade.
- Marketplace/Treasury don't care which proxy type - they only check isRegistered()
- The tier gate is the trust model. A producer who has earned high-tier attestation has history, skin in the game, and justifies implementation control.
- Do it now while no money has entered the platform and no tokens exist in the wrong structure. Migration against a live system with real assets is the cost of not doing it now.
- The NFTDeployer splits into two ownership models, not just two functions.

**Lifecycle intent:**
- Bootstrap: beacon owned by Justin, upgrades fast and clean
- Growth: producers get operational control (mint, CIDs, roles) — platform retains implementation control
- Maturity: beacon ownership → timelock → DAO or renounced
- End state: collections immutable, beacon was scaffolding

**Deploy-line pattern:**
Features never make it to chain because each feature reveals the next one and gas cost of constant upgrades makes iterating on-chain expensive. The correct pattern: build until stable enough to justify a deploy, push everything at once. The problem is "stable enough" keeps moving. The custom collections / tier architecture decision was the missing piece that kept the deploy line moving. Now that the ownership model is decided, the next deploy pass should draw a hard line and push everything up to that point regardless of what the next feature implies.

**Why:** [[project_contracts]]
