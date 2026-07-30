---
name: project_nft_beacon
description: "NFTDeployer two-track beacon architecture — design decisions, why no external registration, orphan plan for old collections, deploy sequencing"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4fca475b-7391-4d9c-925e-3a7e146c1864
---

## Decision: Two-track NFTDeployer with UpgradeableBeacon

**Status:** Implemented in this session (2026-06-21). New `nftDeployer.sol` written. Requires fresh proxy deploy (not upgrade of old deployer).

**Old deployer proxy (0x2A879059CfA27f707F1756DbfC6f683071099cC9):** orphaned. Do not use. Old source archived at `contracts/nftDeployer_old/` (gitignored).

---

## Two-Track Architecture

**`deployCollection(name, symbol, contractCID, owner)`**
- Standard path
- Deploys a BeaconProxy pointing at the shared UpgradeableBeacon
- Auto-registered in `isRegistered`
- One beacon upgrade propagates to all standard collections simultaneously

**`deployCustomCollection(impl, name, symbol, contractCID, owner)`**
- Custom path
- Requires `approvedImplementations[impl] == true` - reverts otherwise
- Deploys an ERC1967Proxy pointing at the approved impl
- Auto-registered in `isRegistered`

Both functions write to the same `isRegistered` mapping. Downstream contracts (Marketplace, Treasury) see no difference between tracks - they check `isRegistered` only.

---

## Platform Rule: No External Registration - Ever

`isRegistered` can only be written by NFTDeployer's own deploy functions. There is no `registerExternal`, no owner bypass, no governance path to register an arbitrary address. This is a permanent, immovable platform decision.

**Why:** The `isRegistered` check is the trust boundary protecting Treasury. An externally-registered contract could manipulate redemption flow with no accountability. Deploy-from-within is the protection. If it wasn't deployed from within NFTDeployer, it doesn't belong on the platform. No future governance decision can override this - it is structural, not configurable.

---

## Approved Implementations Whitelist (Custom Track)

- `mapping(address => bool) public approvedImplementations`
- `approveImplementation(address) onlyOwner` - adds to whitelist
- `revokeImplementation(address) onlyOwner` - removes from whitelist, does NOT affect already-deployed collections
- The approval step (reviewing and whitelisting an impl) is the governance gate, not registration
- The standard beacon impl is the canonical approved implementation; custom impls require explicit owner approval of the code first

---

## Orphaned Collections

- **BEER NFT** (0x210970F39B3AD4081090100Ed871fE42C54C2101) - orphaned ERC1967Proxy, no trades/transactions
- **EGG NFT** (0xB90bC6186bA7d480584E06F92ecb15DAf653DE5C) - orphaned ERC1967Proxy, no trades/transactions

ERC1967Proxies cannot be converted to BeaconProxies - proxy bytecode is immutable. Migration is architecturally impossible. Clean break: orphan both, redeploy fresh as BeaconProxies through new NFTDeployer. Burning existing tokens is optional cleanup, not required (no state worth preserving).

---

## Storage Layout (new NFTDeployer, slots 0-49, gap = 46)

```
0: beacon (address) - shared UpgradeableBeacon for standard collections
1: isRegistered (mapping)
2: allContracts (address[])
3: approvedImplementations (mapping)
4-49: __gap[46]
```

VERSION = 2

---

## Deploy Sequencing

**PREREQUISITE:** UpgradeableBeacon must be deployed BEFORE NFTDeployer. NFTDeployer's `initialize(_beacon, _initialOwner)` takes the beacon address as its first argument - it does not deploy the beacon itself. Deploy order matters.

**This is a fresh proxy deploy - NOT an upgrade of the old deployer (0x2A879059...).** Deploy a new impl + new ERC1967Proxy. Old deployer is orphaned.

1. Deploy UpgradeableBeacon pointing at current nftTemplate impl (`0x637f1f6FD0fF64dF0C920C43B4945779EA706fa2`), owned by platform owner
2. Deploy new NFTDeployer impl + ERC1967Proxy, call `initialize(beaconAddress, ownerAddress)` on proxy
3. Redeploy BEER NFT collection via `deployCollection` - new BeaconProxy address
4. Redeploy EGG NFT collection via `deployCollection` - new BeaconProxy address
5. Run setter batch on new collections: `setMinter(treasury)`, `setRedemptionOperator(marketplace)`
6. Update `contracts.js` + `.env` with new deployer proxy + new collection addresses

Setter batch runs AFTER architecture is stable - not before. Partial deployment with unset parameters is an attack surface. One coherent pass covers everything.

---

## Lifecycle Intent

- Bootstrap: beacon owned by Justin, upgrades fast and clean
- Growth: producers get operational control (mint, CIDs, roles) - platform retains implementation control via beacon
- Maturity: beacon ownership - timelock - DAO or renounced
- End state: collections immutable, beacon was scaffolding

**Why:** [[project_contracts]]

---

## Addendum (pre-implementation draft, folded in from superseded copy)

Content below predates the implemented architecture above and was recovered from an earlier "decided, not yet implemented" draft. The two pieces not already captured above:

**Custom collections tied to a tier system:**
- Standard producers: BeaconProxy (platform-managed). Homestead upgrades, producer owns the tokens.
- High-tier attested producers: custom collection, self-governed. Producer owns the implementation and upgrade authority - can extend beyond the standard template (royalty logic, burn mechanics, metadata extensions) without waiting on a beacon upgrade.
- Marketplace/Treasury don't care which proxy type - they only check `isRegistered()`.
- The tier gate is the trust model: a producer who has earned high-tier attestation has history and skin in the game, which justifies implementation control.
- This maps onto the implemented two-track architecture above: standard track = `deployCollection` (BeaconProxy), custom track = `deployCustomCollection` (ERC1967Proxy against an approved impl).

**Deploy-line pattern (general lesson, not beacon-specific):**
Features never make it to chain because each feature reveals the next one, and gas cost of constant upgrades makes iterating on-chain expensive. The correct pattern: build until stable enough to justify a deploy, then push everything at once. The problem is "stable enough" keeps moving - the custom collections / tier decision was the piece that had been stalling the deploy line. Once an ownership model is decided, the next deploy pass should draw a hard line and push everything up to that point regardless of what the next feature implies.
