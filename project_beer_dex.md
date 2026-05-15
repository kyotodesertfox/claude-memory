---
name: project-beer-dex
description: Core project context — physical beer backed token/NFT redemption system built on the ART DEX framework
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

This DEX codebase (originally built around $ART) is being evolved into a physical beer production marketplace.

**Core mechanic:**
- $BEER is an ERC20 token backed 1:1 by physical beer inventory (the brewer mints $BEER when stock exists)
- User sees a beer item on a marketplace UI
- User sends $BEER (ERC20) to the smart contract
- Contract mints or transfers an NFT to the buyer's wallet
- NFT = redemption voucher for the physical beer item

**What carries over from the ART framework:**
- Marketplace contract structure (ArtMarketplace → BeerMarketplace), UUPS upgradeable
- DEX AMM (Factory / Pair / Router) — still relevant for $BEER price discovery and ETH↔BEER swaps
- Beacon proxy pattern for pairs (all pairs hot-swappable)
- Treasury / fee routing

**Confirmed design decisions (locked 2026-05-11):**
- NFT model: Option A — pre-minted inventory only. Brewer mints NFTs in batches and deposits them into the marketplace contract before sale opens. No lazy minting.
- Redemption: burn on redeem — NFT is burned when redeemed for physical beer. Proves no double-redemption; circulating NFT supply always equals unredeemed stock.

**Full Economic Flow (locked 2026-05-15):**

1. **Brewer stakes ETH → gets $BEER minted** — ETH enters Treasury as permanent floor. $BEER is minted to brewer proportional to stake. Treasury `postStake()` is ETH-payable (redesign from current $BEER stake model).

2. **Brewer buys production NFT with $BEER** — Treasury vends production NFTs for $BEER. Brewer uses freshly minted $BEER to acquire the NFT that represents their physical inventory slot.

3. **Brewer relists NFT on Marketplace for $BEER** — The NFT is their inventory token. Listed price is in $BEER.

4. **Buyer acquires $BEER and purchases NFT** — Buyers get $BEER by buying via DEX with ETH, or by receiving via labor/favor (labor rewards). Buyer spends $BEER to purchase the NFT. $BEER held in Marketplace escrow — NOT sent to brewer immediately.

5. **In-person delivery — redemption** — Brewer presents physical bottle, buyer scans QR code. Buyer's wallet initiates redemption:
   - $BEER burned from escrow — this IS the unlock key for the ETH stake
   - Brewer's ETH stake (pro-rata per NFT) flips to claimable in Treasury
   - NFT marked redeemed
   - `RedemptionRecorded` emitted on HomesteadRelay — ZK-sealed proof on Taiko

6. **Brewer claims ETH** — Claimable, not automatic. ETH sits in Treasury floor until brewer calls `claimStake(batchId)`. Every unclaimed stake strengthens the floor anchor.

**Pro-rata release:** stakedAmount ÷ totalNFTs per redemption. Redeem 3 of 10 bottles = 30% of ETH stake claimable. Remaining stays locked until those bottles are redeemed or slashed.

**Why the burn = unlock:** Neither party can defect without losing something real. Brewer can't claim ETH without buyer burning $BEER. Buyer can't get the physical good without surrendering $BEER. Mutual dependency enforces honesty without trusting either party.

**Deflationary mechanic:** $BEER supply shrinks with every successful real-world delivery. More deliveries = stronger floor (ETH accumulates unclaimed) + scarcer $BEER. Real-world activity directly strengthens the token economy.

**Physical attestation scope:** The chain proves both sides committed and completed. Physical handoff (in-person) requires human trust — cryptographic locks on bottles are out of scope. The economic design makes cheating irrational; physical infrastructure is a separate product.

**ETH enters, $BEER circulates, delivery burns $BEER, ETH flows back.** The whole economy runs on $BEER. ETH is the reserve that backs it.

**Key open design decisions:**
- Pricing: flat 1 BEER per item vs. variable BEER price per SKU
- $BEER minting authority: who can mint, any supply controls

**Why:** Evolving the ART DEX into a real-world backed asset system for a local brewery. Physical beer = backing for $BEER tokens; NFTs are redemption vouchers tied to specific production SKUs.

**How to apply:** Treat all future work in this repo as building toward the $BEER use case, not the original $ART art marketplace.
