---
name: project_order_tracking
description: Order tracking UI and quantum chat subsidy model for Marketplace listings
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

## Order Tracking — "Domino's Style"

Each active purchase has an Order Details view showing on-chain derived status:

1. **Listed** — NFT on Marketplace, awaiting buyer
2. **Purchased** — Buyer paid $BEER, escrow locked in Marketplace
3. **In Delivery** — Coordination phase (both parties using HomesteadChat)
4. **Redeemed** — $BEER burned, NFT redeemed, ZK-sealed proof on Taiko
5. **Stake Claimable** — Brewer's pro-rata ETH stake is claimable from Treasury

Every state transition is on-chain provable via contract events. No manufactured status.

## Quantum Chat Subsidy

Sellers can flag a listing as `subsidizedQuantum = true`. When set:
- Buyer gets quantum encryption on order chat at no cost to them
- Seller covers the 1 $BEER quantum fee — deducted from their ETH earnings at claim time

**Subsidy accounting:**
- Treasury collects the $BEER fee as normal — always whole
- Accumulated subsidy fees are tracked per batch
- When brewer calls `claimStake(batchId)`, subsidy total is deducted from their ETH payout
- Brewer nets slightly less ETH per redemption — their business decision, their cost

**Market signal:** Subsidized quantum listings signal higher seller trust. Buyers learn to read this as a quality indicator. Behavior-as-attestation without formal attestation system. Sellers absorb the cost voluntarily as a customer service investment.

## Contract Changes Needed

- Add `subsidizedQuantum bool` to Marketplace `Listing` struct
- Add `setSubsidizedQuantum(uint256 listingId, bool value)` — listing owner only
- HomesteadRelay quantum fee logic: if `subsidizedQuantum`, deduct from seller's escrowed $BEER or charge seller separately

## UI Needed

- Order Details view (modal or page) accessible from portfolio/NFT card
- Visual step tracker (5 states above)
- Embedded quantum chat panel filtered to this order's participants (buyer ↔ seller)
- Both wallet addresses shown with attestation tier badges
- Subsidy badge on listing cards — visual trust signal for buyers

**Why:** [[project_beer_dex]] — completes the customer experience layer on top of the escrow/redemption flow.
