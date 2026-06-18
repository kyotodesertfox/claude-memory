---
name: project_unit_scaling
description: "Unit scaling architecture decision — separate indivisible goods (NFT) from divisible money (fungible token); 1:1 integrity enforced at four operations, not via token decimals; control model and pending refactor"
metadata:
  node_type: memory
  type: project
  originSessionId: 2026-06-17-unit-scaling
---

## The bug that started this

Minting 10 tokens produced an astronomical balance (a 1e18-factor magnitude error from scaling happening in the wrong place / twice). Justin's fix was `_toBase` in the contracts so the UI never scales, reasoning that UI-side scaling lets future integrations break. Goal: solve scaling at the contract level so it can't break.

## The core finding (why _toBase is not a guarantee)

A `uint256` carries no unit tag. `10` and `10e18` are both just numbers; the contract cannot detect whether input was already scaled. So `_toBase` does not eliminate the ambiguity between "10 tokens" and "10 base units" — it relocates the convention. The ambiguity is structural to `uint256`. Worse for Justin's stated goal: `_toBase` makes ON-CHAIN integration *more* surprising, because the universal EVM assumption is base units (`balanceOf`, `approve`, `transfer` all base). An integrator following that default passes base units to a human-units function and gets the same bug inverted (`_toBase(10e18) = 1e37`). `_toBase` protected the UI (the surface that bit him) at the cost of the integration surface he says he cares about.

## The reframe that resolves it (locked 2026-06-17)

**Indivisibility belongs to the GOOD, not the MONEY.** "I cannot sell a fraction of an egg" is true — but the egg is the NFT (ERC721), not the fungible token. One carton = one ERC721 = priced at 12 EGG. You already cannot own 0.5 of an NFT; ERC721 enforces that for free. `$EGG` is not the egg — it is money denominated in eggs. Money is divisible; the good is not.

**Proof the whole-number-token invariant was never holding:** the moment anyone swaps ETH→EGG, `getAmountOut` returns an arbitrary base-unit number (e.g. 11.73 EGG) — constant-product math never yields clean multiples of 1e18. Fractional EGG balances have existed since the first swap. `_toBase` only ever enforced whole numbers at mint amount and listing price, never on balances, and couldn't (the token is AMM-traded). The LP reward path is the second proof — see "live evidence" below.

**Where the 1:1 promise actually lives — the four operations:** mint (`openLot`), escrow (`mintLotNFTs`), list/buy (Marketplace `createListing`/`buy`), redeem/burn. Every step that carries integrity is whole by nature, enforced BY THE OPERATION, not by token decimals. A swap is none of those — it moves money, never mints/escrows/burns a claim. Fractional money in a wallet is not a fractional claim; it is purchasing power not yet assembled into a whole claim (the NFT).

## The control model (each guard matched to its actual threat)

1. **Whole-claim integrity** → `require(amount > 0 && amount % 1e18 == 0 && amount <= MAX)` at the four operations. In base units a whole token is 1e18, so "1:1 backing, no fractional claims" IS the modulo check. This is the four-operations policing written in code.
2. **Producer over-mint** → the existing 110% collateral ratio (`openLot` checks `stkBalance >= usedCollateral + 110% of lot ETH value at spot`). NO fixed cap on `openLot` — a constant can't scale with the staker (too low blocks legit large producers, too high guards nothing). The ratio is the superior bound: denominated in ETH value against the floor, proportional to skin in the game. A fat-finger of 10 billion tokens reverts because they lack the stake to back it.
3. **Admin over-mint** → fixed plausibility cap on the ONLY uncollateralized mint path (`Treasury.issueTokens` → `mintToWallet`). No economic backstop exists there, so a hard cap sized to real admin-favor scale is the only protection. KEEP this path human-units (deliberate exception): it is hand-typed and `isMinter`/`onlyOwner`-gated, NOT an integration surface — base units would mean typing 19 digits for 10 tokens (more error surface, no benefit). Convention is irrelevant to magnitude typos; only the cap catches them.
4. **UI double-scale** → base units everywhere on integration surfaces + scaling done exactly ONCE in shared `contracts.js` (imported by both exchange and companion). Respects the no-`parseUnits`-in-UI rule's spirit (that rule was against *scattered* component scaling, not one shared chokepoint).

## Whole-number swap UX (without mutilating the token)

Buyers should target whole token amounts. Do it with **exact-output swaps**: `swapETHForExactTokens` (user says "exactly 12 EGG", contract computes fractional ETH input via `getAmountIn`). ETH input being fractional is fine — ETH is the rail, nobody redeems it for a physical good. Producer's redeem-side swap is the mirror (whole EGG in, fractional ETH out). AMM math and LP rewards stay fractional underneath. Router already has `getAmountsIn`; needs the exact-output *swap* execution function added.

## Why decimals stay at 18 (0-decimals rejected)

0-decimals would make double-scaling structurally impossible (human === base, no scaling anywhere). Rejected because the commodity token is ALSO the LP reward token, and Synthetix-style accrual pays fractional rewards — at 0 decimals an LP earning 0.5 EGG gets 0. Plus stkHomestead is wei-fractional (minted 1:1 with ETH via `mintExact`). 18 decimals is forced; scaling must exist somewhere; the only question was where the single source of truth lives.

## Live evidence in code (confirmed 2026-06-17 source read)

- `Treasury.receiveAndMintLPReward` (line ~642): `tokenHuman = _quoteTokensForEth(...) / 1e18; mintToWallet(to, tokenHuman)`. LP rewards are ALREADY floored to whole tokens; sub-1-token reward hits `ZeroReward` and reverts. This is the fractional-reward problem in deployed code — confirms the money layer must keep sub-unit precision.
- `_toBase` defined Treasury line ~183. Used in `openLot` (`tokenAmount`), `mintLotNFTs` (`tokenPerNFT` → `tokenPerNFTBase`), `burnLotTokens`.
- `Treasury.issueTokens` (line ~233, onlyOwner) and `masterTemplate.mintToWallet`/`mintToPool` (`amount * 1e18`) are the human→scaled admin mints.
- `Marketplace.createListing` line ~137 and `updatePrice` line ~232 store `price * 1e18`. `buy`/`redeem` already operate in base units.
- Router fully base-units / AMM-native; `getAmountsIn` present (line ~240), no exact-output swap fn yet.

## TokenDeployer / token transfers (checked 2026-06-17)

No whole-number TRANSFER restriction exists — verified in source. `TokenDeployer` is a pure factory (deploys ERC1967 proxies of masterTemplate, registers them; no token logic). `masterTemplate.transfer`/`transferFrom` are stock OZ ERC20Upgradeable (not overridden); `_update` only adds the pause check. Fractional money already moves freely today — a wallet can transfer 0.5 EGG. The ONLY whole-number coupling is mint-side `amount * 1e18` in `mintToWallet`/`mintToPool` (lines ~90/94), which is convenience-scaling on minted amounts, NOT a transfer guard. Already covered by the Release 1 refactor. Justin's recollection of a "transfer restriction" = this mint-side scaling. (Caveat: source-level finding; a deployed impl that once carried a transfer check would need bytecode verification, but current source has none.)

## Status & plan

Design agreed, NOT yet implemented. Fold into the **Release 1 Treasury upgrade** (see [[project_contracts]] pending releases) — tokens/contracts are not redeployed yet, so this rides along with already-pending upgrades. During the strategic pause; implement when Release 1 is cut.

Refactor scope when executed:
- **Treasury**: drop `_toBase`; `openLot`/`mintLotNFTs`/`burnLotTokens` take base units + `% 1e18 == 0` integrity require; `onRedeem` already returns base (internal inconsistency dissolves); `receiveAndMintLPReward` stops flooring (mint fractional reward via `mintExact`-style path, not human `mintToWallet`).
- **Marketplace**: `createListing`/`updatePrice` stop `* 1e18`, take base + integrity require.
- **Router**: add `swapETHForExactTokens` exact-output path for whole-number buy UX.
- **issueTokens / mintToWallet**: KEEP human-units, add fixed plausibility cap (the deliberate exception).
- **contracts.js + both frontends**: single scaling chokepoint; audit `OnboardingWizard` (already mixes `parseEther` and `BigInt` — the seam that caused the original bug).
- Bump `VERSION` in every changed `.sol` + `EXPECTED_VERSIONS` in `contracts.js`.

## DEXPair / DEXFactory parity (checked 2026-06-17)

Both are already on par — they ARE the downstream money layer the model prescribes, so no scaling changes needed.

- **DEXPair**: pure base-units AMM. ERC20 LP token (18 dec), reserves, swap amounts, `rewardPerTokenStored += msg.value*1e18/totalSupply`, `earned()` — all fractional, all base units. Never touches the four integrity operations (never mints/escrows/lists/redeems a claim). It is the canonical example of "money stays fractional." The LP-reward flooring bug is NOT here — the pair forwards fractional ETH correctly; `Treasury.receiveAndMintLPReward` is where it floors. Source already contains `claimRewards`/`rewardPerTokenStored`/`_updateReward` (Release 2 work) — ahead of the deployed beacon impl, not yet deployed.
- **DEXFactory**: registry/deployment only, no token amounts — orthogonal to unit scaling, nothing to change. CAVEAT (separate bug, flag to Justin): `initialize` assigns `feeToSetter = _feeToSetter` but `feeToSetter` was reserved out to `_reserved2` in commit e2119b2 — dangling reference, will not compile for a new impl deploy. Committed, not in working-tree diff.

Related: [[project]] (tokenomics, four-operation economic flow), [[project_contracts]] (storage layouts, release ordering).
