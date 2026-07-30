---
name: project-moody-brains
description: "Moody Brains dynamic-NFT contract - proves Loopring metadata resolves via on-chain uri() baseURI path, NOT CIDv0(nftID)"
metadata:
  type: reference
---

## Moody Brains (the key that corrected the recovery-tool model)

**L1 contract:** `0x1cACC96e5F01e2849E6036F25531A9A064D2FB5f` - DEPLOYED on Ethereum L1 (~12.5KB code). Dynamic NFTs (state changes over time).

**What it proved:** calling `uri(nftID)` on-chain returns, for a real token:
```
ipfs://<folderCID>/<tokenId-in-decimal>/<state>/metadata.json
e.g. ipfs://QmVYQaf5BP3y8Myr9m4z4FCZYx2v8NJmSHGzm2a2gqig9d/54489352.../2_2/metadata.json
```

So Loopring/GameStop NFT metadata resolves via an **on-chain `uri()` that returns a baseURI folder path** - `ipfs://<baseFolderCID>/<tokenIdDecimal>/<state>/metadata.json` - **NOT** `CIDv0(nftID)`. The `2_2` segment is the **dynamic state**; a dynamic NFT cannot live at an immutable content hash, which is exactly why `uri()` indirection exists.

**Why this matters for [[project-recovery-tool]] / [[project-recovery-repin]]:** the recovery tool reconstructed the metadata address as `CIDv0(nftID) = base58(0x12 0x20 || nftID)`. That is the WRONG address for baseURI-model NFTs - it points at something never pinned, which is why every gateway returned nothing and why creators' media never matched an nftID. The correct resolution is: `uri(nftID)` (on-chain, permanent) -> baseURI path -> `metadata.json` -> `image` CID -> media. The nftID here is a STRUCTURED token id (e.g. `0x0134661800...0001`), not a content hash.

**Consequence:** metadata location is recoverable from the deployed contract's `uri()` on-chain, and the folder CIDs are real/pinned. Justin's thesis ("they prepared for it; the link is there, we just hadn't found it") was correct. Open question: counterfactual (undeployed) collections can't be `uri()`-called on L1 - need to recover their baseURI another way (baked into the CREATE2 salt; possibly the mint calldata).

**nftID observed:** `0x0134661800000000000000000000000000000000000000000000000000000001` (token address `0x1cACC96e5F01e2849E6036F25531A9A064D2FB5f`).
