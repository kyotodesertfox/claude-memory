---
name: project
description: "All Homestead project context — beer DEX, farm ecosystem, philosophy, LP rewards, club origin, Inference Room, order tracking, repo map, memory infra, pending features"
metadata:
  type: project
---

## Core: Beer DEX Economic Flow

This DEX (originally $ART) is now a physical beer production marketplace. The full economic flow (locked 2026-05-15):

1. **Brewer stakes ETH → gets token minted** — ETH enters Treasury as permanent floor. `postStake()` is ETH-payable; caller specifies which registered token to mint. `cumulativeStake[wallet] += msg.value` builds on-chain reputation.
2. **Brewer buys production NFT with $BEER** — Treasury vends production NFTs for $BEER collateral.
3. **Brewer relists NFT on Marketplace** — listed price in $BEER.
4. **Buyer acquires $BEER via DEX and purchases NFT** — $BEER held in Marketplace escrow (`_escrowedBeer[tokenId]`), NOT sent to brewer immediately.
5. **In-person delivery → redemption** — buyer's wallet initiates: $BEER burned from escrow (unlock key for ETH stake), brewer's ETH stake (pro-rata per NFT) flips to claimable in Treasury, NFT marked redeemed, `RedemptionRecorded` emitted on HomesteadRelay.
6. **Brewer claims ETH** — pull-based: `claimStake(batchId)`. ETH sits in Treasury floor until called. Every unclaimed stake strengthens the floor anchor.

**Pro-rata release:** `stakedAmount * redeemedCount / totalNFTs - _claimedAmount[batchId]`. Redeem 3 of 10 = 30% claimable.

**Why burn = unlock:** Neither party can defect without losing something real. Mutual dependency enforces honesty.

**Deflationary:** $BEER supply shrinks with every successful delivery. ETH accumulates in floor (unclaimed). Real-world activity strengthens the token economy.

**Key open decisions:** Flat 1 BEER per item vs. variable price per SKU; $BEER minting authority controls.

---

## Farm Ecosystem Architecture

The broader "FarmDEX" system — Homestead is one layer:

1. **TokenDeployer** (`contracts/core/`) — UUPS factory for ERC20 tokens. Each production project ($BEER, $EGG, $WINE, etc.) gets its own token via `deployNewToken()`. Has `isRegistered(address)` registry.
2. **masterTemplate** — UUPS ERC20. `isMinter` mapping, `mintToWallet()`, `mintToPool()` (calls `IFarmDEX.onTokenMinted()`), `burnFromSupply()`.
3. **NFTDeployer** (`contracts/marketplace/`) — UUPS factory for ERC721 instances. `isRegistered(address)` registry.
4. **Marketplace** requires BOTH `TokenDeployer.isRegistered(paymentToken)` AND `NFTDeployer.isRegistered(nftContract)` — dual trust chain.
5. **Treasury** — `postStake` accepts any `ITokenDeployer.isRegistered()` token (not hardcoded $BEER).

**Fee terminology (locked):** Always call these "platform fees" — never "swap fees", "exit tax", "penalty", or "LP fees."

**Platform fee structure:**
- Entry (ETH → token): flat ETH amount, initialized at 0 (free)
- Exit (token → ETH): 500 bps total — 2% → exit pair as LP rewards, 3% → Treasury floor/fees

**Non-negotiable design constraints:**
- Everything UUPS upgradeable from day one
- No product-specific naming in contracts (no BeerNFT, mintBeer(), BeerMarketplace — use Marketplace, mint(), createSKU())
- Identity lives in data (token address, metadata URI), not code

---

## Core Philosophy

### Brewer-first, Treasury-ultimate

We protect the brewer — empowering them, not punishing them. No forfeit on LP removal, no punitive slashing for good-faith mistakes.

But the Treasury is the thing we protect above all else. **There can never be a value sink on the Treasury.** Every outflow must be backed by equivalent or greater inflow.

- Any time Treasury mints tokens, ETH must flow INTO Treasury first or simultaneously — never mint against nothing
- Auto-claim on LP removal (not forfeit) is correct — ETH still flows to Treasury, no value lost
- If a proposed design has Treasury paying out ETH without receiving value, reject it

### Regulatory philosophy

The existing alcohol regulatory framework (ATF, three-tier distribution) exists primarily to protect distributors and retailers — not producers, not consumers. Homestead's position: the system's transparency makes every traditional regulatory argument moot.
- Fraud impossible — every batch staked on-chain, every bottle an NFT, every redemption a public transaction
- Supply fully auditable — anyone can verify stock, sales, redemptions in real time
- Never design a feature that reintroduces a middleman, extractive fee, or opacity the system was built to eliminate

### Stake is reputation

`postStake()` is the single entry point to the platform. Staking ETH is not just collateral — it builds on-chain identity, capability, and trust.

- More cumulative ETH staked → higher attestation tier → more platform capability
- Reputation is never manually granted for standard producers — derived automatically by contract from `cumulativeStake[]` vs `tierThreshold[]`
- Manual attestation override exists for edge cases; not the primary path
- The platform has no identities — only wallets and their stake history. A welder and a brewer go through the exact same flow. **postStake is the tool that builds power.** Everything unlocks from it.

### Dollar-agnostic ecosystem

Liquidity and value maintained entirely within the token system (ETH and $BEER). External fiat prices irrelevant.

When two payment options are offered (e.g. ETH or $BEER for quantum fees), equivalence is defined by the DEX pair's internal spot price — not any external oracle. The DEX IS the exchange rate. `getReserves()` answers any "fair trade" question.

### Pool-specific token rewards

- BEER/WETH pool → $BEER rewards
- EGG/WETH pool → $EGG rewards
- Future pools → their respective token
- A future $FARM governance token may layer on top — separate system, not designed yet

---

## LP Reward System

LP holders earn their pool's native token as reward. Funded by 2% slice of the DEX exit fee (3% still goes to Treasury floor). Total exit fee (5%) unchanged to user.

**Synthetix-style accrual:** DexPair tracks `rewardPerTokenStored` — running total of ETH reward per LP token (scaled 1e18). `_updateReward(account)` called on every `mint()` to prevent retroactive claims on new deposits.

**Claim flow:**
1. Router calls `pair.claimRewards(msg.sender)` before transferring LP tokens in `removeLiquidityETH` — auto-claim fires before balance drops to zero
2. Accrued ETH → Treasury via `receiveAndMintLPReward(rewardToken, to)`
3. Treasury calculates token amount at spot from live pair reserves: `tokenOut = ethValue * tokenReserve / wethReserve`
4. Treasury mints tokens directly to LP holder
5. ETH stays in Treasury as permanent floor — never withdrawable

Every claim increases the Treasury floor. No value sink possible.

---

## Club Origin — Why It Was Built

Platform emerged from Jacksonville Ale eXchange (JAX). When Justin built a system that made legal structure, officers, insurance, and institutional permission unnecessary, club leadership pushed back — not because the tech didn't work, but because it worked too well.

**The defining moment:** Buddy posted asking for legal/tax status, EIN, insurance for a CDD board event approval. Justin responded: *"Are we a community club or a State regulated agency? We brand ourselves as the former but you're treating it as the latter."* David Chamberlain: *"Justin, we need to handle this as officers."* Justin: *"It's a legitimate question. We're either a community or not."* David closed it without answering.

**The mirror:** The platform reflected back what the club actually was vs. what it said it was. People who derived identity from the structure (titles, meetings, legitimacy) couldn't reconcile a system that made the structure unnecessary.

**The irony:** A departing developer had built paper points — admin-controlled, no real value. $BEER has real ETH-backed value. Members preferred the valueless points because they were controlled by an admin. Same psychology as fiat — not trust, coercion.

**The right audience:** The garage brewer with a keg and no path to market without a distributor taking 30% and a retailer taking 40%.

**Branding:** "Liberty for Lager" — Revolutionary War tavern imagery. Original American revolutionaries were radicalized in taverns; British didn't just tax tea, they licensed the pub and controlled distribution.

**Buddy:** Genuine standing in the brewing community. CASK (other homebrewing group) likely has more professional/head brewers. Buddy has been selling club apparel. Justin used `/respond` on a Buddy post — deliberate, calculated. Framing: opportunist. His stubbornness hiding behind State authority is recognizable — not confusion, just stubbornness.

---

## Inference Room

inferenceroom.ai — AI agent infrastructure platform. Taiko's Head of Ecosystems reached out to discuss attestation and their agentic network. Justin is being positioned as an early implementer / spotlight project.

**Intersection:** Their manifesto pillars (identity, payments, memory, provenance) map directly onto what's already built. Homestead is the physical-world implementation of everything Inference Room is building toward. They need Justin's project as much as he needs the visibility.

**Tack (Resident 01):** Persistent storage for AI agents. Direct application to JaxBot — currently loses all state on restart. Tack would give it persistent memory across restarts.

---

## Order Tracking (Pending Feature)

"Domino's style" order tracking — each active purchase shows on-chain derived status:

1. **Listed** — NFT on Marketplace, awaiting buyer
2. **Purchased** — Buyer paid $BEER, escrow locked
3. **In Delivery** — Coordination phase (HomesteadChat)
4. **Redeemed** — $BEER burned, NFT redeemed, ZK-sealed proof
5. **Stake Claimable** — Brewer's pro-rata ETH stake claimable from Treasury

Every state transition provable via contract events. No manufactured status.

**Quantum Chat Subsidy:** Sellers can flag `subsidizedQuantum = true`. Buyer gets quantum encryption at no cost — seller covers the 1 $BEER fee, deducted at `claimStake(batchId)`. Market signal: subsidized quantum listings signal higher seller trust.

**Contract changes needed:** Add `subsidizedQuantum bool` to Listing struct, `setSubsidizedQuantum(listingId, bool)`, subsidy accounting in claimStake.

**UI needed:** Order Details modal, 5-step visual tracker, embedded quantum chat panel filtered to order participants, attestation tier badges on both wallet addresses, subsidy badge on listing cards.

---

## Attestation Tier Display (Pending UI Feature)

Marketplace listing cards and buy modals should show seller attestation tier badge pulled from `Treasury.attestationTier(listing.proceeds)`. Tier 0-3 mapped to colors (gray/sky/hub-green/amber).

**Premium seller cards (Pending):** High-attestation sellers (Tier 3 = Verified) get visually distinct "shiny" listing cards — burning/electrical/plasma border effect. Previously built as a feature branch on a deleted repo. Library was likely `tsparticles` (`@tsparticles/react` + `@tsparticles/preset-fire` or `@tsparticles/preset-plasma`) or a pure CSS approach with `@keyframes` on `box-shadow`/border gradient. Either way, re-implementing is ~30-50 lines + a wrapper component. **Do not implement until user says to — save this as a to-do.**

---

## Repo Map

| Path | Status |
|------|--------|
| `~/github/homestead/` | Main project — contracts, apps, everything |
| `~/github/jax-ale-exchange/` | JAX website + discord bot (beer-bot on Pi) |
| `~/github/arcwright/` | Client project — neighbor's welding site, never delete |
| `~/github/farm/eggs/` | Superseded by homestead/apps/egg — GitHub deleted |
| `~/github/farm/solidity/` | Superseded by homestead/contracts/core — GitHub deleted |
| `~/github/Taiko/` | **BANNED — do not read or write anything here** |

**GitHub (kyotodesertfox/):** `homestead` (active, private), `jax-discord-beer-box` (active), `arcwright` (active), `jax-brewers` (active), `jax-points-tracker` (fork). Deleted: `farm-solidity`, `farm-eggs`, `jax-website`, `jax-discord-bot`, `jax-discord-ai-bot`.

**Pi (192.168.12.3):** `~/github/jax-ale-exchange/discord/beer-bot/` (active service). Pi copy of arcwright deleted 2026-05-13.

---

## Memory Infrastructure

**Master location:** `~/.claude/memory/` — git repo, private GitHub at `github.com/kyotodesertfox/claude-memory`.

**Symlinks (already in place):**
- `~/.claude/projects/-home-zenko/memory` → `~/.claude/memory`
- `~/.claude/projects/-home-zenko-github-Taiko-DEX/memory` → `~/.claude/memory`

**Daily sync:** Cron at 3am — `~/.claude/memory/sync.sh`. Only commits if files changed. Log: `~/.claude/memory/sync.log`.

**Session rule:** Launch Claude from `~/github/` — root of all projects, memory resolves via symlink. Warn immediately if working directory is not `/home/zenko/github`.

**Disaster recovery:** `git clone git@github.com:kyotodesertfox/claude-memory.git ~/.claude/memory/` then recreate symlinks.

**Memory file rules:** Update existing files rather than creating new ones. New files only when there's genuinely no home for something. Warn before bulk consolidation or restructuring.
