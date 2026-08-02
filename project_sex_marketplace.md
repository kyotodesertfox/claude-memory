---
name: project_sex_marketplace
description: "$SEX — adult services marketplace on Homestead infrastructure. Permissionless provider minting, NFT as claim ticket, Chat via Relay, separate frontend from Homestead brand."
metadata:
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

## Status (as of 2026-08-02)

**Parked, not planned.** Started as a joke deploy off Homestead and is unlikely to ship. The local frontend (`~/github/kyotodesertfox/adult-market`, Vite/React, 2 commits, branch `master`) is kept for the data, not because it is queued for work. If it ever does deploy, it deploys *with* Homestead - same chain, same existing contracts, no separate deployment of its own. Do not treat anything below as an active roadmap.

## What It Is

Permissionless adult services marketplace. Two consenting parties, ETH settles it, no central operator in the transaction. Same infrastructure as Homestead — different product, different frontend, different token.

**Why separate from Homestead:** Legal exposure profile is different. Same contracts, separate frontend. No US-domiciled operator. IPFS-hosted eventually; Netlify for initial deployment.

## Design

- **Color scheme:** Pink and white
- **Tone:** Professional but erotic. Adult site — not censored, not over the top. Language is direct, not crude.
- **+18 gate:** Yes — ethical requirement, not federal compliance
- **Branding:** Separate from Homestead entirely

## Token & Contracts

**New deploys needed:**
- `$SEX` token — deploy via TokenDeployer (same masterTemplate)
- `$SEX NFT` collection — nftTemplate with `permissionlessMint = true`
- SEX/WETH pair — create via DEXFactory after token deploy
- New Router UUPS proxy (already pending)

**Existing contracts used** (all Taiko mainnet, chainId 167000 - same deployments as Homestead, see [[project-contracts]]):
- Marketplace (`0x2321bDF62364ee38Fcf6b631C9742f6BF61B66Aa`) — listing, buy, redeem
- HomesteadRelay (`0x96FC77220d578aF5D4380Dc2D2248Ed31444C491`) — Chat
- Treasury (`0x631f9D082019E25a2BfD219BF235cA0b742206EC`) — fee policy, attestation tiers
- DEXFactory (`0xC72096f120cBb6a8f9e942864b885e1bb5060Cf2`) — pair creation
- TokenEscrow — OTC large token deals (pending deploy)

## Contract Upgrades Required Before Launch

1. **nftTemplate beacon upgrade** — add `permissionlessMint` flag + `setPermissionlessMint(bool)` onlyOwner. Guard: `require(permissionlessMint || isMinter[msg.sender])`. Affects all collections via beacon — existing collections default to `false`, no behavior change.

2. **Marketplace upgrade** — add permissionless listing path. Currently non-owners require `batchId > 0` from Treasury. Need: if NFT contract has `permissionlessMint() == true`, skip batchId/Treasury validation. Add `IPermissionlessCheck { function permissionlessMint() external view returns (bool); }` interface check in `createListing`.

3. **TokenEscrow** — add missing `IProductionToken` interface (`mintExact(address, uint256)`) to `Interfaces.sol` or inline. Not blocking for launch but needed before OTC deals.

## Provider Flow

1. Connect wallet
2. Mint NFTs into $SEX collection (permissionless — no owner approval needed)
3. `createListing(nftContract, $SEX, price, batchId=0)` — permissionless path (post-Marketplace upgrade)
4. `depositInventory(listingId, tokenIds[])` — NFTs into custody
5. Register encryption key on Relay (`registerKey`)
6. Receive buyer messages via Chat, confirm delivery
7. NFT redemption → buyer burns escrowed tokens, provider receives ETH via Router swap

## Buyer Flow

1. +18 gate on entry
2. Connect wallet
3. Swap ETH → $SEX on DEX (or buy directly if entry fee enabled)
4. Browse listings
5. `buy(listingId)` — pays $SEX, receives NFT
6. Chat with provider via Relay (`sendDeliveryMessage` tied to NFT context)
7. `redeem(nftContract, tokenId, minProducerEth)` — confirms delivery, provider paid

## Chat (Relay)

Relay is labeled "Chat" in the UI. Key points:
- End-to-end encrypted — messages stored on-chain as events, encrypted payload only
- Both parties must `registerKey` (X25519 + optional Kyber-768 for quantum-ready)
- `sendDeliveryMessage` — buyer sends tied to specific NFT (can be subsidized by provider)
- `sendMessage` — general encrypted 1:1
- Fee: ETH path (goes to Treasury) or $BEER burn path; plaintext messages free if `ethFeePlainText = 0`
- Provider sets `quantumFreeRecipient` = buyer to cover their messaging costs (subsidy model)

## UI Pages

1. **Landing** — +18 gate, brief value prop, connect wallet CTA
2. **Browse** — listing grid, filter by category/price/availability
3. **Listing Detail** — NFT preview, price, provider profile, Buy button, Chat button
4. **Provider Dashboard** — mint NFTs, manage listings, view earnings, Chat inbox
5. **Swap** — ETH → $SEX, shows price, slippage, fee schedule from Router
6. **Chat** — Relay interface, conversation threads per NFT context
7. **Profile** — wallet, NFT holdings, redemption history

## Pending Design Decisions

- Site name / domain
- Whether provider staking (via Treasury vouching) is required at launch or optional
- Category/tagging system for listings (on-chain vs off-chain metadata in CIDs)
- Whether `depositAndSync` on SEX/WETH pair is restricted to owner (yes — lock it down)

## Deployment

- **Initial:** Netlify
- **Target:** IPFS (no centralized operator, no domain to seize)
- **Wallet for deployment:** Same Homestead deployer — required by Treasury hierarchy (TokenDeployer, NFTDeployer, Marketplace, DEXFactory all owner-gated). Anonymity is in the frontend hosting, not the contracts.
- **Frontend repo:** Separate from `homestead` repo
