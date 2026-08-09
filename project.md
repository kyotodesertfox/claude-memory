Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

---
name: project
description: "All Homestead project context — beer DEX, farm ecosystem, philosophy, LP rewards, club origin, Inference Room, order tracking, repo map, memory infra, pending features"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4d10e6c7-3013-43a7-b1f4-1cad366cf7fd
  modified: 2026-08-07T01:51:11.452Z
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

**Tokenomics model (updated 2026-06-04):**
- Token supply only grows when a producer actively mints against their stake. Minting is capped by collateral ratio — supply can never run ahead of the ETH backing it.
- Per redemption: buyer's escrowed tokens BURNED (deflationary, ~50% of tokens touched). Producer's tokenPerNFT (held by Treasury from mintLotNFTs) transferred to Marketplace → swapped into LP → ETH to producer. Net supply: decreasing — only the buyer's half burns; producer's half recycles into LP.
- Token is deflationary at scale: every completed sale removes buyer's tokens permanently. LP absorbs producer's tokens but total circulating supply trends down with redemption volume.
- Token value appreciates via floor rising AND supply reduction on each sale. Each redemption burns buyer's tokens and captures exit fee ETH into LP and Treasury.
- Idle supply self-corrects: abandoned lots lock producer's staked ETH as a carrying cost. `burnLotTokens` is the cleanup path.
- Token is NOT speculative — it is production-backed. 1 $EGG = 1 carton. Value comes from real delivery, not market sentiment.
- Tokenomics are not featured on the front page — discoverable for those who want the mechanics, not the headline. Wrong audience if leading with AMM math.

**ETH flow (revised design 2026-06-04):**
- Buyer swaps ETH → tokens via LP. ETH enters LP.
- Buyer calls `buy()` — tokens escrowed in Marketplace (`_escrowedTokens[tokenId]`). NFT transfers to buyer.
- Physical delivery → buyer calls `redeem()`:
  1. Marketplace **burns buyer's escrowed tokens** — deflationary, tokens gone permanently
  2. Marketplace calls `Treasury.onRedeem(batchId)` → Treasury transfers producer's `tokenPerNFT` tokens to Marketplace (NOT burned — these are the tokens Treasury held from `mintLotNFTs`)
  3. Marketplace swaps producer's tokens → ETH via Router → sent directly to producer's `proceeds` address
  4. Treasury marks pro-rata collateral claimable
  5. Relay best-effort attestation
- Producer's staked ETH in Treasury is NEVER the direct payment source — it is reputation collateral, claimable separately via `claimStake()` after redemptions
- ~50% burn per sale: buyer's tokens destroyed, producer's tokens recycled through LP to fund ETH payment
- LP floor always ratchets up: AMM 0.3% fee captured on both swap legs + exit fee split (LP rewards + Treasury)

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

### Political identity (crystallized 2026-06-10)

"I am not political. I am productive."

Pre-political — identified a structural problem and started building before asking anyone's permission or picking a team. Not libertarian (libertarians stop at critique and wait for markets to self-correct). Justin builds the missing infrastructure. Political classifications are for people arguing about how to manage the existing system. He is not managing it — he is routing around it.

---

### "Everyone wants the view. Nobody wants the climb." (2026-06-10)

Justin's line describing the cold-start problem in human form. Everyone wants to be early. Nobody wants to be first. Keith Wright (welder) understands the platform can go big, understands institutions rob people, actively thinks about advertising and outreach — but won't be first through the door. His comment to Justin ("if you don't personally believe in it, no one will") was identified as projection — naming his own barrier, not Justin's.

---

### Capital axis problem — household scale (2026-06-10)

Katie holds fiat capital (earns reliably via employment) but has no productive direction for it. Justin has direction and the build but no capital. This is the same structural problem Homestead solves for producers — the person with the capital doesn't know what to do with it; the person who knows what to do with it doesn't have it.

Justin is living the problem he is solving.

---

### Homebrew group — final state (2026-06-10)

Discord server fully empty. Justin posted the whitepaper and the "social experiment" framing in #beer-pix on 2026-06-09. Final message: "I built what I promised that I would & those it would threaten most [displacement = direct buying = correct flow of capital; not hostility] have left."

David Chamberlan (brewery's social media guy) left first — the person whose entire value is narrative control and institutional reputation management. Retirees/pensioners also among the first to go. The selection was unconscious but coherent: the people most dependent on existing intermediary structures self-selected out before a single transaction occurred.

They saw "crypto + NFTs" and left. They didn't read far enough to see the physical-world redemption model. The whitepaper leads with "Grown here. Sold here." — meets people before the technical layer.

---

### Platform as social experiment / mirror (2026-06-08)

Homestead is not just a marketplace — it's a mirror. Every interaction reveals something about how people relate to trust, permission, and institutions.

**What the experiment has shown so far:**
- People who dismiss it without engaging are revealing threat responses, not genuine disinterest
- The laugh-and-leave response in JAX Discord was a coordinated social move — Ward framed it as a values issue before anyone could think about it too long; the rest took their cue
- People engage right up until the moment real participation is required — then silence
- "I'm broke" is the most convenient unanswerable exit from a conversation that got too real
- People refuse to use the platform because they don't like the builder — they call this distrust, but it's actually the atrophy of genuine trust evaluation after decades of outsourcing trust to institutions

**The deepest insight:** Institutions have trained people to trust liability structures, compliance regimes, and dispute teams — not other humans or systems on their own merits. When presented with a trustless system, people reach for their feelings about the builder as the only trust signal they have left. They're not evaluating whether the contracts are sound. They're asking whether they like the person.

**The platform's hardest barrier isn't technical.** It's that full participation requires people to remember how to think for themselves.

**The stake as filter:** Producers who won't stake are telling you something important about themselves before they ever list. The ones who will are confident enough in what they make to back it with real capital. The friction is the feature — it selects for the right producers and filters out the ones the platform was never designed for.

**Capital as permission:** The stake requirement is itself a permission structure — just the most neutral one available. ETH doesn't know who you are. Ward's approval was subjective and political. But both are gates. The vouching system was designed to address this without replacing an objective gate with a subjective one.

### ETH concentration vulnerability (2026-06-08)

Institutions accumulated ETH using printed dollars (leverage on nothing). This means the entry token for a system designed to remove institutional gatekeepers is an asset they disproportionately own. If they hold majority ETH supply, accessing the platform still routes through them — one step removed.

This is the colonization playbook: a new system emerges, institutions absorb it by buying the scarce asset with printed money before most people understand what they're looking at. The rails change but the tollbooth stays.

ETH is still the least bad option currently available. The vulnerability is real but the alternative (dollar dependency) is worse. The circular economy — where participants spend ETH directly within the ecosystem and never need to off-ramp — is the long-term answer. That becomes viable only when people's debt obligations no longer require dollars. Debt is the mechanism keeping people inside the dollar system; it is not accidental.

### The relay and the quantum threat (2026-06-08)

The quantum-resistant messaging relay exists for a reason beyond feature completeness. Justin posted publicly in 2024 foreshadowing this: the distribution layer (X/Twitter and similar platforms) retains all communications. When quantum computing is publicly announced as a real threat, those retained records become readable. The platform will say "we didn't do this — quantum computing did it." The technology becomes the villain; the institution walks away clean.

The relay is the answer to the question people will desperately ask that day: "is there any way to communicate that they can't read?" Peer-to-peer, quantum-resistant, no central server retaining records, no database waiting to be unlocked. Built before the problem was publicly acknowledged.

The suppression of posts about this is itself evidence. Early truth — naming the mechanism before it's deployed — is the most dangerous kind because it gives people time to build alternatives.

### Dollar-agnostic ecosystem

Liquidity and value maintained entirely within the token system (ETH and production tokens). External fiat prices irrelevant.

**No USDC path. Ever. By design.** USDC, USDT, and all dollar-pegged stablecoins are deliberately excluded from every contract and UI path. This is not an oversight — it is a foundational architectural decision. USDC has a freeze function controlled by Circle. Any protocol that routes through USDC has a kill switch it does not control. Homestead removes that dependency entirely.

ETH in, ETH out, production tokens in between. The entire system denominates in assets that cannot be frozen by a compliance team, seized by a regulator, or depegged by an issuer. This is the same reason VC capital was never taken — the moment a dollar enters, the incentives of whoever controls the dollar enter with it.

When two payment options are offered (e.g. ETH or production token for quantum fees), equivalence is defined by the DEX pair's internal spot price — not any external oracle. The DEX IS the exchange rate. `getReserves()` answers any "fair trade" question.

### Pool-specific token rewards

- BEER/WETH pool → $BEER rewards
- EGG/WETH pool → $EGG rewards
- Future pools → their respective token
- A future $FARM governance token may layer on top — separate system, not designed yet

---

## Front-Page Copy Standard

The exchange front page (`apps/exchange/src/pages/home/Page.jsx`) uses a deliberately different register than the whitepaper. Two audiences, two voices - on purpose. Do not de-jargon the whitepaper.

**Front page** - normie/farmers-market audience. Lead with barter. Everyone understands it and it triggers no crypto reflex. Homestead is "a highly advanced barter system."

**Vocabulary rules (front page only):**
- "pledge" = the ETH staking/collateral mechanic. Never say "stake ETH" or "collateral" on the front page. The pledge is held, never spent, returned on delivery - a handshake substitute that lets a stranger trust you.
- ETH is "ETH" only. Never "coin" or "token." When referencing the staking mechanic, use "pledge."
- token = money (the currency of the circle). NFT = the claim ticket bought with tokens and redeemed for the physical good. Keep this distinction explicit.
- Use "producer" terms, not "farm" - inclusive of farmer or homesteader. Generic archetypes (farmer / brewer / welder) are fine.

**No dollar anchoring on the front page.** Dollars are the currency Homestead is exiting. A store-price-vs-token-price comparison trains people to keep valuing in dollars and caps producer pricing. Homestead sells quality - better goods price up, not down. Express value in production terms, not USD.

**The loyalty-card band** ("Why the money holds" section, added 2026-07-06): a loyalty card is worth something until the business folds, and cash is the same thing. Homestead tokens are backed by real goods - the worth cannot fold with anyone. Never say "government" - the metaphor carries the load without naming an enemy. Exact headline: *"Loyalty point value holds until a business folds; cash is just loyalty points from a bigger card."* This is a deliberate filter for economically-literate early adopters, not broad appeal.

**State how, not just that.** Back value claims with verifiability - the backing is recorded on a public ledger anyone can check. Never bare assertion.

**Removed 2026-07-06 - do not rebuild:** PriceEvidenceCard, DealCreditBanner, the PRICE_EVIDENCE contract. That contract was never built or deployed. The game also optimized toward cheapest commodity price - the worst anchor for a quality producer.

**stkHomestead language:** Believed soulbound/non-transferable - use "stays with you" (permanence), never "travels with you" or "portable." Verify against contract before asserting in code.

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

## Homestead Companion (Android Wallet App)

**Location:** `apps/HomesteadCompanion/` inside the homestead repo

**Purpose:** Purpose-built Android wallet for the Homestead ecosystem. Not a general-purpose wallet. Distributed as a sideloaded APK from the website. Built with React Native (same JS/JSX as exchange frontend, different native UI layer).

**App name:** Homestead Companion

**Core lib layer built (`src/lib/`):**
- `network.js` - Taiko mainnet RPC provider (chainId 167000)
- `storage.js` - encrypted private key storage via react-native-encrypted-storage (Android Keystore backed)
- `wallet.js` - wallet creation (`createWallet` returns mnemonic ONCE, never stored), import from seed phrase, `getWallet()` for signed transactions
- `contracts.js` - ABIs and ADDRESSES (addresses need filling from exchange .env.local); `readContract` / `writeContract` helpers

**Screen map (approved):** Onboarding, Home (balances), Send/Receive, Market, Redeem (QR scan), Settings

**Key design decisions:**
- Mnemonic shown once on creation, never saved by the app - user's responsibility
- Private key stored encrypted on device (Android Keystore)
- Taiko only - no other chains
- May connect to HomesteadRelay for redemption attestation - keep relay integration in mind when building QR/redeem flow
- Auto-update: app checks version endpoint, downloads new APK, prompts install

**Build environment:** JDK 17, Android SDK 34, adb installed. ANDROID_HOME set in ~/.bashrc.

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

## Bootstrap Status (2026-07-14)

Platform is technically complete. The cold start problem is the only blocker - no liquidity, no first node, no translation layer. Human element hasn't caught up yet.

**Discord server shut down** a few days before 2026-07-14. Justin drew the parallel to Loopring's shutdown explicitly - same signal, different scale. Not permanent necessarily, but carrying it alone wasn't sustainable.

**Identities:** `lonewolf_eth` is the proxy identity (the operator behind the work). `@HomesteadXC` is the platform identity. Both are on X. X has been suppressing posts that are honest/damning while leaving friction visible - consistent with the pattern of visibility as a managed policy decision.

**Keith Wright (welder) context - 2026-07-14:** Justin identified why Keith is resistant to the platform. He is Native American. His people already had sovereign currency, governance, and land - all of it destroyed by the same institutional force Justin is building around. He doesn't distrust the mechanism. He distrusts the outcome based on generational history. He sees what Justin is doing but can't be a first node. May be meaningful later when proof exists. Currently just a honey customer.

**GME exit reason (clarified 2026-07-14):** Justin sold his GME/BTC stack on principle, not panic. Two simultaneous signals: (1) CSAM (child abuse material) being stored as BLOB data on the Bitcoin chain - holding the stack meant holding infrastructure carrying that content. (2) MicroStrategy/institutional BTC acquisition read as elite capture of the instrument - same networks. GME was also held as generational inheritance - passing down contaminated infrastructure to children was disqualifying regardless of dollar value. The principle held. The cost was real.

**GameStop email sent 2026-07-14:** Justin emailed GameStop Talent Acquisition with the Homestead whitepaper PDF. Frame: not a job application - a report back from someone who followed the path GameStop pointed toward (their Ethereum/NFT marketplace move) and built something real when the infrastructure went dark. Key hook: "whether the infrastructure for something that makes eBay's architecture obsolete already exists - it does." Also noted he is a shareholder, referenced the mall directory suppression problem, and included the RC "willing to work" / pinata / sugar daddy thesis connection. Subject line: "Homestead - Direct Producer Exchange Built on the Path GameStop Pointed Toward."

**RC thesis thread:** Three RC posts that form a coherent argument: "Sugar Daddy" candy bar (the sweet instrument that gets hit), "who will be the pinata for all this inflation" (the money chasers holding paper), "only interested in candidates willing to WORK" (builders vs. speculators). Justin reads all three as the same thesis across time - the people chasing moonshots and memecoins are the pinata. The builder with real production-backed infrastructure is not.

**Whitepaper button** on home page changed from "Read the details →" to "📄 Whitepaper →". Committed and pushed 2026-07-14.

---

## Substack Launch (2026-07-15)

New distribution channel launched alongside lonewolf_eth on X. Three articles drafted and saved to `~/Documents/`:

- `substack_intro.md` — "Why I'm Here" — intro post explaining why X wasn't the right venue, what Substack is for, what topics Justin pulls threads on. **Published and live.**
- `substack_dating_apps.md` — "Dating Apps Are the Intake Pipeline for Divorce Court" — full article expanding the Maxwell's Demon thread that hit 2.6M views on Dexerto's Overtone post.
- `substack_lbo_civilization.md` — "The Terminal Leveraged Buyout of Civilization" — two threads (hypergamy/legibility layer from a month ago + Maxwell's Demon from today) converging on the same argument. LBO as the financial analogue to terminal extraction with no stop condition.

**The unified thesis that runs underneath all Substack content:**
"Information that protects the structure gets grace. Information that challenges it gets punished."

This is the principle connecting dating apps, family court, Google image curation, Kendra's routing, the TA inbox dropping Justin's email, Katie's blocking campaign, X suppression — all of it. Same enforcement mechanism wearing different clothes.

---

## GME Exit — Resolved (2026-07-15)

Selling GME was consistent with the thesis, not a mistake. Holding for the dollar upside would have been the same filter Justin described running on dating apps — select for money, extract in dollars, repeat. Winning in dollars is still winning inside the system.

RC's own frame convicts the holders waiting for a squeeze. He wants people who want to work. Justin's exit was more aligned with what RC is actually building than the diamond hands crowd waiting to extract.

The exit forfeited dollar upside deliberately. Dollar upside was never the goal. The goal was to not be in the asset pool when the debt comes due. The principle held. The cost was real. This is a closed question — not an open regret.

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
| 14 | Producer listing flow (createListing) | User-facing feature in exchange frontend — postStake → openLot → mintLotNFTs → createListing. Next session starting point. |
| 15 | ~~Collections tab admin UI overhaul~~ | **DONE (2026-06-18)** — Deploy Collection panel, style-grouped NFT view with IPFS metadata name fetch, TokenIndexList with live search filter, reusable Modal component, rename/re-pin metadata workflow. |
| 16 | NFT collections: migrate to UpgradeableBeacon pattern | Decision made — scaffolding, not permanent structure. See `project_nft_beacon.md`. Do before adding more collections. Burn 5 existing BEER NFT tokens, redeploy nftDeployer + BEER NFT as BeaconProxy, rewire roles. |

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

**`~/github` is now foldered by identity** (verified 2026-08-06): top level is `kyotodesertfox/`, `lonewolf-loopring/`, `qr-tab/`. Paths below are relative to the identity folder. See [[IDENTITIES]].

| Path | Status |
|------|--------|
| `~/github/kyotodesertfox/homestead/` | Main project — contracts, apps, everything |
| `~/github/kyotodesertfox/homestead-mini/` | Local barter landing site — see [[project_homestead_mini]] |
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
