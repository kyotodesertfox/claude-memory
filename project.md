---
name: project
description: "All Homestead project context — beer DEX, farm ecosystem, philosophy, LP rewards, club origin, Inference Room, order tracking, repo map, memory infra, pending features"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4d10e6c7-3013-43a7-b1f4-1cad366cf7fd
---

## Core: Beer DEX Economic Flow

This DEX (originally $ART) is now a physical beer production marketplace. The full economic flow (locked 2026-05-15):

1. **Producer stakes ETH → gets stkHomestead 1:1** — `postStake()` takes no args, just ETH. Mints stkHomestead via mintExact (base units). `cumulativeStake[wallet] += msg.value` builds reputation. stkHomestead is collateral credential, never burned (except in claimStake pro-rata). **Flow is now separate**: postStake → openLot(token, amount) → approve → mintLotNFTs.
2. **Brewer buys production NFT with $BEER** — Treasury vends production NFTs for $BEER collateral.
3. **Brewer relists NFT on Marketplace** — listed price in $BEER.
4. **Buyer acquires $BEER via DEX and purchases NFT** — $BEER held in Marketplace escrow (`_escrowedBeer[tokenId]`), NOT sent to brewer immediately.
5. **In-person delivery → redemption** — buyer's wallet initiates: $BEER burned from escrow (unlock key for ETH stake), brewer's ETH stake (pro-rata per NFT) flips to claimable in Treasury, NFT marked redeemed, `RedemptionRecorded` emitted on HomesteadRelay.
6. **Brewer claims ETH** — pull-based: `claimStake(batchId)`. ETH sits in Treasury floor until called. Every unclaimed stake strengthens the floor anchor.

**Pro-rata release:** `stakedAmount * redeemedCount / totalNFTs - _claimedAmount[batchId]`. Redeem 3 of 10 = 30% claimable.

**Why burn = unlock:** Neither party can defect without losing something real. Mutual dependency enforces honesty.

**Deflationary:** $BEER supply shrinks with every successful delivery. ETH accumulates in floor (unclaimed). Real-world activity strengthens the token economy.

**Key open decisions:** $BEER minting authority controls. Variable pricing is resolved — Marketplace `createListing` accepts any uint256 `price` (stored as `price * 1e18`), so 1/6/12 EGG tiers are a UI-only change.

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

### Component Failure Priority — The Relay Dilemma

**The dilemma:** `Marketplace.redeem()` must call both Treasury (economic settlement) and HomesteadRelay (attestation/provenance). If both are atomic and Relay fails, the $BEER burn and stake release are blocked — Treasury and producer are harmed by a broken attestation layer. If Relay is best-effort, the economic settlement always completes but provenance may have a gap.

**The resolution:** Economic settlement is the critical path. Attestation is the provenance layer. A component failure in attestation must NEVER revert irreversible economic operations. Priority order is locked:

1. **Treasury** — burn and onRedeem complete atomically, or nothing does
2. **Producer** — stake unlocks when settlement completes; they can make buyer whole if attestation fails
3. **Relay** — best-effort, wrapped so its failure cannot revert the parent transaction

**The reasoning:** If Relay had veto power over settlement, a buggy or unset Relay would hold ALL redemptions hostage — directly violating "Treasury above all." Conversely, firing economic consequences from inside the Relay (inverted call order) is dangerous: you'd be triggering irreversible operations without guaranteeing the full chain completes.

**The rule derived from this:** Any ancillary component (Relay, future oracle, future subsidy system) that sits downstream of a Treasury operation must be called best-effort. No secondary system gets veto power over the economic layer. The producer is the human backstop for buyer-facing failures.

### Physical Redemption — The Barcode Problem

**The problem:** Physical goods like eggs or handcrafted items cannot carry a scannable barcode. The system cannot force buyers to call `Marketplace.redeem()` after receiving goods. If they never redeem, the brewer's ETH stake stays locked in Treasury permanently. This looks like a design gap but is actually coherent.

**The resolution:** The QR code at point of physical exchange is not a product identifier — it is a deep link to `Marketplace.redeem(tokenId)`. When the buyer scans it and confirms in their wallet, that signature IS the co-presence proof. Both escrows resolve atomically at that moment:

1. Buyer's $BEER burned from Marketplace escrow (delivery confirmed)
2. Brewer's ETH stake in Treasury flips to claimable (unlock key received)
3. Relay records the attestation on top (best-effort provenance)

Nothing freezes in the intended flow because the buyer's wallet signature at the moment of handoff IS the redemption. The QR is a UX bridge, not a barcode.

**`markRedeemed()` — the honest penalty:** Owner-only bypass for genuine edge cases (dead phone, buyer refuses to scan). The brewer's ETH stake stays permanently locked if they use it — that IS the penalty for not completing the loop. It is self-punishing by design. A dishonest brewer who marks delivery without delivering also freezes their own stake. Mutual dependency enforces honesty; the contract cannot force it.

**The rule derived from this:** The system's job is to eliminate as many vectors for dishonesty as possible, not to eliminate trust entirely. Some level of honesty will always be required at the edges. Build the incentive structure so that dishonesty is costly to the dishonest party — then accept the residual.

### $FARM Governance Token — Design Philosophy

$FARM is the platform's governance token. It is not an inventory token (that's $BEER) and not a reserve currency (that's ETH). It represents governance weight — the right to influence platform direction.

**Emission sources (ETH-backed, clean under Treasury rule):**
- `postStake` — when a producer stakes ETH, $FARM mints proportional to ETH staked alongside $BEER
- LP reward claim — when an LP holder claims rewards, $FARM mints alongside the pool's native token

**Burn sink:** Quantum messaging fees. Active platform communication burns $FARM, creating equilibrium between emission (participation) and burn (usage).

**No hard cap — ever.** Continuous emission tied to active participation. This is non-negotiable.

**Why:** Concentration of governance power leads to hostile takeover. A hard cap rewards early participants permanently — they accumulate governance weight and eventually dominate the platform regardless of current participation. The JAX club is the lived example: power concentrated among officers who used it to resist the very system that made them unnecessary. The platform must never recreate that dynamic on-chain.

**The anti-concentration mechanism:** Continuous emission dilutes inactive holders. A whale who stops staking and stops providing liquidity gets continuously diluted as new $FARM flows to active participants. The burn sink accelerates this — a large holder who uses the platform burns their own supply. No punitive mechanism needed; the math does it.

**Open design question:** Raw $FARM balance vs. time-weighted snapshot for voting power. Time-weighted (voting power = $FARM earned in last N days) is the strongest anti-concentration design but complex to implement. Continuous emission with no cap achieves most of the same effect through dilution alone. Decision deferred.

**$BEER is NOT a utility/fee token.** It is an inventory token backing real physical assets. Using it as a platform fee currency conflates commodity claims with platform utility. Quantum messaging fees should not burn $BEER.

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

## Order Tracking (BUILT)

"Domino's style" order tracking — each active purchase shows on-chain derived status:

1. **Listed** — NFT on Marketplace, awaiting buyer
2. **Purchased** — Buyer paid $BEER, escrow locked
3. **In Delivery** — Coordination phase (HomesteadRelay messages)
4. **Redeemed** — $BEER burned, NFT redeemed, attestation recorded
5. **Stake Claimable** — Brewer's pro-rata ETH stake claimable from Treasury

**UI location:** `apps/exchange/src/components/OrderTrackingModal.jsx` — modal with 5-step horizontal progress tracker, animated progress bar, order detail panel (price, seller, listing#, batch#), "Confirm Delivery" button (calls `Marketplace.redeem`).

**Wired via `MyOrdersSection`** in `apps/exchange/src/pages/profile/Page.jsx` — reads wallet's NFTs via `balanceOf` + `tokenOfOwnerByIndex`, batches `getTokenListing` calls, filters to marketplace purchases only, shows `OrderCard` grid. Click → `OrderTrackingModal`.

**Step derivation logic (on-chain, no manufactured status):**
- `!hasListing` → step 1 (in wallet, never sold via marketplace)
- `hasListing && !redeemed` → step 3 (purchased → in delivery)
- `redeemed && claimable > 0n` → step 5 (stake claimable)
- `redeemed && claimable == 0n` → step 4 (redeemed, stake already claimed or no batch)
- Step 2 (Purchased) is not yet derivable on-chain without a `purchased` event filter — currently skipped

**Quantum Chat Subsidy (BUILT — design changed from original plan):** Seller specifies `subsidyCount` when calling `Marketplace.createListing()`. Marketplace collects `subsidyCount * relay.quantumFee()` $FARM upfront at listing creation. Per message: Relay calls `Marketplace.chargeSubsidy(nftContract, tokenId, fee)` — burns $FARM from listing's balance. If balance is exhausted, sender pays normally. Unused $FARM auto-returned to seller on `setActive(false)`. Seller can also manually reclaim via `reclaimSubsidy(listingId)`.

**Original design (discarded):** `subsidizedQuantum bool` in Listing struct, deducted from ETH stake at claimStake. Not implemented — replaced with pre-paid $FARM session model which avoids per-message gas overhead and per-redemption accounting complexity.

---

## Branch Status (2026-05-28)

- `main` — current production branch. Latest commit `cff3d55` (2026-05-28). Recent additions: EGG token/NFT/pair wired into contracts + env + admin + market + swap + home pages; CreateListingModal supports BEER|EGG collection picker with collection-specific metadata fields; tanned SVG egg placeholder cards on market + home pages; EGG swap fully live with correct `wethIsToken0` reserve ordering.

## Swap Page State (2026-05-27)

All fee values read live from Treasury contracts at `ADDRESSES.TREASURY`. No hardcoded defaults.
- `dexEntryFeeBps` — read but not yet surfaced in UI (entry fee currently 0, shown when Router redeployed)
- `dexExitFeeBps` — shown as "Treasury Fee" row in trade info panel (Token→ETH only)
- `lpRewardFeeBps` — not yet surfaced separately (LP reward split pending coordinated upgrade)
- AMM fee: `const AMM_FEE_BPS = 30n` — named constant matching `HomesteadLibrary 9970/10000`. TODO: replace with `getFeeSchedule()` call after Router UUPS is deployed
- Swap UI has 0/25/50/75/Max ETH buttons (always visible under ETH input), BUY/SELL colored emerald/rose, RECEIVE green, PAY red

## Portal Tokens (2026-05-28)

Three tokens in swap page selector:
- `$BEER` — live (address set in contracts.js)
- `$EGG` — **live** (yellow dot, wired to EGG_TOKEN + EGG_WETH_PAIR; `wethIsToken0: true` because WETH address sorts below EGG address in that pair)
- `$SPA` — coming soon (purple, null address)

## Strategic Pause

Development intentionally paused as of 2026-05-24. No new features until real user activity warrants them. Router UUPS source is written (`contracts/dex/Router.sol`) but not yet deployed. See `project_contracts.md` for deploy instructions.

---

## Pending Tasks

| # | Task | Notes |
|---|------|-------|
| 1 | Fix NFT metadata spelling error | Use `setTokenCID(tokenId, newCID)` on nftTemplate — user will provide tokenId when ready |
| 2 | Transfer ownership of all deployed contracts | Treasury, Marketplace, nftTemplate instances, TokenDeployer, NFTDeployer, DEXFactory, HomesteadRelay (after deploy) |
| 3 | ~~Build generic producer onboarding wizard~~ | **DONE** — `OnboardingWizard.jsx`, multi-step, floor-stake path for first-timers |
| 4 | Deploy contracts — phased rollout | Phase 0 (upgrade existing), Phase 1 (staking live), Phase 2 ($FARM + emission), Phase 3 (HomesteadRelay). See project_contracts.md. |
| 5 | ~~Seller reputation badges on marketplace listing cards~~ | **DONE** — `ReputationBadge` component in `market/Page.jsx`; reads `Treasury.attestationTier(listing.proceeds)`; labeled "Reputation" (not "Attestation"); tier 0 = no badge, 1 = Holder (sky), 2 = Producer (green), 3 = Trusted (amber) |
| 6 | Shiny cards for high-attestation sellers (Tier 3) | Burning/electrical border effect — likely tsparticles or pure CSS @keyframes. ~30-50 lines + wrapper component. Do not implement until user says to. |
| 7 | ~~Order tracking UI~~ | **DONE** — `OrderTrackingModal.jsx` + `MyOrdersSection` wired in profile page |
| 8 | ~~Wire "Post More Stake" button in StakePanel~~ | **DONE** — opens OnboardingWizard with `skipInitial` |
| 9 | ~~Deploy $stkHomestead stake pool token~~ | **DEFERRED — Phase 4** (mint mechanics TBD; key question: receipt token minted on postStake, burned on claimStake?) |
| 10 | ~~Mobile modal responsiveness~~ | **DONE** — `overflow-x-hidden` on layout root; wallet card Address full-width, ETH/Stake in `grid-cols-2`; HomesteadChat FAB now full-screen on mobile (`fixed inset-0 sm:inset-auto`); Disconnect moved from header to wallet card as text link (red, `text-xs`); chain name colored to match chain dot (emerald/amber) |
| 11 | ~~Live staking position cards~~ | **DONE** — `StakingPositionCards` in profile staking tab; reads `cumulativeStake` (ETH Staked) + batch enumeration for claimable ETH; Claim button fires `claimStake(batchId)` |
| 12 | Manual attestation override on Treasury | Add `attestationOverride` mapping + `setAttestationOverride(address, uint8)` onlyOwner + check override first in `attestationTier()`. Shrink `__gap` by 1. Also add ABI entries to contracts.js and optionally an admin UI call. For trusted providers onboarded via `mintToWallet()` who have no stake. Small upgrade, defer until next Treasury deploy. |
| 13 | Deploy 3 EGG NFT tier contracts | Single Egg (1 EGG), Half Dozen (6 EGG), Dozen (12 EGG) — each a separate NFT contract deployed via nftDeployer with its own artwork and marketplace listing. Pricing is UI-only (pass 1/6/12 as price arg). CreateListingModal collection picker will need to support all three tiers. |

---

## Producer Onboarding Wizard (BUILT — Task #3)

`apps/exchange/src/components/OnboardingWizard.jsx`. Generic multi-step flow for any producer. No identities — only wallets. Keith Wright (welder) goes through the exact same flow as a brewer. Copy is product-agnostic.

**Steps (step index in component):**
- `-1` — Floor stake only (first-timers with no token yet): calls `postStake(ZERO, ZERO, [], 0n)` with ETH
- `0` — Select token (from TokenDeployer registry)
- `1` — Select NFT collection (from NFTDeployer registry)
- `2` — Batch details (CIDs, tokenToEmit)
- `3` — Post stake: `postStake(token, nft, cids[], parseEther(tokenToEmit))`
- `4` — Create listing: `Marketplace.createListing(nft, token, parseEther(price), batchId)`
- `5` — Done

**Re-entry:** "Post More Stake" in StakePanel opens wizard with `skipInitial` (skips floor-stake step).

**Treasury change:** `postStake` now accepts `address(0)` for both `token` and `nftContract` — floor-only stake for first-timers who haven't deployed a token yet. `cumulativeStake` always increments regardless.

## Mint $BEER — Admin Panel

Direct `mintToWallet`/`mintToPool` is an **admin-only** feature (gated by `isMinter` role), NOT the canonical producer mint path. Canonical minting is via `postStake` (collateralized).

**Location:** `$BEER Portfolio` modal → Staking tab → bottom section (amber color, "Admin" badge).

**Destinations:** Self (connected wallet) / Wallet (custom `0x` address input, for favors/labor) / Pool (BEER/WETH pair). Wallet destination validates address format before enabling Mint button.

---

## Attestation Tier Display (BUILT)

`ReputationBadge` component in `apps/exchange/src/pages/market/Page.jsx`. Reads `Treasury.attestationTier(listing.proceeds)` (proceeds = index 3 of listing tuple = seller address). Labeled "Reputation" in UI (never "Attestation"). Tier 0 = no badge shown. Tier 1 = Holder (sky blue). Tier 2 = Producer (hub-green). Tier 3 = Trusted (amber). Badge shown on both listing card body and listing modal header (alongside seller address).

**Premium seller cards (Pending):** High-attestation sellers (Tier 3 = Trusted) get visually distinct "shiny" listing cards — burning/electrical/plasma border effect. Previously built as a feature branch on a deleted repo. Library was likely `tsparticles` (`@tsparticles/react` + `@tsparticles/preset-fire` or `@tsparticles/preset-plasma`) or a pure CSS approach with `@keyframes` on `box-shadow`/border gradient. Either way, re-implementing is ~30-50 lines + a wrapper component. **Do not implement until user says to — save this as a to-do.**

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

**Pi (192.168.12.3):** `~/github/jax-ale-exchange/discord/beer-bot/` (was active service — JAX Discord server is now dead, group disbanded 2026-05-24). Pi being phased out — primary development has moved to laptop. Pi no longer the primary deployment target.

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
