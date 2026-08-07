---
name: project_contracts
description: "Homestead smart contract architecture — storage layouts, key functions, deployed addresses, and upgrade status"
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
  modified: 2026-08-07T04:56:28.922Z
---

All contracts live at `~/github/homestead/contracts/`. All are UUPS upgradeable (OZ). **Never reorder or delete storage variables** — add new ones above `__gap` and reduce gap size accordingly.

## Deployed addresses (Taiko mainnet, chainId 167000)

| Contract | Proxy | Current Impl | Old Impl |
|---|---|---|---|
| Treasury | 0x631f9D082019E25a2BfD219BF235cA0b742206EC | 0x1cBc456ddaaB1D097caC85e6c6FfaF315EF3fB8c ✓ deployed 2026-06-07 (surplus + withdrawSurplus live) | 0x857E2293Ea6b5eF87fa77Af119bf5255B83b0F44 | owner: 0xe782e5f2DD980179bbc0604b353BfB59Fba0f9DC (transferred 2026-07-09, verified via owner() call) |
| Marketplace | 0x2321bDF62364ee38Fcf6b631C9742f6BF61B66Aa | 0xcA688a087F3D46554154E5EF7d8572c6Db258Aac ✓ deployed+verified+UTAC 2026-06-06 | 0x8c62c79958c56b8bdd99Aa97aD23E15e40C7A3cE |
| DEXFactory | 0xC72096f120cBb6a8f9e942864b885e1bb5060Cf2 | 0xC95C39d2E18a9c560C4365E6bEbffb89CB8d0832 | — |
| TokenDeployer | 0xB367B1e95BB9336731809AB1CF35c3D211dc1065 | — | — |
| NFTDeployer | 0x2A879059CfA27f707F1756DbfC6f683071099cC9 | — | — |
| masterTemplate | 0x5a320af586CBDD2Cc732BD76bF2Ce74fD51f2d00 (BEER proxy) | 0x9D6C344d3fF927Df604660d48C9F28c5d7f98C77 ✓ deployed 2026-05-19 | 0x0c5C014397d4f58e0ae90CF2a9FdaaB9738e5402 |
| nftTemplate | 0x210970F39B3AD4081090100Ed871fE42C54C2101 (BEER NFT) | 0x637f1f6FD0fF64dF0C920C43B4945779EA706fa2 ✓ deployed 2026-05-19 | 0x889BB10409C93de5d49a186d473D8293c1209DF8 |
| HomesteadRelay | 0x96FC77220d578aF5D4380Dc2D2248Ed31444C491 (proxy) | 0xE8069A9882194e1d33Db696fe1128a8c57281e28 ✓ upgraded 2026-06-07 (adds kyberKey + ethFee + 2-arg registerKey) | 0x88D6378521276Af5aA0109f99Aac364388373edd |
| DEXPair (beacon impl) | — | 0x86e1092329e108267EB57A9a10fB62CDFF3edaeC | — |
| Router (immutable — TO BE REPLACED) | — | 0x07460A6c6b036019e2ff5Ed8F7462c2Aa0f8BC07 | — |
| WETH | — | 0xA51894664A773981C6C112C43ce576f315d5b1B6 | — |
| BEER/WETH pair | — | 0x7Bbdb6214b0592031933345C8E75186f90d01222 | — |
| EGG token | 0xc20A6C27B12FC81C5FBF46b30AAb6CF912A3C03a | — | — |
| EGG NFT ("Homestead Eggs", $EGGNFT) | 0xB90bC6186bA7d480584E06F92ecb15DAf653DE5C | 0x637f1f6FD0fF64dF0C920C43B4945779EA706fa2 | — | setMinter(Treasury ✓), setRedemptionOperator(Marketplace ✓) |
| EGG/WETH pair | — | 0xF6ed80b5e3b66279822494eC3eeC6AEe00932662 | — | WETH is token0 (WETH addr < EGG addr) |
| stkHomestead | 0x247178A36db9817d3FDb37eb7D7F54C7144e5432 ✓ deployed 2026-05-19 | — | — | name: "Homestead Stake", symbol: "stkHomestead" |

---

## Live wiring state — probed against Taiko mainnet 2026-08-06

Read directly from the deployed contracts while building the admin Map tab. This is measured state, not design intent.

**Ownership is split, and the admin console's gate hides it.** Only Treasury was ever transferred. Everything else still sits on the deploy wallet:

| Contract | owner() |
|---|---|
| Treasury | `0xe782e5f2DD980179bbc0604b353BfB59Fba0f9DC` |
| Marketplace, DEXFactory, TokenDeployer, NFTDeployer, Relay, stkHomestead, $QUANTUM | `0x202ECf228020b79bd1BFCE7457C15A9831BCe4D3` |
| Router | no `owner()` — immutable pre-UUPS deploy |

`AdminPage` gates on `Treasury.owner()`, so the wallet that can open the console cannot actually call setters on any of the other contracts. Pending task #2 ("transfer ownership of all deployed contracts") is the fix; until then every non-Treasury setter in the console will revert for the Treasury owner wallet.

**Deployed implementations are behind the repo source.** These getters exist in `contracts/` but revert on chain, which means the impl behind the proxy predates them:
- `DEXFactory.pairTreasury` — Release 2 not deployed
- `NFTDeployer.beacon` — still the old `contracts/nftDeployer_old/` deploy, pre-beacon
- `DEXPair.rewardsTreasury` — Release 2 not deployed
- `Router.owner` — the immutable Router at `0x0746…BC07`

**Genuine faults (function exists, value wrong/unset):**
- `Relay.registeredContract[Marketplace]` = **false** → `recordRedemption` reverts "caller not registered", and `Marketplace.redeem` swallows it in `try/catch {}`. Every redemption settles economically but records no attestation. Silent, permanent provenance gap. Fix is one call: `Relay.registerContract(marketplace)`.
- `Treasury.isTrustedCaller[EGG/WETH pair]` = false (BEER pair is true) → LP reward claims revert for the EGG pool only.
- `Marketplace.router` / `relay` / `farmToken` all zero — expected, Releases 2 and 3 are unshipped.

**Everything else checked clean:** all six Treasury pointers, `isTrustedCaller[Marketplace]`, Marketplace `feeCollector`/`tokenDeployer`/`nftDeployer`, all three Router pointers, `Factory.tokenDeployer`, `Factory.beacon`, `TokenDeployer.templateAddress`, `Relay.treasury`/`marketplace`/`feeToken`, both pairs' `factory`, `stkHomestead.isMinter[Treasury]`.

### Structural gap found while mapping

`DEXPair.setRewardsTreasury` is gated `msg.sender == factory`, and `DEXFactory` only calls it inside `createPair`. There is no `setPairRewardsTreasury(pair, addr)` admin function. **An existing pair whose `rewardsTreasury` is wrong or unset cannot be repaired without a Factory upgrade.** Worth adding to the Release 2 Factory change while it is already being touched, since both live pairs currently lack the field entirely.

---

## Admin Wiring Map (branch `feature/health-map`, 2026-08-06)

New `Map` tab, first in the admin console. Additive — the other six tabs are untouched.

- `apps/exchange/src/pages/admin/wiring.js` — the point of the whole thing. One declarative `EDGES` array holds every pointer and role grant, each row carrying its expected value, severity, what breaks in plain language, and the setter that repairs it. The graph, the fault list and the fix buttons all derive from that array, so adding a contract later is one row, not three edits.
- `apps/exchange/src/pages/admin/MapTab.jsx` — `@xyflow/react` canvas plus fault list with one-click fix.
- `apps/exchange/src/pages/admin/ui.jsx` — `Label`/`Input`/`Btn`/`TxStatus`/`CopyAddr`/`Hint`/`useWrite`/`useCodeHashes` moved verbatim out of `Page.jsx` so both tabs share one copy.

**Four statuses, not two.** A reverting read is `absent` ("behind source"), never a fault — telling someone to call a setter that does not exist on the deployed impl is worse than saying nothing. An edge whose address path is unset is `skipped` and is never counted as healthy. Both get their own panel.

Scope is core infra only (the fixed `ADDRESSES` set). Per-token and per-collection role grants stay in the Collections and Tokens tabs.

---

## Contract verification on TaikoScan (2026-08-06)

HomesteadRelay's current implementation (`0xE8069A9882194e1d33Db696fe1128a8c57281e28`) is now verified on TaikoScan. It wasn't before — the proxy itself was verified (standard ERC1967Proxy, auto-detected), but "Write as Proxy" had nothing to render because the implementation behind it had no ABI. Ownership hasn't been transferred yet (confirmed 2026-08-06 - still sitting on the deploy wallet per the table above), so this only unlocked the *ability* to call `transferOwnership` through the explorer UI, not the transfer itself.

**Given only Marketplace's row explicitly says "verified" in the address table above, assume the rest are not, until checked.** That's worth doing before anyone needs write access to one of them under time pressure.

**Recipe for verifying a mismatched/unverified implementation** (needed because the current repo source had three commits of unrelated changes on top of what was actually deployed):
1. Don't assume current `contracts/` HEAD matches what's deployed. Check the "Old Impl"/description column above for a hint (e.g. "adds kyberKey + ethFee + 2-arg registerKey"), then `git log --follow -- <file>` to find the matching commit by date/description.
2. Pull that exact version (`git show <commit>:path/to/File.sol > File.sol`), rebuild (`forge build`), and diff the resulting `deployedBytecode` byte-for-byte against `cast code <address> --rpc-url https://rpc.mainnet.taiko.xyz`.
3. An exact length match with only two kinds of leftover diffs confirms it's the right source: (a) the contract's own address embedded 1-2 times (UUPS's `address(this)` immutable — a real verifier resolves this correctly since it compiles against the actual target address) and (b) the trailing ~32-53 byte CBOR metadata hash (environment-dependent, doesn't block verification). Any other diff means it's still the wrong version.
4. Generate the standard-json-input from that exact historical version: `forge verify-contract --show-standard-json-input <impl_address> <path>:<Contract> --chain 167000 > input.json` (this is a local dry-run, no submission, no wallet needed).
5. Submit on TaikoScan under the implementation address's "Verify and Publish" → Solidity (Standard-Json-Input), matching compiler version/optimizer/evmVersion from `foundry.toml` + the contract's own `_metadata.json`.
6. Restore the repo's actual current file afterward (`git checkout -- <file>` or copy back from a pre-swap backup) — the swap in step 1-2 is local-only and must not be left in place.

---

## Unit convention — CRITICAL

**All user-facing token amount parameters across all contracts are in human units (e.g. 50 = 50 tokens).** The contract calls `_toBase(amount)` internally which is the single place `1e18` appears. Never accept base units from the UI or external callers — the contract enforces this by converting internally. Passing base units accidentally would try to move `n * 1e18 * 1e18` tokens and fail with insufficient balance.

---

## Treasury.sol (`contracts/treasury/`) — FULLY REDESIGNED, NOT YET DEPLOYED

Two-step CDP staking model. ETH is permanent floor. stkHomestead is burned proportionally in `claimStake` — 1:1 with ETH leaving the Treasury. Production tokens are always whole numbers (uint256 human units, enforced by `_toBase`). stkHomestead is the only fractional token in the system (minted 1:1 with ETH in wei via `mintExact`).

### Storage layout (slots 0–49, gap = 26)
```
0:  tokenDeployer
1:  nftDeployer
2:  dexFactory
3:  dexEntryFeeBps
4:  dexExitFeeBps
5:  marketplaceFeeBps
6:  accumulatedFees
7:  nftPrices (mapping)
8:  farmToken
9:  farmStakeBps
10: farmLpBps
11: nextBatchId
12: batches (mapping)
13: isTrustedCaller (mapping)
14: weth
15: lpShareBps
16: _claimedAmount (mapping)
17: cumulativeStake (mapping)
18: tierThreshold (mapping)
19: trustedRelay
20: stkHomestead
21: collateralRatioBps
22: usedCollateral (mapping)       ← NEW
23: tokenBatch (mapping)           ← NEW (nftContract → tokenId → batchId)
24–49: __gap[26]
```

### Batch struct
```solidity
struct Batch {
    address producer;
    address nftContract;
    address token;              // production token (generic — not hardcoded)
    uint256 stakedAmount;       // ETH value of lot at spot when opened
    uint256 collateralLocked;   // usedCollateral contribution (110% of stakedAmount)
    uint256 tokenAmount;        // production tokens minted — BASE UNITS internally
    uint256 collateralReleased; // collateral freed so far (redemptions + burnLotTokens)
    uint256 tokenPerNFT;        // escrowed tokens per NFT — BASE UNITS internally
    uint256 totalNFTs;
    uint256 redeemedCount;
    uint256 returnedCount;      // NFTs returned via graceful exit
    uint256 startTokenId;
    bool listed;
    bool slashed;
}
```

### Full producer flow

**1. postStake()**
- ETH in → stkHomestead minted 1:1 in wei via `mintExact`
- ETH locked in Treasury permanently as ecosystem floor
- `cumulativeStake[producer] += msg.value` (reputation counter only — no ETH obligation)
- stkHomestead burned in `claimStake` 1:1 with ETH claimed — credential consumed as collateral resolves

**2. openLot(token, amount)**
- `amount` = human units (contract calls `_toBase` internally)
- Checks: `stkBalance >= usedCollateral + collateralRequired` (110% of lot ETH value at spot)
- `usedCollateral[producer] += collateralRequired` — capacity committed, stkHomestead NOT burned
- Mints `amount` production tokens to producer wallet
- Producer may gift, hold, or trade tokens freely before minting any NFTs

**3. mintLotNFTs(batchId, nftContract, cids[], tokenPerNFT)**
- `tokenPerNFT` = human units (contract converts to base internally)
- Producer must approve Treasury to spend tokens first
- Treasury pulls `count × _toBase(tokenPerNFT)` tokens into escrow
- Treasury mints NFTs to producer (one per CID)
- One call per lot — open a new lot for additional NFTs

**4. Normal sale path**
- Buyer buys NFT on Marketplace — sends `listing.price` tokens; fee → Treasury, remainder escrowed in Marketplace
- Buyer redeems → Marketplace calls `onRedeem(batchId)`:
  - Treasury transfers `tokenPerNFT` tokens to Marketplace (NOT burned — released for swap)
  - Marketplace burns buyer's escrowed tokens (deflationary, ~50% of tokens involved)
  - Marketplace swaps producer's released tokens → ETH via Router → sent to producer's `proceeds` address
  - `usedCollateral` freed proportionally
- Producer calls `claimStake(batchId)` → staked ETH released pro-rata (`stakedAmount * redeemedCount / totalNFTs`)

**FALLBACK A — Unsold NFTs**
- `setActive(false)` + `withdrawInventory` on Marketplace → NFTs back in producer wallet
- `returnNFTs(batchId, tokenIds[])` → Treasury burns NFTs, releases escrowed tokens back to producer
- `usedCollateral` stays locked — only the escrowed tokens are returned

**FALLBACK B — Exit token position to free collateral**
- `burnLotTokens(batchId, amount)` — human units
- Treasury pulls tokens from producer, burns them
- Frees `usedCollateral` proportionally, capped at `collateralLocked - collateralReleased`
- ETH stays in Treasury permanently as floor
- Freed capacity available for new lots

### Key functions
- `postStake()` payable
- `openLot(token, amount)` → batchId
- `mintLotNFTs(batchId, nftContract, cids[], tokenPerNFT)`
- `returnNFTs(batchId, tokenIds[])`
- `burnLotTokens(batchId, amount)`
- `claimStake(batchId)` — pro-rata ETH to producer
- `slashStake(batchId)` — onlyOwner, emergency only
- `onRedeem(batchId)` → `(address token, uint256 amount)` — isTrustedCaller (Marketplace); transfers tokenPerNFT to caller instead of burning
- `markListed(batchId, listingId)` — isTrustedCaller
- `availableCollateral(producer)` — view: stkBalance - usedCollateral
- `setStkHomestead(address)`, `setCollateralRatioBps(uint256)` — onlyOwner
- `_toBase(humanAmount)` — internal pure, single 1e18 conversion point

### Post-deploy config required
```
setStkHomestead(stkHomesteadProxy)
setCollateralRatioBps(11000)          // 110%
setWeth(0xA51894664A773981C6C112C43ce576f315d5b1B6)
setTrustedCaller(marketplaceProxy, true)
setTrustedCaller(beerWethPair, true)
setLpRewardFeeBps(200)
```
- stkHomestead must grant Treasury minter role
- Existing old batches (created under stale impl): slash after upgrade, they have no ETH backing

---

## masterTemplate.sol (`contracts/core/`) — UPDATED, NOT YET DEPLOYED

ERC20 token template. Every fungible token in the ecosystem is a deployed instance.

**New functions added:**
- `mintExact(address to, uint256 amount)` — onlyMinter; mints raw base units with no 1e18 scaling. Used by Treasury for stkHomestead (1:1 with ETH in wei).
- `burnFromMinter(address account, uint256 amount)` — onlyMinter; burns from any account without allowance. Available but no longer used by Treasury (stkHomestead not burned).

**Existing key functions:**
- `mintToWallet(address, uint256)` — onlyMinter, scales by 1e18 internally
- `mintToPool(address pool, uint256)` — onlyMinter
- `burnFromSupply(address, uint256)` — onlyOwner, emergency
- `setMinter(address, bool)` — onlyOwner
- `burn(uint256)` — any holder burns own tokens
- `burnFrom(address, uint256)` — approved spender burns on behalf

**Gap:** `uint256[46]`

---

## nftTemplate.sol (`contracts/marketplace/`) — burnToken deployed ✓

**Post-deploy config required for every new NFT collection:**
- `setRedemptionOperator(marketplaceProxy, true)` — grants Marketplace permission to call `redeem()` on behalf of token holders. Without this, every redemption through Marketplace reverts. One call per collection at deploy time.
- `setMinter(treasuryProxy, true)` — required if Treasury needs to burn NFTs via `returnNFTs`.

**Key functions:**
- `mintBatch(address, string[] cids)` → startTokenId
- `burnToken(address from, uint256 tokenId)` — onlyMinter; used by Treasury in returnNFTs
- `setTokenCID(uint256 tokenId, string newCID)` — onlyOwner
- `redeem(uint256 tokenId)`, `markRedeemed(uint256 tokenId)`
- `setRedemptionOperator(address, bool)` — onlyOwner
- `setMinter(address, bool)` — onlyOwner

**Gap:** `uint256[43]`

---

## Marketplace.sol (`contracts/marketplace/`)

**Key functions:**
- `createListing(nftContract, paymentToken, price, batchId, subsidyCount)` — nonReentrant
- `depositInventory / withdrawInventory / setActive / updatePrice`
- `buy(listingId)` — fee → Treasury; remainder held in `_escrowedTokens[tokenId]` (buyer's tokens)
- `redeem(nftContract, tokenId)`:
  1. Burns buyer's `_escrowedTokens[tokenId]` (deflationary)
  2. Calls `Treasury.onRedeem(batchId)` → returns `(token, amount)` = producer's tokenPerNFT
  3. Swaps producer's tokens → ETH via Router → producer's `proceeds` address
- `setActive(listingId, false)` — deactivates listing (NFTs stay in Marketplace contract)
- `withdrawInventory(listingId, count)` — returns NFTs to caller wallet
- `chargeSubsidy`, `reclaimSubsidy`, `subsidyBalance`

**Gap:** `uint256[38]`

---

## DEXPair / DEXFactory / Router

### Router — FULLY REWRITTEN, NOT YET DEPLOYED (2026-05-27)

Source at `contracts/dex/Router.sol`. Now UUPS upgradeable. Key changes:
- Inherits `Initializable + OwnableUpgradeable + UUPSUpgradeable`
- `_disableInitializers()` in constructor
- `initialize(factory, WETH, treasury, owner)` replaces old constructor
- `AMM_FEE_BPS = 30` — public constant matching `HomesteadLibrary 9970/10000`
- `getFeeSchedule()` → returns `FeeSchedule { ammFeeBps, entryFeeBps, exitFeeBps, lpRewardBps, treasuryBps }` — single call for UI
- Entry fee: deducted from `msg.value` before swap, sent to Treasury
- Exit fee: split — `lpRewardFeeBps` → exit pair (LP reward), remainder → Treasury
- Auto-claim `pair.claimRewards(msg.sender)` in `removeLiquidityETH` before LP tokens transferred
- `setTreasury(address)` onlyOwner
- Router reads ALL fee policy from Treasury at call time — owns no policy itself

**Deploy instructions:**
1. Deploy ERC1967Proxy pointing at implementation (UUPS pattern via OpenZeppelin upgrades script)
2. Call `initialize(FACTORY_PROXY, WETH, TREASURY_PROXY, ownerAddress)` on proxy
3. Update `VITE_ROUTER` in `.env` to new proxy address
4. `getFeeSchedule` ABI already added to `ROUTER_ABI` in `contracts.js`

**Post-Router-deploy swap page TODO:**
- Replace `const AMM_FEE_BPS = 30n` constant with `useReadContract getFeeSchedule()` call
- Surface `entryFeeBps` in trade info panel (currently read from Treasury but not displayed)

### Currently deployed Router (immutable, pre-upgrade)

Address: `0x07460A6c6b036019e2ff5Ed8F7462c2Aa0f8BC07` — entry fee NOT collected, exit fee 100% to Treasury (no LP split), no claimRewards call.

### DEXPair / DEXFactory

- DEXPair upgraded via `Factory.upgradePairs(newImpl)`
- Factory gap: `uint256[43]`
- DEXPair upgrade (add `claimRewards`) must be deployed in same release as new Router

---

## Completed deploys (2026-05-19)

1. ~~masterTemplate new impl~~ ✓ — impl 0x9D6C344d3fF927Df604660d48C9F28c5d7f98C77, upgraded BEER proxy
2. ~~Treasury new impl~~ ✓ — impl 0x97C5DD6315372dba2B0c6E236D43A087885eC0e7, upgraded proxy
3. ~~nftTemplate new impl~~ ✓ — impl 0x637f1f6FD0fF64dF0C920C43B4945779EA706fa2, upgraded BEER NFT proxy
4. ~~stkHomestead~~ ✓ — proxy 0x247178A36db9817d3FDb37eb7D7F54C7144e5432, name "Homestead Stake", symbol "stkHOME"
5. ~~Treasury post-deploy config~~ ✓ — setStkHomestead, setCollateralRatioBps(11000), setWeth, setTrustedCallers
6. ~~stkHomestead: setMinter(treasuryProxy, true)~~ ✓
7. ~~Marketplace new impl~~ ✓ — impl 0x8c62c79958c56b8bdd99Aa97aD23E15e40C7A3cE, upgraded proxy
8. ~~setRedemptionOperator(marketplaceProxy, true)~~ ✓ on BEER NFT

---

## Pending releases — ordered to minimize upgrades

### Release 1 — Treasury upgrade (batch ALL deferred work into one impl)

One upgrade covers everything Treasury-related. Do not upgrade Treasury again until this list is complete.

**Code changes needed (diagnose postStake first):**
- [ ] Fix `postStake()` revert — cause unknown, needs Remix call to get revert reason before writing fix
- [ ] Rename `lpRewardFeeBps` → `lpShareBps` (slot 15 reused, value changes 200 → 4000). New semantics: ratio of collected fee to LPs (0–10000), not absolute bps of trade value
- [ ] Add `attestationOverride` mapping + `setAttestationOverride(address, uint8)` onlyOwner + check override first in `attestationTier()`. Shrink `__gap` by 1. (For trusted providers onboarded via mintToWallet who have no stake)
- [ ] Slash / unslash redesign — DESIGN LOCKED 2026-06-17, see "Slash mechanism" section below. Treasury: add `reason` to `slashStake`, add `unslashStake(batchId, reason)` onlyOwner. Marketplace (coordinated change, same release): add buyer cancel path for slashed batches.

**Post-upgrade config calls (same tx session, not code):**
- `setLpShareBps(4000)` — 40% to LPs, 60% to Treasury
- `setTierThreshold(1, amount)` — tier 1 threshold (Holder)
- `setTierThreshold(2, amount)` — tier 2 threshold (Producer)
- `setTierThreshold(3, amount)` — tier 3 threshold (Trusted)

**Note for Router:** Treasury has been renamed `lpRewardFeeBps` → `lpShareBps` (2026-06-06). Update Router source to call `lpShareBps()` before deploying it.

---

### Slash mechanism — DESIGN LOCKED (2026-06-17)

**Purpose:** punish producers who fail to deliver or harm the platform. Slash is a semi-permanent LOCK for review/QC, not a seizure — accidents should not be absolute punishment. Resolution path unlocks it. Owner/Treasury wallet reviews today; review board / DAO in the distant future (no code change for that — just transfer ownership to a governance/timelock contract; `onlyOwner` already supports it).

**Current state (what `slashStake` already does):** pure flag flip `batch.slashed = true`, ETH never moves. The flag is checked in 6 places — `mintLotNFTs`, `returnNFTs`, `burnLotTokens`, `claimStake`, `onRedeem`, `validateListingCaller` (plus `claimableStake` returns 0). So the batch freeze ("lock the whole lot until review") is fully built. The missing half is the unlock.

**Decisions locked:**
1. **Batch-level only — NO producer-level freeze.** A slashed-batch producer can still `openLot` new batches IF they have collateral. Rationale: a slashed batch keeps its `usedCollateral` committed permanently (slash never frees it), so repeated slashes drain a producer's available collateral until `openLot` reverts `InsufficientCollateral`. The locked collateral IS the automatic, proportional producer-level throttle — no separate flag needed. Self-policing through economics, consistent with the rest of the system.
2. **`unslashStake(batchId, reason)` onlyOwner** — flag flip back, ETH never moves. Add `reason` to `slashStake` too. Both events carry the reason (or evidence CID) as the review audit trail. NO cooldown before ops resume (cleared party shouldn't keep suffering). NO cap on slash/unslash cycles (owner trusted today → DAO later; event log is the accountability). "Never resolves" = default: do nothing, batch stays locked forever.
3. **Buyer is NEVER encumbered by a slash — only the producer.** A buyer holding an NFT from a slashed batch has two options, available the moment it's slashed and indefinitely after:
   - **Hold** — wait for `unslashStake`, then redeem and take delivery normally.
   - **Cancel their side** (new Marketplace fn, gated on `batch.slashed == true`) — reclaim their own `_escrowedTokens[tokenId]`, surrender the NFT back to Marketplace custody (symmetric unwind, no free-NFT double-dip). Buyer exits whole. The batch stays slashed; only the producer remains encumbered.
   - Buyer does NOT get `unslashStake` power — that stays review-only (owner/DAO). The buyer's leverage is their own exit, not clearing the producer's slash. (Giving buyers unslash would gut the QC purpose.)
   - **Why not strand the buyer as "pressure":** a frozen buyer can't compel the producer (can't unslash, can't force delivery) — it routes the complaint to the platform, not the producer, converting a producer failure into a platform liability + innocent-party loss. The real accountability hostage is the producer's frozen stake, held by the party who can actually resolve. Buyer's funds were never needed as a second hostage.

**Cancel mechanics:** NFT returns to Marketplace custody (Marketplace pulls via `transferFrom`, buyer-initiated + prior approval, or buyer transfers then calls). Burn not viable — Marketplace isn't the NFT minter. Returned NFT sits in the slashed listing, non-redeemable/non-returnable until unslash, then cleans up via `returnNFTs`. Marketplace reads slash state via `batches(batchId)` getter or a small `isSlashed(batchId)` view (cleaner). Scope cancel to slashed batches only; same primitive generalizes to pre-redemption cancellation later if ever wanted.

**Release:** rides in Release 1 (Treasury: `reason` + `unslashStake`) + coordinated Marketplace upgrade (buyer cancel reading Treasury slash state). Bump `VERSION` in both `.sol` + `EXPECTED_VERSIONS` in `contracts.js`. Future evolution (not now): producer self-kiosk unlock options.

---

### Release 2 — DEXPair upgrade + Router deploy (independent of Treasury timing)

Can happen before or after Release 1. Hard constraint: DEXPair must be upgraded BEFORE Router is deployed (Router calls `pair.claimRewards()` in removeLiquidityETH — if pair lacks the function, LP removal breaks).

- [ ] Upgrade DEXPair impl: add `claimRewards(address lp)` function. Deploy new impl, call `Factory.upgradePairs(newImpl)`.
- [ ] (If Release 1 done first) Update Router source: `lpRewardFeeBps()` → `lpShareBps()` in ITreasury calls
- [ ] Deploy Router UUPS: impl + ERC1967Proxy, call `initialize(FACTORY_PROXY, WETH, TREASURY_PROXY, owner)`
- [ ] Update `VITE_ROUTER` in `.env` to new proxy address
- [ ] Swap page: replace `const AMM_FEE_BPS = 30n` with `getFeeSchedule()` call; surface `entryFeeBps` in trade info panel

---

### Release 3 — HomesteadRelay (separate, no dependency on 1 or 2)

Contract complete, chat UI is a shell. Deploy order:
1. Deploy proxy, call `initialize(treasury, beer, 1e18)`
2. `setTrustedRelay(relayProxy, true)` on Treasury
3. `setDexPair(pairAddress)` on Relay
4. `setMarketplace(marketplaceProxy)` on Relay
5. `setQuantumFreeRecipient(supportWallet, true)` on Relay
6. Set `VITE_RELAY` in `.env`

---

## Vouching System — Designed, Not Yet Built (2026-06-08)

**Problem:** Capital requirement for staking is itself a permission structure. Small producers with genuine craft but no ETH cannot enter the platform. But removing stake entirely breaks the accountability filter.

**Solution: Delegated staking via reverse fork pattern.**

Two entry paths that converge at the same execution point:

```
Path A (self-staked):   postStake() → openLot() → [batchId] → mintLotNFTs()
Path B (vouched):  vouchOpen() → validates voucher stake → openLot() → [batchId] → mintLotNFTs()
```

`openLot()` and `mintLotNFTs()` are unchanged. `vouchOpen()` is a gated entry point that validates the vouching conditions and hands off to the existing flow. The batch itself doesn't care how it was created — everything downstream is identical.

**Batch struct addition:**
```solidity
address public voucher; // address(0) if self-staked, voucher's address if vouched
```

- `voucher == address(0)` → self-staked, no badge
- `voucher != address(0)` → vouched, display badge + address on Marketplace listing

Single field does three things: boolean check, identity, and full on-chain vouching history derivable from address.

**Slash logic:** If `voucher != address(0)`, slash hits voucher's stake — not producer's. The voucher takes financial risk. The producer takes reputational risk. Both have skin in the game.

**Marketplace badge:** Listing reads `batch.voucher` from Treasury. If non-zero, displays a voucher badge with the voucher's address. Badge is clickable — links to all batches that address has ever vouched for + their delivery record. Vouching becomes an on-chain reputation in itself. A trusted voucher who consistently backs reliable producers becomes a meaningful signal.

**The accountability elegance:** You can't vouch for someone you don't trust because your ETH is on the line. A good voucher who backs reliable producers builds trust. A bad voucher loses stake and credibility simultaneously.

**Graduation path:** Producer completes batches successfully → builds own stake history → eventually posts their own stake → stops needing a voucher. The door opened once becomes unnecessary.

**Why Marketplace needs to know:** Not just security — provenance. The platform should visibly show that it grows through vouching relationships, not just capital. Vouching is community trust made on-chain.

**Not yet implemented** — requires Treasury upgrade (add `voucher` to Batch struct, add `vouchOpen()` function). Marketplace frontend change only (read `batch.voucher` and display badge). No Marketplace contract change needed if frontend reads Treasury directly.
