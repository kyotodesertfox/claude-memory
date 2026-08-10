---
name: project-loopring-recovery
description: "The job: present a JSON whose hash matches the nftID. The verified metadata format, the addressing model, what the tool code actually does, and the CREATE2 result. Not a recovery or reconstruction task - the creator already holds the bytes."
metadata: 
  node_type: memory
  type: project
  originSessionId: cbbd03b1-8886-4e2d-9be8-08400e9c318d
  modified: 2026-08-10T00:14:57.145Z
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.

# Loopring NFT Recovery

Supersedes `project_recovery_tool.md`, `project_recovery_repin.md` and
`project_moody_brains.md`, which carried contradictory versions of the resolution model
and at least one claim that is simply false (see "The EOA correction" below).

Protocol facts are in [[project-loopring-protocol]].

## THE JOB, STATED BY THE OWNER (2026-08-09) - read before anything else here

**Present a valid JSON that, when hashed, matches the fingerprint. Provide the bytes,
get the hash. That is the whole task.**

You are not fixing anything. You are not reconstructing anything. **You are presenting
something the creator already has.** They hold the image. They know the name and the
description they typed. The nftID IS the hash of a metadata JSON document. Assemble the
document, hash it, compare. It matches or it does not.

**The words in this file are wrong and they are why this keeps going sideways.**
"Recovery", "reconstruction", "restoration", "resurrection" all smuggle in the idea that
something is broken and a search must be run. Nothing is broken. There is a document, a
hash function, and a comparison. Every time this got framed as a search, the response was
to go derive something, invent a method, or re-implement a solved primitive - and the
actual question, what were the exact bytes, went untouched.

**Do not re-invent the wheel.** Hashing bytes to a CIDv0 is specified and solved
(UnixFS/dag-pb). Use the spec and a library. Two scripts that implemented it from first
principles were deleted on 2026-08-09 for exactly this reason. The open question is never
how to hash. It is only ever what the exact bytes were.

## What is provably rebuildable, and what is not

Demonstrated end to end on 2026-08-02 against live mainnet blocks:

**Provenance - fully rebuildable, unconditionally.** From raw L1 calldata alone, with no
cooperation from anyone and no surviving Loopring infrastructure: minter account ID,
nftID, creatorFeeBips, NFT standard, amount, storage ID, block and timestamp. Verified by
re-parsing the blocks out of the archive and anchoring on L1 transaction hash.
Every NFT ever minted on Loopring has this permanently recoverable. **This is the part
that proves authorship, and nobody else can produce it.**

Correction to the list above: **the collection address is not in the MINT**, which is 68
bytes and has no room for it. **But it IS in calldata** - NFT_DATA (type 9) transactions
carry it, 18,244 distinct nftIDs worth. See [[project-loopring-protocol]] for the layout.
Memory previously claimed NFT_DATA does not exist on mainnet; that was false and it cost a
whole detour through CREATE2 and L1 logs on 2026-08-09.

**Content - conditional, and the conditions are now measured rather than assumed.** Two
independent blockers:

1. *Addressing.* The `CIDv0 = base58(0x12 0x20 || nftID)` conversion itself is settled -
   it is Loopring's own canonical SDK implementation (see the SDK section below), not
   guesswork. What is NOT universal is whether a given `nftID` was *produced* that way.
   Live counterexample: collection `0x5f5d612de6fbd6923677ea3373bfe750bd156047` has
   `nftID = 0x00...0042` - the integer 66, a sequence number, so its reconstruction
   (`QmNLei78zW...`) is a valid address pointing at something never pinned. A sibling
   collection (`0x9c501909...`) uses a high-entropy hash-shaped nftID consistent with the
   SDK mint path. Same protocol, same era, two different origins. **Test the shape of the
   nftID first** - a low integer rules the SDK path out instantly, high entropy keeps it
   open.
2. *Retrieval.* Gateway 504s are inconclusive - they mean "no provider located in time,"
   not "gone." Probed `QmRwe29K3hEvfvPkJHKkUcamwzayWCKJ8PxZeXLmHRuzEF` across four
   gateways: all timed out or 504'd. Unknown, not negative. **The tool has no better test
   than read gateways** - `pages/api/ipfs-check.ts` races three of them, one of which
   (`cloudflare-ipfs.com`) has shut down. There is no `/api/probe`; earlier versions of
   this file claimed one existed.

**The gap worth naming.** Verification compares the creator's file against a *target*
media CID taken from the metadata JSON. If that JSON is unreachable there is no target -
you can hash the original perfectly and have nothing to check it against. For a
counterfactual collection with unreachable metadata AND a non-hash nftID, there is
currently no path at all. That is the honest edge of the product.

## Wallet type gates nothing

EOA or Loopring smart wallet, both register L2 accounts and both resolve from calldata.
The only real boundary is whether an L2 account was ever registered - no account means no
records, because they never transacted. Whether a collection is deployed affects metadata
resolution only, never who minted.

The tool targets **creators rather than collectors**, not because of any wallet filter,
but because only the person who minted holds the original file.

Narrative and the false claim this replaced: [[feedback-loopring-corrections]].

## The SDK settles the addressing question (2026-08-03)

**The single most important source, and it was never consulted until now.** `nftID` is
computed *client-side* at mint time, so the answer was never going to be in the
contracts - it is in Loopring's SDK. Cloned to
`~/github/lonewolf-loopring/loopring_sdk` (fork of `mobiledev-111-118/loopring_sdk`,
HEAD `852e9f6`, 2025-05-19).

## nftID <-> CID conversion, and what nftID addresses -> moved

**MOVED 2026-08-10 to [[project-loopring-nftid]].** That file now holds what
`nftID` is, what it commits to, the canonical CID conversion, the verification
discipline, and why `nft_id` being the join key across chain / metadata / claim
registries is a structural fact.


### THE BLUEPRINT IS A PUBLISHED STANDARD, NOT A LOOPRING INVENTION (2026-08-09)

**Read this before the sample-derived section below.** The metadata format was
never Loopring's own. The SDK's `IPFS_METADATA` type
(`loopring_sdk/src/defs/loopring_defs.ts:2729`) parses:

```
base:  name, decimals, description, image, properties, localization
extra: imageData, externalUrl, attributes, backgroundColor,
       animationUrl, youtubeUrl, minter
```

The first group is the **ERC-1155 Metadata URI JSON Schema**, field for field.
The second is **OpenSea's metadata extensions**, which in the actual pinned JSON
are snake_case: `image_data`, `external_url`, `background_color`,
`animation_url`, `youtube_url`, `attributes`. `royalty_percentage` is an
extension following the same convention.

**What this changes:** the four fields seen across four samples were not the
format. They were the subset that happened to be populated. Everything else in
the standard was presumably omitted rather than written empty, which is why only
four ever appeared. Build against the schema, not against the samples.

Confirms the earlier inference that `attributes` sorts alphabetically FIRST,
ahead of `description` - now from the schema rather than from a guess.

**Still open:** whether the minting client omitted empty fields or emitted them
as empty strings, and the whitespace variants.

### Claims in this file that were wrong

Five statements here were false and were corrected on 2026-08-09, including one that sent
a whole afternoon down a dead end. The dated record is in
[[feedback-loopring-corrections]]. The load-bearing ones, as directives:

- **No code in the repo builds a candidate JSON.** It never did.
- **There is no canonical Loopring hasher.** `nftID` is a `uint256` the client computes and
  supplies as an INPUT to the mint. Nothing in the protocol derives or validates it. The
  authority is the IPFS UnixFS/dag-pb spec plus whatever the pinning client used.
- **`upstream/protocol3-circuits` has no NFT support.** Zero matches for "nft". It cannot
  answer NFT questions.
- **CIDv0 single-chunk only is verified.** Anything over 262144 bytes needs multi-chunk DAG
  construction, which is NOT verified, and every real image exceeds it.

### THE METADATA JSON FORMAT - cracked and byte-verified (2026-08-03)

The highest-value finding of the whole effort. Reconstruction was blocked on not knowing
the exact serialisation; a single retrieved sample solved it, and three independent
samples confirmed the structure and mapped the variation.

**Invariant structure - identical across every sample:**
```
{\r\n
"<key>": <json value>          keys ALWAYS sorted alphabetically
,<SEP>                         between fields
"<key>": <json value>
\r\n}<TRAILING>
```
- CRLF line endings throughout, never LF
- `": "` between key and value (colon, single space)
- No indentation at all - fields start at column 0
- Standard JSON value encoding (`JSON.stringify` semantics)

**The only variable parts** (different minting tools emitted different whitespace):

| Sample | SEP | TRAILING | size |
|---|---|---|---|
| Celestial Love | `\r\n` | `\r\n\r\n\r\n` | 164 B |
| Cheese Loop | `\r\n` | *(none)* | 158 B |
| Community Card 3: Nancy | `\r\n\r\n` | *(none)* | 248 B |

So a reconstruction is **8 deterministic candidates** (2 separators x 4 trailing options),
not an open search. An earlier 55,296-candidate brute force failed purely because it
assumed LF endings and never tried three trailing CRLFs.

**Fields observed** (all four samples): `description`, `image`, `name`,
`royalty_percentage`. No `attributes` / `animation_url` / `collection_metadata` seen yet -
Nancy carries trait-like text inside `description` rather than a structured array, and its
artwork traits are burned into the image. If a sample with real `attributes` turns up,
note that alphabetical sorting places it FIRST, ahead of `description`.

`royalty_percentage` was **10 in all four samples across four different creators** - treat
it as a platform default, not a per-creator value.

`image` takes either form:
- bare CID: `ipfs://QmZKfpqUFq...`
- folder path: `ipfs://QmeGV4miFg.../Nancy.gif`

**Proof the whole thesis works:** "Celestial Love" is an L2-only collection, never deployed
to L1, so no `uri()` exists anywhere - and `CIDv0(nftID)` resolved to live content on
ipfs.io. That is the first confirmed case that the SDK conversion does not merely match
Loopring's code but lands on real retrievable data. Cheese Loop and Nancy likewise.

**How to present the bytes:**
1. Hash the original media with true UnixFS/dag-pb (`ipfs-only-hash`, cidVersion 0) - NOT
   raw sha256. `scripts/cidcheck.js` in loopring-explorer does this.
2. Build the JSON above with `{description, image: "ipfs://<mediaCID>", name,
   royalty_percentage: 10}`, keys sorted.
3. Try the 8 whitespace combinations; hash each; convert to nftID form
   (`base58 decode, drop the leading 0x12 0x20`).
4. Compare against the on-chain nftID. A match means the bytes are correct.

If none of the 8 match, the answer is that one of the inputs is not what was used - the
image bytes, the name, or the description. It is NOT a signal to widen the search, invent
a variant, or write a new hasher. **Say which input is uncertain and stop.**

**Known failure mode:** attempted on "Coffee House Pack"
(nftID `0xbe5597f487838930b1bc003db7d1a1b8385c9f119795e9de464fa589c511948c`) and it did
NOT match against any file in the creator's source folder. Name, description, structure and
whitespace candidates were all known - the miss is the *image bytes*. The uploaded export
(likely resized or re-encoded at upload time) is not on disk. This is a missing-file
problem, not a broken method.

### LIVE SAMPLE, byte-exact (retrieved and re-hashed 2026-08-10)

Retrieved from `CIDv0(nftID)` and confirmed by re-hashing the retrieved bytes back to
the same CID. This is a real Loopring metadata JSON, not a reconstruction.

```
CID     QmcUJs3qypHMY1tsSBW6JR6JSsQghkXMKk9ectom25Fv6V
size    157 bytes
```

Exact bytes, with line endings shown:

```
{\r\n
"description": "by AA5K",\r\n
"image": "ipfs://QmXohsVcDhMZSESG2KqGAcbbSWDQjHsYFnD8v6iPQi6wwu/The Ape.jpg",\r\n
"name": "The Ape",\r\n
"royalty_percentage":10\r\n
}\r\n
```

Hex of the first 48 bytes, so the framing is unambiguous:

```
7b 0d 0a 22 64 65 73 63 72 69 70 74 69 6f 6e 22   {.."description"
3a 20 22 62 79 20 41 41 35 4b 22 2c 0d 0a 22 69   : "by AA5K",.."i
6d 61 67 65 22 3a 20 22 69 70 66 73 3a 2f 2f 51   mage": "ipfs://Q
```

**Details that no reconstruction would guess:**

- Opening `{` is followed immediately by CRLF - there is no space or newline convention
  beyond that.
- Keys are alphabetical: `description`, `image`, `name`, `royalty_percentage`.
- The first three keys use `": "` - colon SPACE. `royalty_percentage` uses `":` with
  **NO space**. That inconsistency is in the real file and is enough on its own to make
  every candidate miss.
- `royalty_percentage` is a bare number, not a string, not quoted.
- Every line ends CRLF, including the last one after the closing brace.
- No trailing newline beyond that single CRLF.
- `image` here is a **folder path**: `ipfs://<dirCID>/The Ape.jpg`. The directory block
  was fetched and parsed - one entry, `The Ape.jpg` -> `QmeVizmeTzywpVq9emDRGjmjB7kK4HubBTqcyhbKo9TFte`,
  tsize 491063. Mints made by single-file upload instead carry a bare CID with no path,
  so this field's shape varies by how the creator uploaded.

**Provenance of this sample:** 12 random digest-shaped nftIDs were taken from
NFT_DATA-derived rows in the archive and converted to CIDv0. 8 of 12 resolved on
dweb.link; the other 4 returned 301 (gateway noise, not absence). All 8 are saved and
all 8 re-hash to their own CIDs. This also refutes "nobody's metadata resolves" - a 67%
survival rate across 8 independent creators, measured 2026-08-10.


### Counterfactual collection addresses are derivable (closes an old open question)

`computeNFTAddress` (`src/api/nft_api.ts:440`):
```
salt    = keccak256("NFT_CONTRACT_CREATION" || nftOwner || nftBaseUri)
address = CREATE2(nftFactory, salt, keccak256(CREATION_CODE))
default nftFactory = 0xDB42E6F6cB2A2eFcF4c638cb7A61AdE5beD82609
```
**The baseURI is baked into the CREATE2 salt** - which is what
`project_moody_brains.md` speculated and could not confirm. Consequences: for an
undeployed collection you cannot call `uri()` on, a candidate baseURI is *testable* by
recomputing the address and checking it matches. With the default empty `nftBaseUri` the
salt collapses to a function of owner alone.

### CREATE2 is a valid formula and the wrong tool (2026-08-09)

The paragraph above ended with "so a counterfactual collection can be **proven** to
belong to a given wallet". That claim is too strong and the tool uses CREATE2 for
nothing. Three findings, in order of how much they cost to learn:

1. **The formula and mechanics are confirmed.** Deriving forward for all 5,546 owners in
   the archive and intersecting against 2,985 addresses observed in TRANSFER calldata
   produced exactly one hit, under `NFTFactory[MAINNET]` with empty baseURI:
   `0x44d5150d22d4270f024f03b4c00eaeaff0490c12` from account 303010. At 160 bits across
   16.5M pairs that is not coincidence.

2. **It answers the wrong question.** It yields an owner's DEFAULT collection, not the
   collection a given mint went into. NFT_MINT is 68 bytes and binds no collection at
   all. Tested against every nftID whose true collection AND minter owner are both known:
   **0 matches out of 12.**

3. **The SDK's CREATION_CODE does not describe every mainnet collection.** The owner's
   own two collections are EIP-1167 proxies whose L1 runtime bytecode delegates to
   implementation `0xaf4c6c97c620425b9d05c6a12f886d14a04eff06`. `loopring_sdk`'s mainnet
   `CREATION_CODE` embeds `0xb25f6d711aebf954fb0265a3b29f7b9beba7e55d`. Different
   implementation, different codeHash, different address - so none of 3 factories x 4
   baseURI candidates reproduced them. **Which factory deployed them is not established.**

Owner observation, not ground truth, recorded because it points the same way: LoopExchange
required users to manually add a collection by address before it could find their NFTs,
while Loopring's own API was still live. Source is the owner, first-hand, as a user of
that marketplace. Nothing above depends on it.

### uri() confirms CIDv0(nftID) from the deployed side (2026-08-09)

`uri(nftID)` on deployed collection `0x8eb42287...` returned exactly `ipfs://CIDv0(nftID)`
for three different nftIDs. The conversion was already canonical from SDK source; this
confirms it from a deployed contract, an independent direction, and since ERC-1155
`uri()` is by definition the *metadata* URI it also confirms **nftID addresses the
metadata, not the image**.

Trap that cost time this session: calling `uri()` with the SAME nftID against two
different collections returns the same string. That looks like a fixed per-collection
template and is not - it is per-token and both were being asked about the same token.

### Metadata resolution confirmed

`getContractNFTMeta` (`:238`) calls `uri()` for ERC1155 / `tokenURI()` for ERC721,
substitutes `{id}`, then fetches JSON. Exactly the branch `pages/api/nft-metadata.ts`
already implements.

## THE VERIFIER IS THE nftID. NOT IPFS. -> moved

**MOVED 2026-08-10 to [[project-loopring-nftid]].** That file now holds what
`nftID` is, what it commits to, the canonical CID conversion, the verification
discipline, and why `nft_id` being the join key across chain / metadata / claim
registries is a structural fact.


## The metadata resolution model

There is no universal rule. Resolution is determined by each collection contract.

| Case | Resolution | Confidence |
|---|---|---|
| Deployed, reference `L2MintableERC1155` | `uri()` ignores tokenId, returns a template; client substitutes `{id}` | Verified in source |
| Deployed, custom `uri()` override (Moody Brains, `0x1cACC96e...`) | Returns a resolved per-token path, may encode mutable state (`.../2_2/metadata.json`) | Empirically confirmed on-chain |
| Counterfactual collection | No contract to call. Reconstruct via the canonical SDK conversion, or derive/test the baseURI from the CREATE2 salt | Conversion canonical; whether a given nftID came from that path is per-NFT |
| `CounterfactualNFT` (GameStop path) | Unknown - contract in neither local repo | Unverified |

A dynamic NFT cannot live at an immutable content hash, which is exactly why `uri()`
indirection exists. Both collections sampled on 2026-08-02 turned out to be
**counterfactual** (`eth_getCode` returned `0x`), so reconstruction was the only
available path for them - a useful reminder that the deployed case may be the minority.

### Metadata hash vs media hash

`pages/api/cid.ts` states it in code: the true IPFS CIDv0 is the UnixFS/dag-pb hash
`ipfs add` produces, computed via `ipfs-only-hash`. **Raw `sha256(file)` is not a CID and
will never match.** A verifier built on raw sha256 fails against genuine originals - a
bug that shipped once, see [[feedback-verify-before-asserting]].

## ARCHITECTURE: read the chain, do not read a table (2026-08-09, owner directive)

**"stop using the archive in the code / source of truth. BUILD OFF THE CALLDATA."**

The NFT decoder page reads three derived SQLite tables - `account_owner`, `nft_mints`,
`nft_collections` - and never parses a byte of calldata. `pages/decode.tsx` does the
opposite and is the pattern to follow: give it a transaction hash, it fetches and parses
live, stores nothing.

The archive itself is honest about blocks - each is checked against its own commitment at
ingest - but the derived tables have no verification at all. They are Claude's parser
output and can be stale, partial or wrong with no signal. That is the same structural
problem as The Graph, one step removed: the index is now ours, which changes who is
trusted and nothing else.

**Ground truth is Ethereum consensus. Everything else is a copy of a copy:**
```
Ethereum consensus     ground truth
  RPC endpoint         someone's claim about it
    blocks table       our copy of that claim
      derived tables   our parse of our copy
        the page       what the user sees
```
A copy is legitimate when it is **reproducible**, not when it is trusted. The data
availability guarantee means anyone can rebuild it and compare, and the claim to make is
never "I have the data" but "here is how you get the same data, and if yours differs one
of us is wrong and we can find out which."

**The database is not required for this.** See [[project-loopring-protocol]] - only
address-to-mints needs a scan; everything else reads the chain directly.

## CODE IS BEHIND MEMORY - open work as of 2026-08-09

Normally memory lags the code. Here it is the reverse: the contract sweep found things the
code does not yet reflect. **Do not treat the files below as correct.**

1. **`scripts/derive-from-calldata.js` writes byte 1 of NFT_MINT into the `nft_type`
   column. Byte 1 is `mintType`.** 518 of 2,494 rows in `nft_mints` therefore claim
   nftType 2, which is not a valid standard. Fix: rename the column to `mint_type`, and
   source the real `nftType` from NFT_DATA byte 41.

2. **`scripts/derive-collections.js` resolves collections from ERC-1155 TransferSingle L1
   logs only - 679 nftIDs.** NFT_DATA transactions in calldata carry the same binding for
   **18,244** nftIDs, plus minter, creatorFeeBips and the real nftType. The script's header
   comment argues at length that logs are the only route. That argument is now wrong. The
   log route stays valid as corroboration.

3. **`pages/api/calldata-nft.ts`** `unavailableNotes()` tells callers the collection is
   "known only for NFTs that moved to L1". Untrue once NFT_DATA is parsed.

4. **`pages/decode/nft.tsx`** carries the same claim in its `mintRowToRaw` comment.

5. **`utils/config.ts`** and the CREATE2 discussion throughout are unaffected - CREATE2 is
   still the wrong tool. The difference is that the question it was being asked no longer
   needs it.

None of this was changed in code, because the instruction was to sweep and record, not to
rebuild.

## Tool state - MIRRORS THE CODE as of 2026-08-09

This section is a transcription of the files, not a description of intent. If it
stops matching them it is wrong and the files win. Anything below without a
file:line was not read.

**The verify chain, end to end:**

1. `nft.tsx:328` `resolveMeta` -> `/api/nft-metadata?nftID=...` (`token` optional)
2. `nft-metadata.ts:95-107` if `token` given and `eth_getCode` non-empty, call
   `uri(nftID)` then `tokenURI(nftID)` and fetch that
3. `nft-metadata.ts:110-112` otherwise, and as fallback,
   `recUri = 'ipfs://' + nftIDtoCIDv0(nftID)` and fetch that
4. `nft-metadata.ts:83` `imageRaw = metadata.image`
5. `nft.tsx:146-150` `mediaCidFromMeta` strips `ipfs://`, returns null if the value
   contains `/` (a folder path cannot be matched against one file)
6. `nft.tsx:357` `cidOfFile` -> `/api/cid`
7. `cid.ts:19` `Hash.of(body, { cidVersion: 0 })` - `ipfs-only-hash`, UnixFS/dag-pb
8. `nft.tsx:360` compare file CID to the media CID

**So `CIDv0(nftID)` is the ADDRESS the metadata JSON is fetched from, and the
dropped image is compared to the `image` CID found inside that JSON.** The image
is never hashed against `CIDv0(nftID)`. That ordering is now proven from the
chain, not inferred: `uri(nftID)` on his deployed collection returned exactly
`ipfs://CIDv0(nftID)` for three different nftIDs, and ERC-1155 `uri()` is by
definition the metadata URI.

**NOT verified:** `/api/cid` has never been checked against a file whose CIDv0 is
independently known, because no known-good sample is saved anywhere. Its chunking
parameters versus the original pinning client's are unknown. Same blocker class as
the JSON builder - see [[project-loopring-own-mints]].

**What the page does NOT have.** Earlier versions of this file described these as
present. They are not in the code:
- no `/api/probe`, no Pinata `pinByHash` probe. The route does not exist in
  `pages/api/` and its caller was deleted 2026-08-09
- no `/api/pin`, no re-pin flow, no `pinStatus`
- no subgraph anything. The NFT decoder is on the calldata-only side of the
  exclusion recorded in [[project-loopring-revival]]; the core team's pages are
  not, and that boundary does not move

`NFTRecord` is exactly: `raw`, `cid`, `cidStatus`, `verifyStatus`, `meta`,
`verifiedCid?`. The engine returns exactly `state, lookup, checkAvailability,
resolveMeta, verifyFile, resetVerify` (`nft.tsx:371`).

`raw` keys, from `mintRowToRaw`: `nftID, nftType, creatorFeeBips, amount,
minterAccountID, toAccountID, toAccountOwner, token, collectionSource, nftSlot,
storageID, l2Block, slotInBlock, mintedAt, merkleRootAfter`.

Page moved from `pages/recover/index.tsx` to `pages/decode/nft.tsx` on 2026-08-02.

## Architecture - as the code stands 2026-08-09

**Data-driven router, not a fixed schema.** The first version hardcoded four hand-picked
fields, imposing a shape on the data. Corrected principle: the source defines the
dimensions - store the returned object verbatim as `raw`, render whatever keys came back.
The source is now `/api/calldata-nft`, which reads the archive, not a subgraph.

`useRecoveryEngine()` holds state keyed by `raw.nftID`; `patchRecord(nftID, patch)` is
the single update helper. State fills progressively - account, then mints, then metadata
and availability lazily on viewport entry (`IntersectionObserver`, `nft.tsx:739`).

Card React keys are `${raw.l2Block}-${raw.slotInBlock}` (`nft.tsx:829`). They used to be
`raw.id`, a subgraph entity id, which after the Graph removal was `undefined` on every
card.

**Removed 2026-08-09 from the NFT decoder, do not describe as present:** pagination constants,
the Holder tab's data source, the network probe, the re-pin flow, and the wallet-type
control-proof seam (`ecrecover` / EIP-1271). The seam was only ever needed to authorise a
re-pin; with no re-pin there is nothing to bind. Content proof is wallet-agnostic and is
the load-bearing proof, which is unchanged.

The Holder tab still exists in the UI but is always empty: current holdings need a replay
of every NFT transfer to rebuild balances, which is tractable from the same corpus and is
not built (`nft.tsx:268`, `calldata-nft.ts` `unavailableNotes`).

### Archive facts (replaces the old "Subgraph facts" section, deleted 2026-08-09)

Tables in `loopring-archive.db`: `l1_txs`, `l1_logs`, `blocks`, `discovered`,
`discovered_blocks`, `log_cursor`, `meta`, `nft_mints`, `account_owner`,
`account_owner_conflicts`, `nft_collections`, `nft_collection_conflicts`.

- `account_owner` maps accountID -> L1 owner, with the tx type that proved it. Built by
  `scripts/derive-from-calldata.js` from ACCOUNT_UPDATE, DEPOSIT, AMM_UPDATE and
  SIGNATURE_VERIFICATION, all of which carry both values inline. 5,546 rows.
- `nft_mints` is one row per NFT_MINT, keyed `(block_idx, slot)`. 2,494 rows, 2,037
  distinct nftIDs, 107 distinct minters.
- `nft_collections` maps nftID -> collection, built by `scripts/derive-collections.js`
  from L1 logs. 679 nftIDs resolved, 11 distinct collections, 0 conflicts.
- **nftID is NOT unique.** 14 nftIDs in the archive were minted by more than one account,
  one of them by 19 different accounts. All 14 share a shape: a 20-byte value
  left-aligned in the 32-byte field with 12 trailing zero bytes. One of them,
  `0x5863f024...00`, is the address `0x7e5863f0246602c12765e11a935c6697b090201c` with its
  leading byte dropped. So some nftIDs encode an address rather than a metadata CID, which
  agrees with the already-recorded `0x00...0042` sequence-number case: **test the shape of
  the nftID before assuming the CIDv0 path.**
- Token decimals: the old note said the subgraph was the authoritative registry with 295
  tokens. That registry is gone and nothing replaces it. Amounts render as raw base units.

## Bugs fixed (these recur)

- **Reading state back out of a `setState` updater for control flow** - updaters run
  during render, so the guard is still false at the call site and the fetch is skipped.
- **`dynamic(() => Promise.resolve(Component))`** creates a new Promise each render,
  remounting and resetting hook state.
- **Next.js 12 server bundle never built** for the heavy-dependency page; fixed by
  skipping SSR.

## What the fingerprint actually gives you -> moved

**MOVED 2026-08-10 to [[project-loopring-nftid]].** That file now holds what
`nftID` is, what it commits to, the canonical CID conversion, the verification
discipline, and why `nft_id` being the join key across chain / metadata / claim
registries is a structural fact.


## IPFS died, not Loopring

Three healthy layers, one degraded, and the broken one is not Loopring's:
- **Ownership record** - Ethereum L1 calldata. Permanent.
- **Metadata pointer** - on-chain `uri()` for deployed collections. Permanent.
- **Content** - IPFS. This rotted industry-wide: cloudflare-ipfs shut down, ipfs.io and
  dweb.link rate-limit to 504s, nft.storage pivoted.

## Positioning -> moved

**MOVED 2026-08-10 to [[project-loopring-nftid]].** That file now holds what
`nftID` is, what it commits to, the canonical CID conversion, the verification
discipline, and why `nft_id` being the join key across chain / metadata / claim
registries is a structural fact.


## L1 deployment is the protocol's own safe exit, not a risky fork

Deploying a counterfactual collection to L1 without the (dead) operator does not fork
ownership. Loopring built a permissionless exodus path for exactly this:

1. `forceWithdraw` - anyone can request a forced withdrawal, with explicit NFT handling.
2. If ignored past `MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE`, anyone can call
   `notifyForcedRequestTooOld`, freezing the exchange into withdrawal mode. The operator
   cannot block this.
3. `withdrawFromMerkleTree` - withdraw against the last finalized state root via Merkle
   proof, with standard double-claim protection.

Withdrawals run against a frozen canonical final state; there is no scenario where L2
stays live while a separate L1 claim exists. Source: `ExchangeWithdrawals.sol`,
`ExchangeMode.sol`.

**Partly settled 2026-08-09.** Creator royalties are definitively NOT protocol-enforced:
`creatorFeeBips` appears only in a struct, a type hash and a Poseidon hash, and no
contract or circuit does arithmetic with it. Enforcement was marketplace-side. LRC
*trading* fees remain unverifiable because SPOT_TRADE has no Solidity at all. So the
"Loopring reactivates once fee revenue resumes" argument cannot lean on royalties.

The exodus path itself IS verified - all four functions exist in the contracts.

## Re-pin - NOT IMPLEMENTED, removed from the code 2026-08-09

Design intent, unchanged: verification is the gate, re-pinning is what restores. Still
open if it is ever built: whether re-pin binds to the minter (and therefore needs a
control-proof seam), pinning service (creator's own vs tool-operated, currently no
custody), payment chain undecided.

**Do not describe this as shipped.** `/api/pin` does not exist. The UI that called it
was deleted along with the network probe, which called a `/api/probe` that also never
existed. Both had been sitting in the page firing at 404s.

## Open questions

- **RESOLVED 2026-08-03 by the SDK** - the addressing question, the baseURI/CREATE2
  question, and the metadata-resolution question. See the SDK section above. The
  `CounterfactualNFT` *contract* source is still unread (not in `protocols`, and
  `protocol3-circuits` is the ZK prover with no Solidity at all), but it no longer
  blocks anything: `computeNFTAddress` gives the address derivation and
  `getContractNFTMeta` gives the resolution path.
- **RESOLVED 2026-08-03: yes.** Three L2-only NFTs (Celestial Love, Cheese Loop,
  Community Card 3: Nancy) all resolved via `CIDv0(nftID)` on ipfs.io, and all three
  metadata JSONs were reproduced byte-identically from scratch. The addressing model
  and the serialisation format are both confirmed against live data. Note earlier
  probes returning `{"Providers":[]}` were true negatives for those specific NFTs
  (unpinned), not evidence against the model.
- **SPOT_TRADE layout** remains unverifiable against Solidity - see
  [[project-loopring-protocol]].

## Community actors

| Handle | Wallet | Notes |
|---|---|---|
| Autodestructive | `0xC7Eaf32B4141FC4a0984A501D41Da6F06Be13bB6` | Ran a secondary NFT marketplace outside GSMP; built LoopringRescueRegistry, a Merkle-gated ERC-1155 rescue contract anchored to Loopring's official snapshot. Exit-liquidity focused. |

Reception of the decoder's public announcement is in
[[project-decoder-community-reception]].
