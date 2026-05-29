---
name: project_contracts
description: "Homestead smart contract architecture — storage layouts, key functions, deployed addresses, and upgrade status"
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

All contracts live at `~/github/homestead/contracts/`. All are UUPS upgradeable (OZ). **Never reorder or delete storage variables** — add new ones above `__gap` and reduce gap size accordingly.

## Deployed addresses (Taiko mainnet, chainId 167000)

| Contract | Proxy | Current Impl | Old Impl |
|---|---|---|---|
| Treasury | 0x631f9D082019E25a2BfD219BF235cA0b742206EC | 0x97C5DD6315372dba2B0c6E236D43A087885eC0e7 ✓ deployed 2026-05-19 | 0x62F23283649d56b49EA76e522Fa9C52f7ADf57e5 |
| Marketplace | 0x2321bDF62364ee38Fcf6b631C9742f6BF61B66Aa | 0x8c62c79958c56b8bdd99Aa97aD23E15e40C7A3cE ✓ deployed 2026-05-19 | 0x53439131029767302542893a83313180717DA791 |
| DEXFactory | 0xC72096f120cBb6a8f9e942864b885e1bb5060Cf2 | 0xC95C39d2E18a9c560C4365E6bEbffb89CB8d0832 | — |
| TokenDeployer | 0xB367B1e95BB9336731809AB1CF35c3D211dc1065 | — | — |
| NFTDeployer | 0x2A879059CfA27f707F1756DbfC6f683071099cC9 | — | — |
| masterTemplate | 0x5a320af586CBDD2Cc732BD76bF2Ce74fD51f2d00 (BEER proxy) | 0x9D6C344d3fF927Df604660d48C9F28c5d7f98C77 ✓ deployed 2026-05-19 | 0x0c5C014397d4f58e0ae90CF2a9FdaaB9738e5402 |
| nftTemplate | 0x210970F39B3AD4081090100Ed871fE42C54C2101 (BEER NFT) | 0x637f1f6FD0fF64dF0C920C43B4945779EA706fa2 ✓ deployed 2026-05-19 | 0x889BB10409C93de5d49a186d473D8293c1209DF8 |
| DEXPair (beacon impl) | — | 0x86e1092329e108267EB57A9a10fB62CDFF3edaeC | — |
| Router (immutable) | — | 0x07460A6c6b036019e2ff5Ed8F7462c2Aa0f8BC07 | — |
| WETH | — | 0xA51894664A773981C6C112C43ce576f315d5b1B6 | — |
| BEER/WETH pair | — | 0x7Bbdb6214b0592031933345C8E75186f90d01222 | — |
| EGG token | 0xc20A6C27B12FC81C5FBF46b30AAb6CF912A3C03a | — | — |
| EGG NFT ("Homestead Eggs", $EGGNFT) | 0xB90bC6186bA7d480584E06F92ecb15DAf653DE5C | 0x637f1f6FD0fF64dF0C920C43B4945779EA706fa2 | — | setMinter(Treasury ✓), setRedemptionOperator(Marketplace ✓) |
| EGG/WETH pair | — | 0xF6ed80b5e3b66279822494eC3eeC6AEe00932662 | — | WETH is token0 (WETH addr < EGG addr) |
| stkHomestead | 0x247178A36db9817d3FDb37eb7D7F54C7144e5432 ✓ deployed 2026-05-19 | — | — | name: "Homestead Stake", symbol: "stkHomestead" |

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
15: lpRewardFeeBps
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
- Buyer buys NFT on Marketplace
- Buyer redeems → Marketplace calls `onRedeem(batchId)` → escrowed tokens burned → `usedCollateral` freed proportionally
- Producer calls `claimStake(batchId)` → ETH released pro-rata (`stakedAmount * redeemedCount / totalNFTs`)

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
- `onRedeem(batchId)` — isTrustedCaller (Marketplace)
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
- `createListing(nftContract, paymentToken, price, batchId, subsidyCount)`
- `depositInventory / withdrawInventory / setActive / updatePrice`
- `buy(listingId)` — fee → Treasury; remainder held in escrow per tokenId
- `redeem(nftContract, tokenId)` — burns escrowed tokens, calls `Treasury.onRedeem(batchId)`
- `setActive(listingId, false)` — deactivates listing (NFTs stay in Marketplace contract)
- `withdrawInventory(listingId, count)` — returns NFTs to caller wallet
- `chargeSubsidy`, `reclaimSubsidy`, `subsidyBalance`

**Gap:** `uint256[39]`

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

**Post-upgrade config calls (same tx session, not code):**
- `setLpShareBps(4000)` — 40% to LPs, 60% to Treasury
- `setTierThreshold(1, amount)` — tier 1 threshold (Holder)
- `setTierThreshold(2, amount)` — tier 2 threshold (Producer)
- `setTierThreshold(3, amount)` — tier 3 threshold (Trusted)

**Note for Router:** After Treasury renames `lpRewardFeeBps` → `lpShareBps`, update the Router source to call `lpShareBps()` before deploying it.

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
