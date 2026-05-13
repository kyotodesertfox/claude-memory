---
name: project_lp_rewards
description: LP reward system design — per-pool token rewards funded by exit fee split, built 2026-05-13
metadata:
  type: project
---

## What it does

LP holders earn their pool's native token as a reward for providing liquidity. Rewards are funded by a 2% slice of the DEX exit fee. The remaining 3% goes to Treasury floor as before. Total exit fee (5%) is unchanged to the user.

- BEER/WETH pool LPs earn $BEER
- EGG/WETH pool LPs earn $EGG
- Future pools earn their respective token
- A future $FARM governance token may layer on top as a cross-pool emission — separate system, not designed yet

## Why this design

Without LP incentives, no one has reason to provide liquidity beyond speculative exposure. Rewarding LPs in the pool's own token aligns their interests directly with the token's success. Volume is the natural gate — if there's nothing to claim, there's nothing to claim. No artificial time locks.

## Fee split

Router splits exit fee at source:
- `lpFeeBps` (200 = 2%) → sent as native ETH directly to the exit pair contract
- `treasuryFee` (remaining 3%) → sent to Treasury as before
- Both values are governance-configurable via Treasury; `lpRewardFeeBps <= dexExitFeeBps` enforced

## How rewards accrue (Synthetix-style)

DexPair tracks `rewardPerTokenStored` — a running total of ETH reward per LP token (scaled 1e18). Every time the pair receives reward ETH (via `receive()`), this value ticks up proportional to total LP supply. Each LP holder has a `userRewardPerTokenPaid` snapshot — the difference between current and snapshot × their balance = their `earned()` amount.

`_updateReward(account)` is called on every `mint()` (add liquidity) to snapshot before the new LP is minted, preventing retroactive reward claims on new deposits.

## Claim flow

1. Router calls `pair.claimRewards(msg.sender)` before transferring LP tokens in `removeLiquidityETH` — auto-claim fires before balance drops to zero
2. Accrued ETH is sent from pair → Treasury via `receiveAndMintLPReward(rewardToken, to)`
3. Treasury calculates token amount at spot price from live pair reserves: `tokenOut = ethValue * tokenReserve / wethReserve`
4. Treasury mints tokens directly to LP holder's wallet
5. ETH stays in Treasury as **permanent floor** — not added to `accumulatedFees`, never withdrawable
6. LP holders can also call `pair.claimRewards(address)` directly at any time (mid-hold claim)

## Treasury protection guarantee

Every single claim increases the Treasury floor. ETH flows in, tokens are minted out. Same economic engine as `postStake` — different source (accumulated fees vs. brewer capital), same outcome (ETH→floor, tokens→user). No value sink possible.

## Pending tasks / known gaps

- `postStake` still takes $BEER collateral — needs redesign to be ETH-payable (separate task)
- If pair receives reward ETH when `totalSupply == 0`, ETH sits in contract until first LP claim (edge case — can't happen in practice since no swaps without liquidity)
- LP-to-LP direct transfers (not via Router) bypass auto-claim — acceptable edge case, users must manually claim before transferring LP tokens outside Router

## Files changed (commit 782399b)

- `contracts/dex/DexPair.sol` — reward storage + receive() + claimRewards + mint() hook
- `contracts/dex/Factory.sol` — pairTreasury storage + auto-configure on createPair + batchConfigurePairRewards
- `contracts/dex/Router.sol` — fee split + claimRewards call in removeLiquidityETH
- `contracts/dex/Interfaces.sol` — IDEXPair interface + lpRewardFeeBps/receiveAndMintLPReward on ITreasury
- `contracts/treasury/Treasury.sol` — receiveAndMintLPReward + weth + lpRewardFeeBps storage

**Why:** [[project_philosophy]] — no value sinks; [[project_beer_dex]] — LP incentives needed for real liquidity depth
