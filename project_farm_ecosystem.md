---
name: project-farm-ecosystem
description: The broader FarmDEX ecosystem — TokenDeployer factory + masterTemplate ERC20 + DEX/Marketplace form a single physical-goods tokenization platform
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

The DEX repo (/home/zenko/github/Taiko/DEX) is ONE layer of a larger "FarmDEX" system.
The token factory lives at /home/zenko/github/farm/solidity.

**Full ecosystem architecture:**

1. **TokenDeployer** (farm/solidity/tokenDeployer.sol) — ERC1967Proxy factory
   - Owner deploys new ERC20 tokens from a shared masterTemplate "Gold Image"
   - Each physical production project (beer, wine, hops, etc.) gets its own token via deployNewToken()
   - Template can be upgraded via updateTemplate() for all future deployments

2. **masterTemplate** (farm/solidity/masterTemplate.sol) — UUPS upgradeable ERC20
   - isMinter mapping: multiple wallets/bots can mint (owner + registered minters)
   - mintToWallet(address, amount): mint directly to a user wallet
   - mintToPool(address, amount): mint to a DEX pool AND call IFarmDEX.onTokenMinted() callback
   - burnFromSupply(address, amount): emergency owner burn (to be removed after testing)
   - pause()/unpause(): emergency stop
   - updateMetadata(name, symbol): post-deploy name/symbol override
   - __gap[50]: 50 slots reserved for future storage variables
   - IFarmDEX interface: { onTokenMinted(uint256 amount) } — the DEX must implement this

3. **DEX** (Taiko/DEX) — AMM + Marketplace (see [[project-beer-dex]])
   - Must implement IFarmDEX.onTokenMinted() on the relevant pool/pair contract
   - $BEER (and other tokens) are minted here when physical stock is confirmed

**The core flow across the full system:**
Producer confirms physical stock exists
  → calls mintToPool($BEER contract, pool address, amount)
  → $BEER tokens appear in the DEX pool
  → DEX.onTokenMinted() is called to update internal inventory state
  → tokens are now tradeable on the AMM
  → users buy $BEER via DEX
  → users spend $BEER on BeerMarketplace → receive NFT redemption voucher
  → user redeems NFT at brewery → NFT burned + $BEER burned → physical goods exchanged

**Key design point:** mintToPool + IFarmDEX callback is the link between the token layer and the DEX layer. The DEX pair/pool needs to implement onTokenMinted(). Currently no contract in Taiko/DEX implements this interface.

**Fee terminology (locked):** Always call these "platform fees" — never "swap fees", "exit tax", "penalty", or "LP fees" in code comments, UI copy, or documentation.

**Platform fee structure:**
- Entry (ETH → token): flat ETH amount, initialized at 0 (free) — upgradeable via setEntryFee()
- Exit (token → ETH): 500 bps (5%) initial value — upgradeable via setExitFee(), lower over time as liquidity deepens
- No USDC support, ever — users who want stable must handle ETH→USDC off-platform themselves
- All platform fees route to Treasury
- Both fees live in the Router (direction-aware: path[0]==WETH = entry, path[last]==WETH = exit)

**Core design principles (locked):**
- Everything must be UUPS upgradeable from day one — full mutability now, progressive lockdown later
- TokenDeployer itself must become UUPS upgradeable (currently plain Ownable — needs fixing)
- NFT contracts mirror the token pattern: nftTemplate (UUPS ERC721) + NFTDeployer (UUPS factory) with its own isRegistered registry
- Marketplace requires BOTH TokenDeployer.isRegistered(paymentToken) AND NFTDeployer.isRegistered(nftContract) — dual trust chain
- NO product-specific naming in contracts, functions, or variables. Names describe behavior, not the product. Identity lives in data (token address, metadata URI), not code.
  - Bad: BeerNFT, mintBeer(), BeerMarketplace
  - Good: InventoryNFT, mint(), Marketplace, createSKU()

**Why:** Building a multi-producer physical goods tokenization platform on Taiko. $BEER is first; the same TokenDeployer can spin up $WINE, $HOPS, etc. with identical logic.

**How to apply:** When working on any contract, function, or variable: (1) check it is UUPS upgradeable, (2) check it is connected to the TokenDeployer/NFTDeployer trust hierarchy, (3) check no product-specific names are used. These are non-negotiable constraints.
