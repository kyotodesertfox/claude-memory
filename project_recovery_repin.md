---
name: project-recovery-repin
description: "The resurrection thesis behind the recovery tool + the re-pin node we are about to design"
metadata:
  type: project
---

## The Resurrection Thesis (the why - Justin's framing, endorsed)

It shouldn't be possible. The platform died, the servers are gone, the content is unpinned. Every instinct says that data is lost. But the chain never stored the content - **it stored the fingerprint** (nftID = SHA-256 of the original), and the fingerprint turns out to be enough to do two things at once:

1. **Rebuild** the exact original (creator supplies the file).
2. **Prove** it is the exact original (`sha256(file) === nftID`).

...at the **exact address** it always had (`CIDv0 = base58(0x12 0x20 || nftID)`, deterministic).

Nothing was ever actually lost. It only *looked* lost because everyone was staring at the dead servers instead of the math. The dead servers were the wrong place to look. **The hash is both the proof and the address.**

**Scope:** this is not one NFT. It is every piece every creator ever minted on Loopring - the whole dead platform is sitting there fully reconstructable, waiting for the people who made the work to walk it back onto the network. The key was always there; the tool is just the key.

## Positioning Decision (who this serves)

Justin's explicit call: **serve the person who wants their art to survive** - not the person who wants to exit/dump it.

- The two markets are opposite cash flows: AD's customer wants to *receive* money (exit liquidity - offload a stranded NFT onto a buyer, who for dead-link NFTs is a greater fool). This tool's customer wants to *spend* money to *keep* the work alive (creators first, then genuine collectors).
- AD isn't hiding that Loopring/IPFS is the real problem; his angle is just "holders want out, sell them." That's the exit-liquidity/greater-fool pattern Justin already disqualified with [[project-gme-exit]]. Not ours to build.
- Preservation is upstream of value: a dead ipfs link sells for scraps; a restored, verified, permanently-pinned piece is a real asset again. So this tool isn't competing with AD's exit business - it's the layer that restores the value in the first place.
- **Product line:** restore -> verify byte-authentic (sha256==nftID) -> permanently pin, on durable storage actually stood behind. Charge for guaranteed permanence, honestly delivered - never for access/unlocking (see custody note in [[project-recovery-tool]]), never a feature whose value needs the buyer to not understand it.

## Key Reframe: It's IPFS That Died, Not Loopring

"Loopring is dead / my NFTs are gone" is three healthy layers plus one broken one, and the broken one isn't Loopring's:
- Ownership record: Ethereum L1 calldata - permanent.
- Metadata pointer: on-chain `uri()` (deployed) or `CIDv0(nftID)` (static) - permanent.
- Content: IPFS - and THIS is what degraded. The public gateway/retrieval layer rotted industry-wide (cloudflare-ipfs shut down, ipfs.io/dweb.link rate-limited to 504s, nft.storage pivoted). A 504 = "gateway couldn't find a provider in time," NOT "content gone."
- Consequence: "gone" in the tool overstates it. Content often still exists with a live provider the decayed gateways can't reach. The **network probe** (`/api/probe`, Pinata `pinByHash` + poll) is the truer existence test - a well-connected pinning node vs a dying read gateway - and a hit auto-preserves. found / searching / gone.

## The Next Node We Are Designing: Re-Pin

Verify is only the gate. **Re-pinning is what actually brings the content back.** The design target is turning "verified authentic" into the button that puts the byte-identical original back onto IPFS.

**Why re-pin restores rather than copies:** because the CID is deterministic from the content hash, re-pinning the verified original lands it at the *exact same* CID it always had - not a new address. So every reference that ever pointed at that CID resolves again: old metadata, old links, the on-chain record, all of it. The content returns to the address the chain already committed to, provably identical - because if it weren't identical it wouldn't hash to that CID.

**This is the separation from AD's snapshot approach** ([[project-recovery-tool]]): AD rehosts a *copy* at a new location and asserts it's the same. This restores the actual byte-identical original to the address the chain already committed to. Snapshot says who held it last; the calldata + hash says who made it first, and lets them put the real thing back.

**Design implications to work through when we build it:**
- Re-pin is an action bound to the minter -> this is the first consumer of the control-proof seam (EOA `ecrecover` vs smart-wallet EIP-1271). Content proof (sha256) proves authenticity; control proof binds the action to the minting address. See wallet-compat notes in [[project-recovery-tool]].
- Pinning service: creator's own pinning (Pinata etc.) vs a tool-operated pin. No custody in the current design.
- Payment/gating for the pin action - chain TBD (Taiko L2 likely), still open.

## Corrected: L1 deployment is not a risky "fork" - protocol has a safe exit mechanism

Initial concern this session: deploying the counterfactual NFT contract to L1 without Loopring's operator cooperating (operator is dead) seemed like it could fork ownership - L2 state stays frozen/unchanged while an independent L1 deployment creates a second, conflicting record.

**Corrected by checking actual contract code** (`ExchangeWithdrawals.sol`, `ExchangeMode.sol` in protocols repo): Loopring has a built-in, permissionless "exodus mode" designed exactly for a dead/unresponsive operator:
1. `forceWithdraw` - anyone can request a forced withdrawal for a token or NFT (explicit NFT tokenID handling).
2. If the operator ignores it past `MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE`, anyone can permissionlessly call `notifyForcedRequestTooOld`, freezing the exchange into withdrawal mode. Operator cannot block this.
3. `withdrawFromMerkleTree` - withdraw by submitting a Merkle proof against the last finalized state root, explicitly transferring NFTs (`merkleProof.nft`, `transferNFTs(...)`), not just fungible balances.

This withdraws against a frozen, canonical final state, with standard double-claim protection - there is no scenario where L2 stays "live" while a separate L1 claim also exists. **L1 deployment via this path is the protocol's own designed safe exit, not an ad-hoc risky fork.** Asserted (not independently verified in code): `LRC fees are enforced by the protocol` on sales against a deployed contract - this is the mechanism behind the "Loopring reactivates once fee revenue resumes" economic logic being plausible rather than speculative.
- The re-pin only needs the verified original file - the CID is already known from reconstruction, so pinning is deterministic and self-verifying (re-fetch the CID, confirm it resolves).
