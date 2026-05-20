---
name: project_governance
description: "Homestead DAO governance design — tier system extension, Tier 4 criteria, anti-whale principles, bootstrap path, slash mechanism"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4d10e6c7-3013-43a7-b1f4-1cad366cf7fd
---

## Core principle — NO capital gating

Wealth alone must never grant governance power. History shows capital-gated governance gets captured by whales. Stake matters for Tier 2 (Producer) because skin-in-the-game is required to produce. Tier 4 governance is earned through time and participation — things that cannot be bought.

**Why:** Justin explicitly ruled out capital gating. Time-weighted alone is also insufficient. The combination of time + activity + peer nomination is the target.

## Attestation tier map

| Tier | Label | Gate |
|---|---|---|
| 0 | None | Default |
| 1 | Holder | Minimum cumulative stake (TBD) |
| 2 | Producer | Higher cumulative stake — unlocks `openLot`, `registerStyle` |
| 3 | Verified | Significant stake threshold — unlocks governance participation |
| 4 | Council | Tier 3 + time + activity + peer nomination — owns governance rights |

## Tier 4 criteria (not yet coded)

Two paths — same destination, different speed:

### Solo path (no nominations needed)
1. **Tier 3 status**
2. **Very long time at Tier 3** — high bar, cannot be fast-tracked with capital
3. **Very high on-chain activity** — completed batches, redeemed lots, style registrations, governance votes. Real engagement over a sustained period.

The first Tier 4 wallet in existence earns it this way. No permission from anyone required.

### Accelerated path (community trust)
1. **Tier 3 status**
2. **Shorter (but still meaningful) time at Tier 3**
3. **Activity threshold** — lower than solo path but still required
4. **Weighted vote threshold** — nominations come from Tier 3 and Tier 4 wallets. Tier 3 vote = 1 unit weight. Tier 4 vote = higher weight (exact multiplier TBD, e.g. 3x). Candidate must accumulate N total weight units. Early on (no Tier 4 exists) the pool is flat Tier 3 votes. As Tier 4 grows their weighted votes compress the timeline further for trusted candidates.

Community trust compresses the clock but does not replace time and activity entirely.

**Why:** time and activity cannot be bought. A whale can reach Tier 2 with capital but cannot manufacture months of on-chain participation history. Weighted peer votes solve the bootstrap problem — no admin genesis needed, no single wallet controls the first elevation. Tier 4 carrying higher vote weight reflects earned trust compounding over time.

## Bootstrap path

No admin designation needed. The first Tier 4 earns it through the solo path — time and activity, no nominations required. Once Tier 4 wallets exist, subsequent candidates can take the accelerated path via Tier 3 nominations. The system is fully self-bootstrapping.

## Governance actions gated at Tier 4

- `slashStake(batchId)` — requires Tier 4 quorum
- Contract ownership (Treasury, Marketplace) — held by timelock controlled by Tier 4 multisig
- Any future owner-only functions

## slashStake mechanism (not yet coded)

Current impl: `onlyOwner`, emergency only — marks batch slashed, blocks producer from `claimStake`, freezes `usedCollateral`.

Target design:
- Any Tier 4 wallet can propose a slash
- N-day timelock before execution (accused producer can respond, community can observe)
- Requires M-of-N Tier 4 approvals to execute
- Any Tier 4 wallet can veto within the window
- Slash never happens silently or unilaterally
- Buyers of slashed batch NFTs are NOT punished — redemption still works, escrowed tokens still flow

## NFT/repo interaction with slash (not yet coded)

- Unsold NFTs in listing → pushed to `repoInventory` on slash
- Producer's ETH claim on that batch → forfeit, stays permanently in Treasury
- `usedCollateral` for that batch → stays locked (punishment, capacity not recovered)
- Escrowed tokens for remaining unredeemed NFTs → resolution path TBD

## Relationship to ownership renouncement

Owner is NOT renounced — ownership is **transferred to a DAO/timelock** controlled by Tier 4 council. Full renouncement would make `slashStake` permanently impossible. The target state is: no single wallet controls anything, but the ecosystem retains the ability to act in emergencies through collective governance.

## Style registration gate [[project_contracts]]

`registerStyle(name, symbol)` requires Tier 2 (Producer). The stake to reach Producer tier is the spam filter. No separate deposit required. Treasury deploys the style NFT contract atomically with correct permissions (Treasury = minter, Marketplace = redemption operator).
