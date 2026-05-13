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

**Key open design decisions:**
- Pricing: flat 1 BEER per item vs. variable BEER price per SKU
- $BEER minting authority: who can mint, any supply controls
- Redemption auth: who can trigger the burn (NFT holder self-service vs. staff/POS wallet co-sign)

**Why:** Evolving the ART DEX into a real-world backed asset system for a local brewery. Physical beer = backing for $BEER tokens; NFTs are redemption vouchers tied to specific production SKUs.

**How to apply:** Treat all future work in this repo as building toward the $BEER use case, not the original $ART art marketplace.
