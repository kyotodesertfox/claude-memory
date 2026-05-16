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
Pinned records at `contracts/.deploys/pinned-contracts/167000/`
`.env` and `contract_addresses.txt` are the authoritative address references.

| Contract | Proxy | Current Impl | Old Impl |
|---|---|---|---|
| Treasury | 0x631f9D082019E25a2BfD219BF235cA0b742206EC | **0x62F23283649d56b49EA76e522Fa9C52f7ADf57e5** ✓ upgraded | 0xFAC3fF5D6FA146177792E9C4D48F7195c9447c0D |
| Marketplace | 0x2321bDF62364ee38Fcf6b631C9742f6BF61B66Aa | 0x53439131029767302542893a83313180717DA791 | — |
| DEXFactory | 0xC72096f120cBb6a8f9e942864b885e1bb5060Cf2 | 0xC95C39d2E18a9c560C4365E6bEbffb89CB8d0832 | — |
| TokenDeployer | 0xB367B1e95BB9336731809AB1CF35c3D211dc1065 | 0x757fE132A402B96Ec41D084e089B9c91E112dcc6 | — |
| NFTDeployer | 0x2A879059CfA27f707F1756DbfC6f683071099cC9 | 0x69f49a3E8A645999CAC67CD304C59366F0CD802D | — |
| masterTemplate | 0x5a320af586CBDD2Cc732BD76bF2Ce74fD51f2d00 (BEER) | 0x0c5C014397d4f58e0ae90CF2a9FdaaB9738e5402 | — |
| nftTemplate | 0x210970F39B3AD4081090100Ed871fE42C54C2101 (BEER NFT) | 0x889BB10409C93de5d49a186d473D8293c1209DF8 | — |
| DEXPair (beacon impl) | — | 0x86e1092329e108267EB57A9a10fB62CDFF3edaeC | — |
| Router (immutable) | — | 0x07460A6c6b036019e2ff5Ed8F7462c2Aa0f8BC07 | — |
| WETH | — | 0xA51894664A773981C6C112C43ce576f315d5b1B6 | — |
| BEER/WETH pair | — | 0x7Bbdb6214b0592031933345C8E75186f90d01222 | — |

---

## Full deployment checklist (updated 2026-05-15)

Commits include stake system, LP rewards, contract audit fixes (burn/burnFrom, trustedRelay, getReserves 3-value, relay wiring, onTokenMinted removal).

**Phased rollout plan (avoid one large risky deploy):**
- **Phase 0** — Upgrade existing contracts (masterTemplate, Treasury, DEXPair, Marketplace, nftTemplate, Router, Factory) + wire post-upgrade config
- **Phase 1** — Staking live; $FARM off (`setFarmToken(0)`, `setFarmStakeBps(0)`) — verify postStake, claimStake, attestation tiers
- **Phase 2** — Deploy $FARM token, seed FARM/WETH pair, enable $FARM emission (`setFarmToken`, `setFarmStakeBps`, `setFarmLpBps`)
- **Phase 3** — Deploy HomesteadRelay (UUPS), wire to Treasury + Marketplace, enable quantum chat + delivery messages
- **Phase 4 (deferred)** — $stkHomestead stake pool token (TBD mint mechanics)

Deploy in order — HomesteadRelay depends on Treasury being upgraded first.

### Step 1 — Deploy new implementations (order matters)

1. Deploy new **masterTemplate** impl → upgrade each token proxy (burn/burnFrom added, onTokenMinted removed)
2. Deploy new **Treasury** impl → call `upgradeProxy(newImpl)` on Treasury proxy (trustedRelay added, gap 31→30)
3. Deploy new **DEXPair** impl → call `Factory.upgradePairs(newImpl)` (getReserves now returns 3 values)
4. Deploy new **Marketplace** impl → call `upgradeProxy(newImpl)` on Marketplace proxy (relay field added, gap 42→41)
5. Deploy new **nftTemplate** impl → call `upgradeProxy(newImpl)` on each nftTemplate instance
6. Deploy new **Router** (not upgradeable — fresh deploy, immutable constructor args: factory, WETH, treasury)
7. Deploy new **Factory** impl → call `upgradeProxy(newImpl)` on Factory proxy
8. **Deploy HomesteadRelay** — must be AFTER Treasury upgrade (needs trustedRelay to exist on-chain)
   - Now UUPS upgradeable — deploy impl + ERC1967 proxy, call `initialize(_treasury, _feeToken, _quantumFee)`
   - `initialize` args: `_treasury`, `_feeToken` ($BEER address), `_quantumFee` (1e18 = 1 BEER)

### Step 2 — Wire Treasury

```
Treasury.setFarmToken(farmTokenAddress)   // $FARM governance token (deploy first, seed FARM/WETH pair first)
Treasury.setFarmStakeBps(1000)            // 10% of ETH staked value emitted as $FARM at spot
Treasury.setFarmLpBps(500)               // 5% of LP reward ETH value emitted as $FARM at spot
Treasury.setWeth(wethAddress)
Treasury.setLpRewardFeeBps(200)          // 2% of exit fee to LP rewards
farmToken.setMinter(treasuryProxy, true)          // Treasury must mint $FARM on stake + LP claim
Treasury.setTrustedCaller(marketplaceProxy, true)
Treasury.setTrustedCaller(beerWethPairAddress, true)   // LP reward claim path
Treasury.setTrustedRelay(homesteadRelayAddress)        // NEW — unlocks recordRedemption
```

### Step 3 — Wire Factory

```
Factory.setPairTreasury(treasuryProxyAddress)
Factory.batchConfigurePairRewards([beerWethPairAddress])   // migrates existing pair
```

### Step 4 — Wire nftTemplate instances

```
// On each deployed nftTemplate:
nftTemplate.setMinter(treasuryProxyAddress, true)
nftTemplate.setRedemptionOperator(marketplaceProxy, true)  // allows Marketplace.redeem() to mark redeemed
```

### Step 5 — Wire Marketplace

```
Marketplace.setRelay(homesteadRelayAddress)        // enables best-effort attestation on redeem
Marketplace.setFarmToken(farmTokenAddress)         // NEW — required for quantum subsidy collection
```

### Step 5b — Wire Relay to Marketplace

```
relay.setMarketplace(marketplaceProxy)             // NEW — enables chargeSubsidy on delivery messages
```

### Step 6 — Wire HomesteadRelay

```
relay.setDexPair(beerWethPairAddress)              // required for ETH quantum fee path
relay.setQuantumFreeRecipient(ownerWallet, true)   // support messages to owner are quantum-free
relay.registerContract(marketplaceProxy)            // allows Marketplace to call recordRedemption
```

### Step 7 — Update frontend .env

Replace `VITE_ROUTER` with new Router address.

### Notes
- Old Router stays live until new one is deployed — no gap in trading
- HomesteadRelay MUST be deployed after Treasury upgrade — it calls `Treasury.trustedRelay()` on construction
- Marketplace.setRelay and Treasury.setTrustedRelay must both point to the same relay address
- `withdrawFees` is onlyOwner (you); transfer to multisig before significant TVL
- `floorBalance()` is the permanent ETH floor — never withdrawable
- `accumulatedFees` is the owner-withdrawable operational pool (exit fees)

---

## HomesteadRelay.sol (`contracts/relay/`) — NOT YET DEPLOYED

Written 2026-05-15. Awaiting deployment to Taiko mainnet.

**Constructor args:** `_treasury`, `_feeToken` ($BEER address), `_quantumFee` (1e18 = 1 BEER)

**Post-deploy config:**
```
relay.setDexPair(beerWethPairAddress)              // required for ETH quantum fee path
relay.setQuantumFreeRecipient(ownerWallet, true)   // support messages to owner are quantum-free
relay.registerContract(marketplaceProxy)            // allows marketplace to call recordRedemption
// Treasury also needs: Treasury.setTrustedRelay(relayAddress) — requires Treasury upgrade
```

**beer-bot config (after deploy):**
- Set `CONTRACTS["relay"]` in `src/config.py`
- Set `OWNER_ADDRESS` in `src/config.py`

**Key design:**
- No IPFS — messages inline in calldata, X25519 key in state, Kyber key in registration event
- `quantumFreeRecipient` mapping: designated wallets receive quantum messages fee-free
- Standard messages: X25519 only, free
- Quantum upgrade: **dual-path** — burn 1 $BEER (deflationary) OR pay ETH equivalent at DEX spot (→ Treasury floor). Sender's choice via `msg.value > 0`.
- `ethEquivalent()` reads BEER/WETH pair reserves at send time; no external oracle
- `sendMessage` and `sendGroupMessage` are payable
- `onlyTrustedByTreasury` modifier verifies two-way trust with Treasury before privileged ops
- `joinGroup()` uses `max(manual attestation[wallet], ITreasury.attestationTier(wallet))` — stake reputation recognized automatically, no owner intervention needed

**Additional storage:**
- `address public marketplace` — set via `setMarketplace(address)`; enables subsidy charging on delivery messages

**`sendDeliveryMessage(to, encryptedPayload, quantumReady, nftContract, tokenId)`:** Specialized send for buyer-seller delivery coordination. If `quantumReady && quantumFee > 0`, tries `marketplace.chargeSubsidy(nftContract, tokenId, fee)` first (best-effort try/catch). If subsidy fails or no marketplace set, falls back to standard `_chargeQuantumFee(recipient)` from sender.

**Upgradeable:** UUPS (converted — not yet deployed, no migration needed)
**Gap:** `uint256[45]` (marketplace slot added, 46→45)

---

## masterTemplate.sol (`contracts/core/`)
ERC20 token template. Every fungible token in the ecosystem (e.g. $BEER) is a deployed instance.

**Key storage:**
- `mapping(address => bool) isMinter` — addresses allowed to mint
- `string _nameOverride / _symbolOverride` — overrides ERC20 name/symbol post-deploy
- `string _contractURI` — OpenSea-style contract metadata

**Key functions:**
- `mintToWallet(address, uint256)` — onlyMinter, mints to EOA
- `mintToPool(address pool, uint256)` — onlyMinter, mints to DEX pool + calls `IFarmDEX.onTokenMinted()`
- `burnFromSupply(address, uint256)` — onlyOwner, emergency burn from any address
- `setMinter(address, bool)` — onlyOwner

**Gap:** `uint256[46]`

---

## nftTemplate.sol (`contracts/marketplace/`)
ERC721 template. Each physical product batch (e.g. a beer batch) is a deployed instance.

**Key storage (post-upgrade):**
- `string _contractCID`, `mapping(uint256 => string) _tokenCIDs`, `uint256 nextTokenId`
- `mapping(uint256 => bool) redeemed`, `mapping(uint256 => string) _redeemedCIDs`
- `mapping(address => bool) redemptionOperator`
- `mapping(address => bool) isMinter` ← NEW

**Key functions:**
- `mint(address, string cid)` — isMinter or owner
- `mintBatch(address, string[] cids)` — isMinter or owner; returns `startTokenId`
- `setMinter(address, bool)` — onlyOwner
- `setTokenCID(uint256 tokenId, string newCID)` — onlyOwner; fixes metadata post-mint (typos etc.)
- `setRedeemedCID(uint256 tokenId, string cid)` — onlyOwner; sets post-redemption variant URI
- `redeem(uint256 tokenId)` — holder, approved operator, or redemptionOperator
- `markRedeemed(uint256 tokenId)` — onlyOwner
- `setRedemptionOperator(address, bool)` — onlyOwner

**Gap:** `uint256[43]`

---

## Marketplace.sol (`contracts/marketplace/`)
Handles listings, sales, and redemptions.

**Key storage (current):**
- `address tokenDeployer`, `address nftDeployer`, `address feeCollector`
- `mapping(uint256 => Listing) _listings`, `uint256 nextListingId`
- `mapping(uint256 => uint256) _listingBatch` — listingId → batchId (0 = no stake)
- `mapping(uint256 => uint256) _tokenListingId` — tokenId → listingId+1 (0 = untracked)
- `mapping(uint256 => uint256) _escrowedBeer` — tokenId → escrowed $BEER amount, burned on redeem
- `address public relay` — best-effort attestation relay (set via `setRelay`)
- `address public farmToken` — $FARM token for quantum messaging subsidy collection
- `mapping(uint256 => uint256) private _subsidyBalance` — listingId → $FARM held for quantum delivery messages

**Key functions (current):**
- `createListing(nftContract, paymentToken, price, batchId, subsidyCount)` — `subsidyCount > 0` collects `subsidyCount * relay.quantumFee()` $FARM upfront; owner can pass batchId=0
- `depositInventory / withdrawInventory / setActive / updatePrice` — owner or listing.proceeds; `setActive(false)` auto-returns unused $FARM subsidy balance to seller
- `buy(listingId)` — platform fee → Treasury; remainder held in `_escrowedBeer[tokenId]` (NOT sent to brewer)
- `redeem(nftContract, tokenId)` — burns escrowed $BEER, calls `Treasury.onRedeem(batchId)`, then best-effort `relay.recordRedemption()`
- `getTokenListing(tokenId)` — view; returns `(listingId, batchId)` for any token sold via marketplace
- `chargeSubsidy(nftContract, tokenId, fee)` — relay-only; decrements `_subsidyBalance[listingId]`, burns $FARM; returns false if insufficient balance (sender pays normally)
- `reclaimSubsidy(listingId)` — seller or owner; manually reclaims unused $FARM
- `subsidyBalance(listingId)` — view
- `setRelay(address)`, `setFarmToken(address)` — onlyOwner

**Gap:** `uint256[39]`

---

## Treasury.sol (`contracts/treasury/`)
Fee governance, ETH floor accumulation, NFT vending, $BEER stake management, and LP reward minting.

**Key storage (current):**
- `address tokenDeployer`, `address nftDeployer`, `address dexFactory`
- `uint256 dexEntryFeeBps`, `uint256 dexExitFeeBps`, `uint256 marketplaceFeeBps`
- `uint256 accumulatedFees`, `mapping(address => uint256) nftPrices`
- `address farmToken`, `uint256 farmStakeBps`, `uint256 farmLpBps` ← repurposed from dead beerToken/stakeRatioBps/minListingBalance slots; $FARM emitted at DEX spot price proportional to ETH staked/LP reward
- `uint256 nextBatchId`, `mapping(uint256 => Batch) batches`, `mapping(address => bool) isTrustedCaller`
- `address weth`, `uint256 lpRewardFeeBps`
- `mapping(uint256 => uint256) _claimedAmount` — ETH claimed per batchId (partial claim tracking)

**Key functions (current):**
- `postStake(token, nftContract, cids[], tokenToEmit)` payable → batchId — accepts ANY registered token (not hardcoded beerToken); ETH = permanent floor; token minted to producer; NFTs minted to producer; `cumulativeStake[sender] += msg.value`
- `attestationTier(wallet)` — view; derives tier 0-3 from `cumulativeStake[wallet]` vs `tierThreshold[]`; no manual calls needed
- `setTierThreshold(tier, ethAmount)` — onlyOwner; sets ETH threshold for each tier (1=holder, 2=producer, 3=verified)
- `markListed(batchId, listingId)` — isTrustedCaller only
- `onRedeem(batchId)` — isTrustedCaller only; increments redeemedCount only (no transfer — ETH becomes claimable)
- `claimStake(batchId)` — producer pulls pro-rata ETH; `earned = stakedAmount * redeemedCount / totalNFTs - claimedAmount[batchId]`
- `claimableStake(batchId)` — view; frontend read for claimable ETH
- `slashStake(batchId)` — onlyOwner; forfeits unclaimed ETH to floor permanently
- `receiveAndMintLPReward(rewardToken, to)` payable — isTrustedCaller; converts ETH to tokens at spot, mints to LP holder
- `withdrawFees(to, amount)` — onlyOwner; draws from `accumulatedFees` only, never touches floor
- `floorBalance()` — `address(this).balance - accumulatedFees`; permanent, structurally untouchable
- `mintLaborReward(token, to, amount)` — onlyOwner

**Gap:** `uint256[31]`

**Deployment note:** `stakeRatioBps` and `minListingBalance` state vars remain but unused in postStake path.

## DEXPair.sol (`contracts/dex/`)
AMM pair, BeaconProxy. All pairs upgraded simultaneously via `Factory.upgradePairs(newImpl)`.

**Key storage (current):**
- `address factory`, `address token0`, `address token1`, `address weth`
- `uint112 reserve0`, `uint112 reserve1`, `uint32 blockTimestampLast`
- `uint256 price0CumulativeLast`, `uint256 price1CumulativeLast`, `uint256 kLast`
- `address rewardsTreasury`, `uint256 rewardPerTokenStored` ← NEW
- `mapping(address => uint256) userRewardPerTokenPaid`, `mapping(address => uint256) pendingRewards` ← NEW

**Key functions:**
- `rewardToken()` — view, derived: `token0 == weth ? token1 : token0`
- `claimRewards(address account)` — updates reward snapshot, forwards accrued ETH to Treasury, Treasury mints tokens to account
- `setRewardsTreasury(address)` — factory-only
- `receive()` payable — accumulates reward ETH into `rewardPerTokenStored`
- `mint(address to)` — calls `_updateReward(to)` before minting LP
- `burn(address to)` — standard LP removal (Router calls claimRewards before burn)

**Gap:** `uint256[38]`

## DEXFactory.sol (`contracts/dex/`)
UUPS upgradeable. Manages BeaconProxy pair creation and LP reward configuration.

**Key storage (current):**
- `address beacon`, `address feeTo`, `address feeToSetter`, `address tokenDeployer`
- `mapping(address => mapping(address => address)) getPair`, `address[] allPairs`
- `address pairTreasury` ← NEW — auto-wired to new pairs on creation

**Key functions:**
- `createPair(tokenA, tokenB, weth)` — now also calls `setRewardsTreasury(pairTreasury)` on new pair if set
- `upgradePairs(newImpl)` — upgrades all pairs simultaneously via beacon
- `setPairTreasury(address)` — onlyOwner ← NEW
- `batchConfigurePairRewards(address[] pairs)` — migrates existing pairs ← NEW

**Gap:** `uint256[43]`

## Router.sol (`contracts/dex/`)
NOT upgradeable — immutable constructor args (factory, WETH, treasury). Requires fresh deploy on any change.

**Current exit fee split (token → ETH):**
- `lpReward = ethOut * lpRewardFeeBps / 10000` → sent to exit pair (accumulates as LP rewards)
- `treasuryFee = ethOut * dexExitFeeBps / 10000 - lpReward` → sent to Treasury
- `userProceeds = ethOut - lpReward - treasuryFee`

**`removeLiquidityETH`:** calls `pair.claimRewards(msg.sender)` before transferring LP tokens — auto-claim fires before balance drops to zero.

**Why:** [[project_beer_dex]] [[project_lp_rewards]]
