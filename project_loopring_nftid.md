---
name: project-loopring-nftid
description: "What nftID is, what it commits to, and why it being the join key across chain / metadata / claim registries is a structural fact - plus the verification discipline that keeps reasserting itself"
metadata: 
  node_type: memory
  type: project
  originSessionId: cbbd03b1-8886-4e2d-9be8-08400e9c318d
  modified: 2026-08-10T19:24:56.974Z
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.
CLAUDE NEVER DOWNLOADS MEDIA - ABSOLUTE: Claude is NEVER permitted to download any media. Not imagery, not video, not JSON. Not from IPFS, not from a gateway, not from any URL, not from any content-addressed source. Claude is never permitted to access or analyze any of it directly. No exceptions. Not to test something, not to verify something, not once.

---

## nft_id is the join key - structural, not a convenience

`nft_id` is the only identifier present in all three layers:

```
L1 calldata mint record     nft_id    what the chain says
CIDv0(nft_id)               nft_id    what the metadata is
snapshot / registry entry   nft_id    what a claim says
```

`CIDv0 = base58(0x12 0x20 || nft_id)`, so the identifier IS the content address.
Nothing sits between the chain record and the IPFS object. The identifier is the
index - there is no lookup table to trust, build, or lose.

### Why that matters beyond convenience

**A snapshot is an assertion; the chain is a record.** Loopring's official snapshot
is a fixed list of who held what. Its authority rested on two facts: the operator
produced it, and nobody had an independent way to check it.

A Merkle-gated claim contract commits to a root over such a list. Anyone can prove
they are IN the tree. **Nobody can prove the tree is CORRECT, and nobody can prove
who was LEFT OUT** - a Merkle proof only proves inclusion. Omission is invisible by
construction.

**Calldata reconstruction is the only thing that makes omission visible.** Every
mint, transfer and withdrawal is in L1 calldata, self-verifying against
`publicDataHash`, so L2 ownership at any block is independently derivable. That
yields the complete set, which a Merkle root cannot supply. The tree becomes
checkable in both directions: is every entry supported by the chain, and is every
chain-supported holder present in the tree.

Without a calldata-derived `nft_id` there is no cross-reference at all - you would
have to accept whatever identifier a registry used, on its own authority. With it,
every registry row has a chain-side counterpart anyone can produce. **That join IS
the audit.**

### The consequence

Evidentiary authority moves from a party to a public process.

- **Before:** the snapshot is the record, disputes resolve by consulting it, and
  whoever holds it holds the authority - including the authority to have excluded
  someone, unappealably, because no higher court existed.
- **After:** the chain is the record, the snapshot is a claim *about* the chain, and
  disputes resolve by reconstruction anyone can perform and check. Someone excluded
  can produce evidence rather than an objection.

This happens whether or not anyone intended it, whether or not any given snapshot is
accurate, and it cannot be reversed, because the calldata is permanent.

**Honest limit: none of this shows any snapshot is wrong. It shows one is testable,
and that the test requires nobody's cooperation.** That is the entire claim.

### Discipline note - structural claim, not an intent claim

This is the STRUCTURAL version: checkable from public facts, no mental state
required, no exit. **Do not convert it into a claim about anyone's intent.** An
intent claim is escaped by any *available* competing explanation, and the burden
then flips onto proving a mind, which cannot be done. See
[[feedback-precision-over-helpfulness]] for the burden asymmetry, and the standing
rule in [[project-decoder-community-reception]] against attributing an objection to
a named person without a direct quote tied to them.

### Opposite requirements, no bad faith required

A snapshot/claim registry and a provenance-restoration tool have opposite
requirements on the same property. Exit liquidity needs a settled, final,
authoritative list - ambiguity is a liability while people are claiming and selling.
Provenance restoration needs an open, reconstructible one - a settled list you
cannot audit is the failure case. Both can be built in good faith and still pull in
opposite directions on whether the record stays checkable.

---

## The nftID <-> CID conversion is CANONICAL, not a convention

*(moved here from [[project-loopring-recovery]] 2026-08-10)*

`src/api/nft_api.ts:337`:
```js
public ipfsNftIDToCid(nftId: string) {
  const hashBN = new BN(nftId.replace('0x', ''), 16)
  const hex = hashBN.toString(16, 64)
  const buf = Buffer.from('1220' + hex, 'hex')   // 0x12 0x20 multihash prefix
  return new CID(buf).toString()
}
```
Inverse at `:325` (`ipfsCid0ToNftID`). This is exactly
`base58(0x12 0x20 || nftID)` - the thing earlier memory hedged as an "unverified
convention." It is Loopring's own shipped implementation with a committed test vector:

```
nftID 0x0880847b7587968f32ba6c741f9d797d9dc64971979922a80c4e590453b8dc2f
CID   QmNuqdeWUJ9iEiw5qZfJ2pJ9onqAS45ZffvV8JQSUzp7DQ
```
The explorer's implementation reproduces this exactly (checked 2026-08-03).

**Canonical means: this is the code Loopring shipped, with their own test asserting the
output.** It does NOT mean every nftID was created this way - the `0x00...0042`
collection proves some were not. Canonical conversion, not universal application.

## nftID addresses the METADATA JSON, not the image

*(moved here from [[project-loopring-recovery]] 2026-08-10)*

`IPFS_METADATA` (`src/defs/loopring_defs.ts:2729`) is the SDK's **internal parsed type**,
NOT the shape of the pinned file - a distinction that cost time:
```
{ uri, base: { name, decimals, description, image, properties, localization },
  imageSize: {...}, extra: {...}, nftId?, nftType, network, tokenAddress, tokenId }
```
The actual pinned JSON is **flat and much smaller** - four fields, confirmed against three
retrieved samples. The nested `base`/`imageSize`/`extra` structure is assembled
client-side by combining the pinned file with API data. Do not reconstruct against this
type; reconstruct against the verified format in [[project-loopring-recovery]].

Either way the chain is the same - the pinned JSON's `image` field holds
`ipfs://<mediaCID>` pointing at the media. So:

```
nftID = ipfsCid0ToNftID( CID(metadata JSON) )  ->  metadata.base.image  ->  media file
```

**Practical consequence:** hashing your image file and comparing it to `nftID` can never
match - they are different files. This is why creator-side verification attempts failed;
the method was fine, the target was wrong.

**What this means in practice:** nothing needs to be retrieved. Hash the image to get
`mediaCID`, put it in the JSON with the name and description that were used, hash that,
compare to `nftID`. A match says the bytes are right. Nothing is being recovered - the
creator supplies what they already have and the chain confirms it.

JSON hashing is byte-exact, so this once looked like an open-ended search. **It is not
open-ended any more** - the exact format is known and verified, and the residual
ambiguity is 8 candidates. See the format section in [[project-loopring-recovery]].

---

## THE VERIFIER IS THE nftID. NOT IPFS. (2026-08-09)

*(moved here from [[project-loopring-recovery]] 2026-08-10)*

**Correcting an overstatement written earlier the same day**, which was titled "Hashing is
PROVEN CORRECT - stop suspecting it". That claimed more than the evidence supports.

**THE OWNER CAUGHT THIS AND DIRECTED THE CORRECTION. Claude did not notice it.** His
words: *"we should stop trying to confirm a hash as to whether content appears > we need
to match the hash itself; and you keep defaulting to IPFS as the verifier."*

That is the whole correction, and it identified the flaw in the reasoning flow rather than
in any single claim. Claude had run gateway fetches, a DHT provider walk and a
gateway-racing API route, then written the results up as though they bore on verification.
They do not. He named the category error, named it as a recurring default rather than a
one-off, and only then did the overstated section get rewritten.

Recorded this way deliberately: the record should show which corrections were caught by
Claude and which were caught by him. This one was his, as were the NFT_DATA sweep that
overturned three claims and the ZERO AGENCY rule.

### The rule, because this default keeps reasserting itself

**The question is never "does the content appear". It is "does our hash equal the
fingerprint the chain already committed to".**

`nftID` IS the answer key. It is on-chain, permanent, and needs nothing and nobody.
Verification is: build a candidate document, hash it, compare to `CIDv0(nftID)`. Offline,
no network, no gateway, no DHT, no pinning service.

Repeatedly on 2026-08-09 the fallback was to reach for IPFS instead - gateway fetches, a
DHT provider walk, `pages/api/ipfs-check.ts` racing gateways. **Every one of those tests
availability, which is orthogonal to correctness.** Whether anybody still pins the bytes
has no bearing on whether our arithmetic reproduces their fingerprint. Treating a
retrieval result as evidence about the hash is a category error, and it was made more than
once.

### What is actually proven, and what is not

| Claim | Status |
|---|---|
| Our CIDv0 matches the IPFS reference implementation | **PROVEN.** kubo 0.43.0, file 5/5 incl. multi-chunk, JSON 4/4 incl. CRLF and trailing whitespace |
| `base58(0x12 0x20 \|\| nftID)` matches Loopring | **PROVEN.** The deployed collection's `uri()` returned exactly that for 3 nftIDs |
| **Our pipeline matches LOOPRING'S CLIENT** | **DISPUTED - see the unresolved conflict below** |

### RESOLVED BY EXPERIMENT 2026-08-10 - was flagged as a conflict, then settled

**Settled by running it, not by choosing a side.** 12 random digest-shaped nftIDs from
NFT_DATA-derived rows were converted to `CIDv0` and fetched; 8 resolved. All 8 retrieved
JSONs were re-hashed and **8/8 reproduced their own CIDs**, alongside the two standard
IPFS reference vectors (empty file, `hello world\n`). Bytes to digest, demonstrated on
real Loopring metadata across 8 independent creators.

**So the 2026-08-03 entry stands and the 2026-08-09 "never been done" line is
superseded.** `project_loopring_own_mints.md:206` - "the builder has never been validated
against a single known-good sample ... that is the blocker" - **is now wrong** and should
be corrected: the pipeline is validated, so a miss means the CONTENT is wrong, not the
format, the wrapping or the tooling.

**The bug that made the first attempt read 0/8:** in dag-pb, `PBNode.Data` is **field 1**
(tag `0x0a`), not field 2. The merkledag proto declares `repeated PBLink Links = 2;
optional bytes Data = 1;` - reversed from the obvious assumption. Using tag `0x12`
produces a well-formed but wrong CID for every input. Isolated against the known empty-file
CID `QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH`.

Verified minimal implementation, no dependencies:

```
UnixFS Data  = 0x08 0x02 | 0x12 <varint len> <bytes> | 0x18 <varint len>
PBNode       = 0x0a <varint len> <UnixFS Data>            <- Data is FIELD 1
CIDv0        = base58( 0x12 0x20 || sha256(PBNode) )
```

Single-block only - correct for metadata JSONs, NOT for media over the chunk size.

### WHAT IS STILL NOT DETERMINED: media chunking parameters

**The SDK contains no media-hashing code at all.** `loopring_sdk/src/api/nft_api.ts` has
exactly `ipfsCid0ToNftID` (`:325`), `ipfsNftIDToCid` (`:337`) and a gateway URL rewriter
(`:252`). It never adds a file to IPFS. The circuits treat nftID as opaque. So **nothing in
Loopring's own source specifies chunk size, `rawLeaves`, or CID version for media** - those
belong to whatever client uploaded the file, and any value chosen for them is an assertion
until measured against a real Loopring-pinned file.

Empirical anchor for that measurement, captured 2026-08-10 from the AA5K sample:

```
directory  QmXohsVcDhMZSESG2KqGAcbbSWDQjHsYFnD8v6iPQi6wwu
entry      'The Ape.jpg' -> QmeVizmeTzywpVq9emDRGjmjB7kK4HubBTqcyhbKo9TFte  tsize 491063
```

### MEASURED 2026-08-10: rawLeaves is FALSE, CIDv0, kubo defaults

**DONE, and it is no longer an assertion.** The file above was fetched from IPFS
(490,931 bytes, multi-chunk) and its CID recomputed from the retrieved bytes under
candidate parameter sets:

```
cidVersion 0, rawLeaves false (kubo default)  QmeVizmeTzywpVq9emDRGjmjB7kK4HubBTqcyhbKo9TFte  MATCH
cidVersion 0, rawLeaves true                  QmcQwmYK69H9kRCjvXxmoZ5SRsS79rkhtV7zpNpbpZmQAt  no
cidVersion 1, rawLeaves true                  bafybeigrdu5koiftup4rx4rxjecjzoco6wxbyklmkpr6wp4p23bu4fb2xe  no
```

**So the pinning client used CIDv0 with dag-pb leaves - `rawLeaves: false`.** This was
previously listed as an open unknown and as a candidate explanation for reconstruction
misses; it is neither any more. Measured against a real Loopring-pinned mint, not
assumed, and not taken from documentation.

**Caveat on chunk size, stated so it is not overclaimed:** `ipfs-only-hash` silently
IGNORES the `chunker` option - 64KiB, 256KiB and 1MiB all returned the identical CID for
a 490,931-byte file, which is impossible if the option were honoured. So what is
established is *the library default* (256 KiB), which is what matched. Chunk size has NOT
been independently discriminated. To do that properly, vary it with a tool that honours
the setting (kubo itself) against the same file.

**Correct invocation, now evidence-backed:**

```js
await Hash.of(buf, { cidVersion: 0, rawLeaves: false })   // do NOT pass chunker, it is ignored
```

Media CIDs computed this way 2026-08-10 for the Coffee Pack source folder:

```
1619664B  QmctBjhj1er6pphBUZxotY1F8CKQARDXtY2kk2DqbMA8oQ  Coffee Pack.png
 161752B  QmYMqDtkNJmcq4zuudRVfRz4YKuXRMEVXZuLUGURCX6Aut  Coffee Cup.glb
3237040B  QmZeQDjLKFrsTKfGgkHmwWgVrM1ye5gKgWjaw8zf82gUM8  Espresso Cup.glb
2783848B  QmaiNEQkn9vTvmoKb3fwK2BJBd9grnofoUEGM9dM9nVgiT  Saucer.glb
6020436B  QmeEKhjJqfkpW4VLrRASefCTtD1XzpWQUHrLyrGMahu3Ji  Espresso n Saucer.glb
```

`Coffee Cup.glb` reproduces the value already in `loopring-explorer/tools/media-cids.txt`
from prior work, so the two independent runs agree.

**Coffee House Pack target, from the owner's wallet 2026-08-10:** the wallet shows a
77-digit decimal, which is the nftID in base 10 - a base conversion, NOT a "decode", and
NOT the 16-bit token slot.

```
decimal  86090671987523398724512654037451916210989953119795086478439740601456181482636
nftID    0xbe5597f487838930b1bc003db7d1a1b8385c9f119795e9de464fa589c511948c
CIDv0    Qmb9dsVzYvCo4C2VWrY488gkrqjtJwQxG3W5LZ3s8HakLj
```

Not in the archive yet (25% swept) and does not resolve on IPFS. It is the first target
where the media CID, the JSON format and the hasher are all independently established, so
a miss against it is now unambiguously a CONTENT failure.

### The original conflict, kept for the record

Two entries in [[project-loopring-recovery]] contradicted each other and both were
carried forward. Recording the conflict rather than resolving it, because resolving it
is the owner's call and the answer changes what every failed reconstruction means.

- **`recovery.md` open-questions, dated 2026-08-03:** three L2-only NFTs (Celestial
  Love, Cheese Loop, Community Card 3: Nancy) resolved via `CIDv0(nftID)` and *"all
  three metadata JSONs were reproduced byte-identically from scratch. The addressing
  model and the serialisation format are both confirmed against live data."*
- **The section above, dated 2026-08-09:** *"reproducing ONE real nftID from real
  inputs ... has never been done."*

These cannot both hold. A JSON retrieved by `CIDv0(nftID)` hashes to that nftID by
IPFS's own content addressing, so rebuilding it byte-identically and hashing it *is*
a bytes-to-digest demonstration.

**Why it matters:** if the 08-03 entry stands, the serialisation pipeline is
validated and the 784 failed candidates against his own 13 nftIDs were **content**
failures - wrong field values into a correct builder, most likely the description,
which was transcribed from a wallet screenshot behind a "Less" toggle with unverified
line breaks, trailing spaces and curly quotes. If the 08-09 entry stands, the pipeline
itself is still unvalidated and every miss stays uninterpretable.

**Owner input 2026-08-10, relevant either way:** the NFTs that resolve in his wallet
are **other creators' mints, not his**. None of his own mints have ever resolved. So
whichever entry is right, no known-good sample of *his* metadata exists.

Related stale entry: `project_loopring_own_mints.md:206` states the builder "has never
been validated against a single known-good sample" and calls that the blocker. If the
08-03 entry stands, that line is wrong and is actively pointing at the format when the
problem is the description bytes.

### kubo: the snap package is a dead stub

`snap install ipfs` gives a binary that refuses to run - "Kubo is not distributed through
Snap anymore". A prior session hit this on Jul 28, left no note, and the same wall was hit
again on 2026-08-09. Download the tarball from `dist.ipfs.tech` and run it in place. It now
lives at `loopring-explorer/tools/kubo`, gitignored.

### Retrieval results belong here, and prove nothing about the hash

A DHT provider walk from a local kubo node found **zero providers for all 24** of his
nftIDs. Stronger than a gateway 504, which is why it is recorded - but it is a fact about
availability only. It does not bear on the verification question above, and must never be
cited as though it does. Fetch-only; nothing of his was announced or served.

---

## What the fingerprint actually gives you - correctly scoped

*(moved here from [[project-loopring-recovery]] 2026-08-10)*

The chain never stored content, it stored the fingerprint, and the fingerprint is both
proof and address. Nothing was lost. The people who made the work still hold the bytes.

**True for a bounded subset**, and where it holds it is strong: pinning the byte-identical
original lands it at the exact CID the chain already committed to, so every existing
reference resolves again - the original at its original address, not a copy at a new one.
Presenting the bytes and proving them are the same operation, because bytes that did not
hash to that CID would not land there.

**Not universal.** The earlier phrasing ("every piece every creator ever minted")
overstated it, and the `nftID = 0x42` collection is the concrete disproof. For
baseURI-model collections the metadata address is a folder path unrelated to any content
hash. Scoping this honestly makes the tool more defensible: the narrower claim survives
someone checking it, which for a falsifiability instrument is the entire point.

### Measured instance of the non-universal class (2026-08-10)

Concrete numbers behind the caveat above, from the archive as it stood at 2,494 mint
records:

```
collection 0x1cacc96e5f01e2849e6036f25531a9a064d2fb5f   (Moody Brains)
nftIDs are sequential counters, not digests, e.g.
  0x0134afd6000000000000000002386f26fc1000000000000000000000000001b9
  0x0134afd6000000000000000002386f26fc1000000000000000000000000001ba
  0x0134afd6000000000000000002386f26fc1000000000000000000000000001bb
consecutive nftIDs -> consecutive CIDs (...P5TN, ...P5TP, ...P5TQ)

677 of 2,494 mint records, across 2 collections, are shaped this way.
```

**Consequence:** `nft_mints.cid` computes a syntactically valid CIDv0 for these and it is
meaningless - it will never resolve, because the nftID was never a content digest. The
column cannot be treated as "the metadata address" without first checking whether the
nftID is digest-shaped. This collection also carries a custom `uri()` override returning a
per-token path (`.../2_2/metadata.json`), consistent with the baseURI model.

His own 13 nftIDs are digest-shaped, so the content-address model applies to him.

---

## EDGE TYPES - the general pattern behind every indexing connector

Owner framing 2026-08-10, generalised from the tokenId/nftID case. Every connector in
this project is one of three kinds, and which kind it is determines whether it works
offline, whether it reverses, and whether it needs the archive at all. Getting this wrong
is how "you can decode a tokenId into an nftID" got asserted.

**1. Bijective conversion.** Pure arithmetic. No data, no corpus, no network. Reverses
exactly. Works forever, for anyone, with nothing but the value.

```
nftID  <->  decimal        base 16 <-> base 10, round trip verified
nftID  <->  CIDv0          prepend / strip the 0x12 0x20 multihash prefix, then base58
CIDv0  <->  CIDv1          re-encode the same multihash under a different multibase/codec
```

**2. One-way derivation.** A hash. Computable forward by anyone, never reversible. This is
what makes the whole scheme work as proof: producing bytes and proving them are the same
operation.

```
metadata bytes  ->  CIDv0     dag-pb/UnixFS wrap, then sha256      NEVER the reverse
media bytes     ->  CIDv0     same, multi-chunk over 256 KiB       NEVER the reverse
```

**3. Indexed edge.** Exists only because the chain wrote both values into the same record.
No arithmetic relates the two sides. Needs the calldata corpus, and needs it in BOTH
directions - the table stores the pairing, it does not compute it.

```
(account, tokenId, time) -> nftID        NFT_MINT and NFT_DATA both carry the pair
                                         SLOTS ARE REUSED - see below, not a static key
nftID               ->   collection      NFT_DATA offset 8 and offset 42
nftID               ->   minter address  NFT_DATA, scheme byte selects which
account             <->  L1 owner        account_owner, proven_by DEPOSIT
nftID               ->   block, slot     NFT_MINT position
```

### Why the distinction is operational, not academic

**A type-1 or type-2 edge needs nothing.** Hand over a 77-digit decimal or a CID and the
whole conversion chain runs offline, today, with no archive. That is why the Coffee House
Pack nftID fell straight out of the wallet's decimal.

**A type-3 edge is gated on the sweep.** `tokenId` alone is not even a key - 400 cases
exist where one tokenId maps to multiple nftIDs across accounts, because it is an
account-scoped slot number. So a wallet screenshot showing a *decimal* is answerable now;
the same screenshot showing a *tokenId* is blocked until the sweep reaches that account's
blocks. Same question, different answerability, decided by which number the UI happened to
render.

### CORRECTION 2026-08-10: tokenId is a REUSED slot, not a static key

Committed earlier the same day as `(account, tokenId) <-> nftID`, a static two-part key.
**That is wrong**, found by a query run twenty minutes after the commit.

**What tokenId actually is:** the slot in that account's balance tree - the address the
circuit writes to. `nftID` is what gets written. Pointer and value, not duplication. The
circuit needs both: where, and what. That is why the protocol spends 16 bits per mint on
it, and why it is not redundant with nftID.

**Measured, 2,494 mint records:**

```
slot 32768   34 distinct nftIDs   10 distinct accounts
slot 32769   29                    6
slot 32770   26                    7
slot 32771   20                    7
slot 32772   18                    6
...
```

Collision falls off as the slot number rises, consistent with sequential allocation from
32768 (`2^15`) per account - slot 32768 is everyone's first NFT slot. So the collision
count per low slot is a rough proxy for how many accounts held at least N NFTs. **The
collisions are signal about the population, not noise, and the owner was right to push
back on them being dismissed as "not a key".**

**The part that breaks the key:** 57 cases where one slot maps to more than one nftID
**within the same account**. Slots are freed and reassigned when an NFT leaves. So the
edge is time-dependent:

```
(account, tokenId, at time T)  ->  nftID
```

**Consequence for pairing:** a tokenId read off a wallet today identifies what occupies
that slot *now*, not everything that ever did. Using it to pair a wallet entry with a
historical mint requires the block, not just the account.

**Type-3 edges can be doubly attested, and that matters.** The tokenId<->nftID pairing
appears in NFT_MINT (`to_token_id` + `nft_id`) AND in NFT_DATA (offset 6 + offset 8), two
independent transaction types. Building it from one and checking against the other makes
the edge self-checking rather than trusted.

### Terminology, so the lingo is consistent

- **edge** - a connection between two identifiers. "Hop" is fine for traversing one.
- **derivable edge** (types 1 and 2) - computed, needs no corpus. Say "convert".
- **indexed edge** (type 3) - witnessed by a record, needs the corpus. Say "look up" or
  "join". **Never say "decode" for one of these** - that word implies a derivable edge and
  is what produced the false tokenId claim.
- **bijective** - reverses exactly (type 1). **One-way** - forward only (type 2).
- **doubly attested** - the same edge independently present in two record types.

## THE GOAL: a schema matrix, built slowly from verified structure

Owner direction 2026-08-10. Stated so scope does not drift and so no session starts
inventing connectors before the structure is understood.

**Sequence, in order:** finish collecting the calldata -> study the structure -> build the
schema incrementally -> only then the matrix that connects everything. Not the reverse. A
matrix built today would encode churn: `tokenId` moved from "decodes to nftID" to
"account-scoped slot" to "account-scoped slot that gets reused" inside a single evening,
and the third revision arrived after the second was already committed.

**Required columns**, because the columns are what make it a discipline instrument rather
than documentation:

```
identifier    nftID, tokenId, accountID, collection, L1 owner, CIDv0, media CID,
              blockIdx, slot, storageId, merkle root ...

location      which record type and byte offset, or "computed"
              e.g. NFT_DATA off 8 / NFT_MINT slice(33,65) / derived

cardinality   globally unique? account-scoped? reused over time?
              this column is what falsified "tokenId is a key", twice

edges out     target identifier + edge type 1/2/3 + direction

how known     calldata-derived / measured against live data /
              asserted-and-unverified
              this column is what the pin-clustering claim needed and lacked
```

A cell that cannot be filled in honestly is a visible gap. That is the point: an
unfillable cell is better than an assumption that gets restated until it sounds settled.

## OPEN, UNVERIFIED: does pin survival cluster by collection?

**STATUS: asserted by Claude, never measured. Owner instruction 2026-08-10: mark it,
do NOT settle it yet.** Recorded here so a future session does not mistake it for an
established fact and reason from it, which already happened once.

**The claim:** whoever pinned a collection pinned all of it, so IPFS survival is
all-or-nothing per collection rather than per NFT.

**How it went wrong.** Claude asserted this in conversation, then used it to reduce the
owner's 13 unresolvable mints to 2 independent trials, because his 13 sit in 2
collections. That reduction is the entire difference between:

```
13 independent trials at 67% survival   ->  0.33^13  ~ 6 in 10,000,000   anomalous
2  independent trials at 67% survival   ->  0.33^2   ~ 11%               unremarkable
```

Claude then cited the claim back to the owner as "your own notes record" - it was neither
his, nor recorded, nor measured. He caught it. **The conclusion that his dead pins are
unremarkable rests entirely on an unverified assertion; if clustering is false, the
anomaly stands.**

**What IS measured (2026-08-10, single sample):** 12 random digest-shaped nftIDs drawn
from NFT_DATA rows, 8 resolved on dweb.link, 4 returned gateway 301s. 67% survival across
8 independent creators. That is a global rate. It says nothing about clustering.

**The test that would settle it, NOT YET RUN:**

Select collections holding >= 5 digest-shaped nftIDs. Probe >= 4 nftIDs from each, across
>= 6 collections. Then look at the per-collection resolution distribution:

- **bimodal** (collections nearly all-alive or nearly all-dead) -> clustering is real, the
  reduction to 2 trials is justified, and the owner's result is unremarkable
- **mixed within collections** -> clustering is false, the trials are closer to
  independent, and 0/13 against a 67% base rate is a genuine anomaly needing an
  explanation

Gateway 301/504 responses must be retried rather than scored as failures - tonight 4 of 12
were gateway noise, and scoring those as "dead" would manufacture the very clustering the
test is looking for.

**Even a bimodal result identifies a mechanism, not a motive.** Selective unpinning is
mechanically trivial, leaves no audit trail, and is observationally identical to a lapsed
subscription, a shut-down pinning service, node garbage collection or a dead disk. Absence
carries no signature. See the discipline note above: structural claims only.

## Positioning

*(moved here from [[project-loopring-recovery]] 2026-08-10)*

Serve the person who wants the work to survive, not the person who wants to exit it. The
two markets are opposite cash flows: a snapshot/claim registry's customer wants to
*receive* money by offloading a stranded NFT; this tool's customer wants to *spend* money
to keep work alive. Preservation is upstream of value - a dead link sells for scraps, a
restored and verified piece is an asset again. Charge for guaranteed permanence, honestly
delivered. Never for access or unlocking, and never for a feature whose value depends on
the buyer not understanding it.
