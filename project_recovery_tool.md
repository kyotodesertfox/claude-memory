---
name: project-recovery-tool
description: "NFT Recovery tool in loopring-explorer - wallet lookup behavior, CID verification flow, architecture, known limitations, bug history"
metadata:
  type: project
---

## NFT Recovery Tool (`pages/recover/index.tsx`)

Wallet address lookup → The Graph query for minted NFTs → CID reconstruction → IPFS availability check → SHA-256 file verification.

## Known Limitation: Smart Wallet Addresses Only

The recovery tool only works for Loopring **smart contract wallet addresses**. The lookup queries The Graph `accounts` entity by `address` field, which maps to the Loopring account registered address. Users who never registered a Loopring account (EOA-only users) will return no results.

**Why:** Minting on Loopring L2 required a registered account with a Loopring account ID. The `nonFungibleTokens` minter field is keyed by that account ID, not the raw Ethereum address.

**How to apply:** If a user gets "No Loopring account found," they either used a different address for their smart wallet, or never registered a Loopring account.

**Design implication:** This is not purely a bug - it is also a scope boundary. The tool targets **creators/minters**, not collectors. Only a minter would have the original source file needed for SHA-256 verification. Collectors who held but did not mint have no original file to verify against - that use case belongs to AD's rescue registry (claim by snapshot proof). The smart wallet requirement naturally filters toward the right user: someone who was active enough on Loopring L2 to register an account and mint original work.

This distinction is the core product differentiation:
- AD's tool: proves you HELD it (snapshot) → claim a copy
- This tool: proves you MADE it (calldata + original file) → verify and preserve the original

## Resolution Matrix

The recovery tool is a resolution engine - any node handed in resolves all connected nodes. The order of resolution matters critically: each layer depends on the one before being solid. A gap at any layer breaks everything downstream. Do not skip ahead.

```
eth address (user input)
    │
    ▼
account ID (numeric, e.g. "33443")         ← FIND_ACCOUNT query: accounts(where: { address })
    │                                          CRITICAL: account.id is NUMERIC STRING, not eth address
    │                                          account.address = eth address (stored separately)
    │                                          These are two different values - never conflate them
    ▼
nftID[] + token[] (collection addresses)   ← MINTED_NFTS query: nonFungibleTokens(where: { minter: accountId })
    │              │                           minter field = numeric account ID, NOT eth address
    │              │                           reverse lookup (eth addr as minter) returns nothing
    │              │                           pagination: first:100, skip:N, loop until batch < limit
    │              ▼
    │         collection name              ← ethers call: new Contract(token, ['function name() view returns (string)'], provider).name()
    │                                         provider = INFURA_ENDPOINT from utils/config.ts (already in project)
    │                                         one call per UNIQUE collection address (deduplicate first)
    │                                         result: human-readable label for grouping cards
    ▼
CIDv0 (IPFS content identifier)            ← MATHEMATICAL - no query, no network call
    │                                         nftID is sha2-256 digest of original IPFS content
    │                                         CIDv0 = base58( 0x12 || 0x20 || nftID_bytes )
    │                                         same algorithm as Loopring's own IPFS.sol library
    │                                         same algorithm as decode.tsx
    ▼
CID availability (live / gone / unknown)   ← /api/ipfs-check proxy route (server-side, avoids CORS)
    │                                         tries cloudflare-ipfs, gateway.pinata.cloud, ipfs.io in sequence
    │                                         5s timeout per gateway, returns first success
    │                                         batch in groups of 5 to avoid hammering gateways
    │                                         most Loopring content = gone (Loopring infra offline)
    ▼ (if gone)
SHA-256 file verification                  ← WebCrypto: crypto.subtle.digest('SHA-256', file.arrayBuffer())
    │                                         sha256(originalFile) === nftID  →  verified authentic
    │                                         this is the cryptographic proof no other tool provides
    │                                         snapshot-based tools (AD's rescue registry) cannot do this
    │                                         only the minter has the original file → tool targets creators
    ▼ (if match)
verified authentic → CID confirmed → re-pin to IPFS of creator's choice
```

**Why this order is non-negotiable:**
- Can't get nftIDs without account ID
- Can't reconstruct CID without nftID
- Can't check availability without CID
- Can't verify file without nftID to compare against
- Can't re-pin without verification (unverified re-pin is what AD's tool does - not this tool's purpose)

**Key facts confirmed from live query:**
- `account.id` = "33443" (numeric string - this is the Loopring L2 account number)
- `account.address` = "0xc22724df2f8d30db4ed2f3bff317897bfc2c494b" (eth address, stored separately)
- `nonFungibleTokens` entity ID format: `{ethAddress}-{accountType}-{collectionAddress}-{nftID}`
- `nonFungibleTokens.minter` = numeric account ID (e.g. "33443")
- `nonFungibleTokens.nftID` = 32-byte hex string (the content hash)
- `nonFungibleTokens.token` = collection contract address
- `nonFungibleTokens.nftType` = 0 (ERC1155) or 1 (ERC721)
- `NonFungibleToken_filter` supports `minter_starts_with`, `minter_contains` etc but NOT nested entity filters
- `id_starts_with` does NOT exist in the filter schema - only `id_gt`, `id_gte`

**The puzzle constraint:**
This is a giant puzzle where what you need on one side won't resolve unless you have the other side solved first. Each layer must be solid before building the next. The matrix is the architecture - not a feature, the foundation.

## Router Nuance: The Source Defines the Array (data-driven, not reverse-engineered)

**Core principle Justin insisted on:** build the array from what the source gives us, do NOT reverse-engineer a fixed field schema and force the data into it. The first pass did it backwards - a hardcoded `NFTSlot` with four hand-picked fields (`nftID, token, nftType, cid`), querying only those, imposing a shape. That is reverse-engineering the schema. Justin flagged it: "we should be building the array based on what it gives us, instead of reverse engineering it."

**The inversion:** the subgraph entity defines the dimensions. Introspect/query everything the entity exposes (`id, mintedAt, mintedAtTransaction, minter, nftType, token, creatorFeeBips, nftID, slots, transactions`), store the returned object verbatim, and render whatever keys came back. A new field in the subgraph appears automatically - zero code change.

**The record shape** (`NFTRecord`):
- `raw` - exactly what the subgraph returned for this NFT (the source-defined array)
- `cid`, `cidStatus`, `verifyStatus` - derived nodes that hang off `raw`

**The router:** each node knows how to resolve outward, and derived nodes hang off specific keys of `raw`:
- `nftID` -> `cid` (math) -> `availability` (ipfs-check)
- `token` -> collection identity (getCode/name via `/api/eth-call`)
- `nftID` -> `verify` (sha256 vs nftID)
- `mintedAtTransaction` -> L1 calldata (ties into `/decode`)
- `minter` -> account
The dictionary is: what the source gave us + what each of those resolves into. Hand in any node, resolve the connected nodes.

**Rendering is generic, not hand-written:** the card iterates `Object.entries(raw)` and renders each key via a `FIELD_LABELS` map + a generic `RawValue` component (handles scalars, nested entities via `.address`/`.id`, timestamps, hex). Special-case only where a key has a resolver (`token` -> `CollectionValue`). Derived nodes (CID, recovery panel) render after the raw fields. No per-field JSX by hand.

**Why this matters (the "why"):** the metadata everyone assumes died with Loopring is mostly regenerable by traversal - but only if the structure is defined by what survived, not by what we guessed should be there. The content-level metadata (name/image, inside the unpinned metadata JSON at the reconstructed CID) is the one part genuinely gone until the creator re-supplies it; the on-chain provenance (mintedAt, mint tx, minter, fee, type) is all still in the Graph and now surfaces automatically because we stopped hand-picking fields.

## Reconstruction Engine Architecture (current implementation)

`useRecoveryEngine()` custom hook manages all state; records identity-keyed by `raw.nftID`:
- `AccountSlot` - eth address + numeric accountId + resolution status
- `NFTRecord` - `raw` (source object) + derived `cid`, `cidStatus`, `verifyStatus`
- `CollectionSlot` - collection address + name() result + resolution status
- `RecoveryState` - account, nfts[], collections{}, phase, error

State fills progressively: account resolves first, then NFTs paginate (full enumeration, one query per page), then CID reconstruction (sync, at enumeration), then collection identity (parallel per unique token via `/api/eth-call`), then availability lazily per card on viewport entry (IntersectionObserver, `requested` ref fires once).

**Wallet-agnostic core + one seam:** the read/reconstruction matrix is identical for EOA and smart wallets - nothing forks. Wallet type only matters at the control-proof seam (proving you ARE the minter address: EOA `ecrecover` vs smart-wallet EIP-1271), which is a shim on top, invoked only by actions that must bind to the minter (authorized re-pin, payment). Content proof (sha256==nftID) is wallet-agnostic and is the load-bearing proof. See [[project-recovery-wallet-compat]] if split out later.

`patchRecord(nftID, patch)` is the single state-update helper (find by `raw.nftID`, shallow-merge). `verifyFile`/`resetVerify`/`checkAvailability` all route through it. UI is purely reactive.

**checkAvailability bug (fixed):** never read a value back out of a `setState` updater for control flow - updaters run during render, not synchronously, so the guard variable is still false at the call site and the fetch gets skipped (cards stuck on "checking" forever). Fix: the card passes the reconstructed `cid` directly into `checkAvailability(nftID, cid)`.

Queries use raw fetch to `/api/graphql` (not Apollo). See [[feedback-apollo-programmatic]].

Page is client-only: mounted guard pattern (`useState(false)` + `useEffect` setMounted) prevents SSR. See [[feedback-nextjs-ssr-dynamic]].

**ipfs-check races gateways in parallel** (`Promise.any`, 4s timeout) - was sequential 3x5s=15s, now ~4s. Loopring content resolves "gone" (infra offline); the check gates whether the recovery panel opens.

`NFT_PAGE_SIZE = 100`, `MAX_PAGES = 200`.

## Bugs Discovered and Fixed

**Apollo useLazyQuery in while loop** - Returns stale data from previous call regardless of changed variables. Every iteration of the pagination loop got the same first NFT, causing infinite accumulation. Fixed by switching to `useApolloClient` / `client.query()`, which also failed - see next.

**Apollo client.query() also loops** - `keyArgs: false` on `nonFungibleTokens` in the Apollo cache config interacts with re-renders. Clicking any card triggers a re-render; under some conditions this re-triggered GraphQL queries. Root cause unclear but eliminated by removing Apollo from the engine entirely. Fixed by switching to raw fetch.

**Next.js 12 server bundle missing** - Client bundle compiles fine at `.next/static/chunks/pages/recover.js`, but server bundle at `.next/server/pages/recover.js` never gets created. ENOENT thrown on every page request. Likely cause: heavy dependency tree (full ethers ESM, ~3.3MB client chunk) causes server webpack compilation to fail or stall in dev mode. Fixed by skipping SSR.

**dynamic(() => Promise.resolve(Component)) remount trap** - Creates a new Promise reference on every render. `dynamic()` may re-evaluate the factory, causing the component to unmount and remount, resetting all hook state. Fixed by using a mounted guard instead.

**NFT_PAGE_SIZE = 1 never terminates** - With first:1, each batch returns 1 NFT. Break condition `batch.length < NFT_PAGE_SIZE` = `1 < 1` = false, so it never breaks until all NFTs are exhausted plus one empty batch. With 68 NFTs that's 69 sequential queries. Looked like an infinite loop. Fixed by setting NFT_PAGE_SIZE = 100.

## What Works (confirmed against Justin's wallet, account ID 33443)

- 68 NFTs load in one query (first:100, 68 returned, `68 < 100` breaks loop)
- CID reconstruction correct for all 68
- CID availability: all 68 gone (expected - Loopring IPFS infrastructure offline)
- SHA-256 verify UI wired and tested
- Collection name() resolver wired, fires once per unique token address

## UX Problem: No Metadata

Cards show collection address, nftID, IPFS CID - but no names or images because IPFS content is gone. Creators with many mints cannot identify which card is which without knowing their nftIDs.

**Partial fix:** Call `name()` on the collection contract (CounterfactualNFT) via the Infura/ZAN endpoint to at least label cards by collection name. This is implemented.

## Community Actors

| Handle | Wallet | Notes |
|---|---|---|
| Autodestructive | `0xC7Eaf32B4141FC4a0984A501D41Da6F06Be13bB6` | Built LoopringRescueRegistry - Merkle-gated ERC-1155 rescue contract anchored to Loopring's official snapshot. Exit-liquidity motivated. Full technical conversation on provenance distinction is preserved in `/receipts/`. |
