---
name: project-loopring-own-mints
description: "His own Loopring L2 account and every mint of his found in L1 calldata, plus archive state and the reconstruction attempt that failed. Derived data - do not re-derive."
metadata:
  type: project
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.

# His own Loopring mints, from calldata

All of this was derived from L1 calldata alone on 2026-08-09. No index, no API,
no wallet export. Recorded so a future session does not repeat the merge and the
derivation to get back here.

## Account

```
account_id 33443
owner      0xc22724df2f8d30db4ed2f3bff317897bfc2c494b
proven by  a DEPOSIT transaction (carries owner + accountID inline)
```

## The 13 mints found so far

`block_idx | slot | nftID | creatorFeeBips | amount | nftType | nftSlot`

```
58178  97  0x79da903e8eaff0cbf9c39b75a7ed27c78fcf27200986dcd4b2e301a2745e6868  10   50  0  33241
58584  17  0x7c2445a50d80ded5ef303a88dd64fb904afd8ea36b40452993acb9e5a42ea930  10   50  0  33245
58754  21  0xc559be02e4f950d79ce577aca758a524aa2468ec428e3b1d45050a715ba8f5a5  10  100  0  33247
58788  43  0x51099b42197966f9ce7be80e5c55a42aaa93d0caa2fb014dd8e85a9ceb15d951  10  100  0  33248
58911  11  0x60f0810008df7031b326ae290250cd09e83a4a117cfa7eaf935760670c424191  10    1  0  33297
58914   5  0xff50d429e053f438897972ee01c813abdae99a5ff61ab2e2805bb881cef70597  10    1  0  33298
58923   1  0x7d8b09021b7d33c7411a695634bd55287a83c1bd840db7013d6e1f191c87e334   0   10  0  33299
58953  18  0x6ff0dc96f4e495f8cf6d875507cf0d2944e7ab8766406210ba2ed5e1e47ab262   0    1  0  33301
58953  33  0x32b2f45e911fb130f0afaee7216d2811999b5eb51783327e0f8531712d96e22b  10    1  0  33302
58953  36  0x59861ac3bf05a284b469f56c778fb2a7117388daaaf3dd59755ad10d60a28fa4  10    1  0  33303
60429  56  0x400cd2e78bf5f36b3b2febc0f6c745149a22beab0e132f36b23b6473934cc569  10   13  0  33304
64755  12  0x4e5665c83c95a671a6d2d81328198b87a789f20347955569f4eb0b04518113bd  10    1  0  33310
66820   1  0x29fc46f9dec98398c4d27ecb93c6190ee24db372d22f4d257e4682078e0b13c2   0    1  0  33311
```

**This is not all of them.** The archive currently holds blockIdx 57,917 to
67,896 - roughly 15% of the history. Anything minted outside that window is not
listed above.

`creatorFeeBips` here IS the `royalty_percentage` input, per mint. Do not guess it.

**Confirmed 2026-08-09 from NFT_DATA calldata: all 13 of his that carry NFT_DATA read
`creatorFeeBips = 10`, including Quest POI.** So royalty 10 was already correct in the
hash attempts and is ELIMINATED as the cause of those misses. The 0 values in the mint
table below are byte-65 reads on mints with no NFT_DATA counterpart.

`royaltyPercentage` in the SDK and `creatorFeeBips` in the circuit are the same field -
`sign_tools.ts` signs Poseidon over exactly the six inputs `NftDataGadget` hashes.

Note "Pizza Pie on a Stone" displays **85** in the wallet. That is the balance
held now, not the mint amount. Two candidates have `amount = 100`
(58754/21 and 58788/43) but neither is confirmed to be Pizza.

## His collections

Both `owner()` to `0xc22724df2f8d30db4ed2f3bff317897bfc2c494b` on L1. That part is a
chain fact, read by `eth_call`.

| Address | Name | Source of the name |
|---|---|---|
| `0x8eb4228702fc4cdf202b9dc17cd50b05dce096fe` | **3D Metaverse Assets** | **Owner, first-hand.** NOT chain-derived. |
| `0x7a5208036ceb854bcc1463943b4287f0449ef769` | **UNVERIFIED** | Recorded for future identification. Do not guess it. |

**A collection has no name on-chain, BY DESIGN.** `name()` and `symbol()` are
unimplemented on both, and `contractURI()` returns `https://nftinfos.loopring.io/<address>`,
which is dead. Confirmed from the SDK's own `collectionNFT.md`: a collection's `name`,
`description`, `avatar`, `banner` and `tileUri` were **stored on Loopring's service and
user-editable there** - "Loopring own collection on L2, allow user to view/edit their
Collection information." Never on-chain, not necessarily on IPFS.

So a collection name can only come from the owner or from the NFTs inside it. It is not a
gap in the derivation and no amount of chain work recovers it.

Both are EIP-1167 proxies delegating to implementation
`0xaf4c6c97c620425b9d05c6a12f886d14a04eff06`, which is NOT the implementation baked into
`loopring_sdk`'s mainnet `CREATION_CODE`. See [[project-loopring-recovery]] for why that
kills the CREATE2 route.

### Which of his nftIDs sit in which

From `MintFromL2` L1 logs, which name the minter inline. 13 identified so far.

**3D Metaverse Assets** (`0x8eb42287...`) - 9:
```
0x1d85359ff36d815dd5c1d78723d5b88b16f064bf425fde730dd42b37d30a4e64
0x2075e56f13da8a4c9945c2931d29ed18f571bfc6ac8d07fc7a2bf78339f86a1f
0x40349ea298d6a0d26052b06cb521381c1af6919e4faa3f4065eb7ada3b992d68
0x51099b42197966f9ce7be80e5c55a42aaa93d0caa2fb014dd8e85a9ceb15d951
0x79da903e8eaff0cbf9c39b75a7ed27c78fcf27200986dcd4b2e301a2745e6868
0x8b14a4a5c4c23f44d5fb8543bc78045fdf5df2c303fc770917ebcaa9c77be276
0xb3d016c4eff6eca0d0cdb23a04b69088b016f350070f443c5bfc14e8646684d3
0xc25e2d01af6f9c791ddfabb182e3c4a26221f0777c406714477fedb89e3d2eb5
0xc2a15f6ca2bcf1a424d1e4494ad9303539ae7a3e3e188a26e91385bc581b84ee
```

**UNVERIFIED collection** (`0x7a520803...`) - 4:
```
0x1594154fedec166b317e368addeecf3440947e87606fe934015e245e9a769860
0x7c2445a50d80ded5ef303a88dd64fb904afd8ea36b40452993acb9e5a42ea930
0xac5466c1086fc4463a6905489b9357af122482665fd0b4351b93658b3eaa3d1e
0xcbefd63f297e5c664efd5bf5c76d526c6d5f1dd458aec2a76e6adf3d08281094
```

Identifying `0x7a520803...` means resolving one of those four nftIDs to its metadata and
reading the `name` field, or the owner recognising the work. **Do not infer it from the
other collection.**

## The two NFTs worked on directly (2026-08-09)

Everything below came from him or from the chain, and is recorded so no future session
re-derives it or re-runs the same failed sweeps.

### Coffee House Pack
```
tokenID (decimal) 86090671987523398724512654037451916210989953119795086478439740601456181482636
nftID             0xbe5597f487838930b1bc003db7d1a1b8385c9f119795e9de464fa589c511948c
CIDv0 (metadata)  Qmb9dsVzYvCo4C2VWrY488gkrqjtJwQxG3W5LZ3s8HakLj
collection        0x8eb4228702fc4cdf202b9dc17cd50b05dce096fe  (3D Metaverse Assets)
name              Coffee House Pack
description       This Coffee House Pack is SURE to be a coffee aficionado's dream!
held              488  (of an edition he believes was 500)
source folder     /home/zenko/Creations/Metaverse Assets/Coffee Pack
```
NOT in the archive - its mint falls outside the 9,954-block window, so `creatorFeeBips`
is unreadable for it.

### Quest POI - the wallet calls it "Point of Interest Marker"
```
tokenID (decimal) 87915086873263964949986678250415073833433150787371560661018672339866483502773
nftID             0xc25e2d01af6f9c791ddfabb182e3c4a26221f0777c406714477fedb89e3d2eb5
CIDv0 (metadata)  QmbRP6KJbqW1U62or1891KarQZPZYgf5uNfMiP7CthJ6FE
collection        0x8eb4228702fc4cdf202b9dc17cd50b05dce096fe
name              Point of Interest Marker          <- NOT "Quest POI", which is the folder
description       A Point of Interest marker is a navigational guidance marker in an area
                  or vicinity that highlights or draws attention to a noteworthy location.
                  Whether it be a Quest, Landmark, or any other place of special interest.
properties        color = black                     <- the wallet renders a trait
image             Quest POI.jpg      -> QmPPRELUYnh7SoDsY5AgajqzFHLHGjm2emMHXPJJDMRE8N
animation         POI-Marker.glb     -> QmabpPeVySFV9s3XngVM4QDF4fXfmSWNHtPNbmZNePzxcQ
creatorFeeBips    10   (READ FROM NFT_DATA CALLDATA, not guessed)
source folder     /home/zenko/Creations/Metaverse Assets/Quest POI
```
**Quest POI proves the four-field metadata format in [[project-loopring-recovery]] is
incomplete.** It carries a trait the samples never had.

### What was tried and ELIMINATED - do not repeat

| Sweep | Candidates | Result |
|---|---|---|
| Coffee House Pack, 9 media files x 2 apostrophes x royalty {10,0,5} x 8 whitespace | 432 | no match |
| Quest POI, 4 image + 7 animation CID encodings x 6 trait forms x royalty {10,0,5} x 8 whitespace, hashed BOTH dag-pb and raw sha256 | 4,032 | no match |

Eliminated as causes: **the hasher** (kubo agrees at every link), **the media CID
encoding** (raw-leaves, CIDv1 and trickle variants all generated with kubo and tested),
**royalty** (10 is confirmed from calldata for Quest POI), **whitespace** (all 8), and
**the apostrophe form**.

Not eliminated: whether those files are the uploaded bytes, and **the document's field
set** - which Quest POI already showed memory has wrong.

### Who holds his work on L1

Two collectors, 19 units across 13 tokens, all withdrawn to L1:
```
0xda0f9f916db23d3c8c097376f60196483550869b   L2 account 298669   12 of his
0x7e5863f0246602c12765e11a935c6697b090201c                        2 of his
```
On 2026-01-01 06:31:11 UTC account 298669 withdrew 17 NFTs across 9 collections in one
operator block submission, 8 of them his, plus a second tx with 4 more. He did NOT
withdraw anything - every one of these was a collector exiting.

## Archive state (2026-08-09)

- `~/github/lonewolf-loopring/loopring-archive/loopring-archive.db`
- enumeration COMPLETE across the full L1 span from the deploy block
  (11,149,814): **67,886 submissions** located
- **9,954 blocks** merged from the preserved copy and each re-verified against
  its own `public_data_hash` rather than trusting the stored flag. 0 failures.
- **57,932 blocks still to fetch**
- preserved backup: `old-archive-2026-08-03.db` in the same directory
- **Anchor on transaction hash, never on a block number that did not come from a
  BlockSubmitted topic.** A numbering previously recorded here ran 25 below the chain's
  real `blockIdx` and got written down as fact.

## The reconstruction attempt that failed - do not repeat as-is

784 candidates hashed against all 13 nftIDs. Zero matches.

Sweep covered: 5 media files from the Pizza source folder, `decimals` present
and absent, `royalty_percentage` as number and string at 10 / 5 / 0 / omitted,
2 separator variants, 4 trailing-whitespace variants. Name and description taken
from a wallet screenshot.

**This does NOT implicate his files.** It is uninterpretable, because:

**The builder has never been validated against a single known-good sample.**
That is the blocker. Until one retrieved metadata JSON is hashed and shown to
reproduce its own known CID, and rebuilt byte-identically from its own field
values, every miss is meaningless and every conclusion drawn from one is
guesswork. This is the same mistake that produced the "Coffee House Pack failed
because of the image bytes" conclusion, which was also unsupported.

Secondary unknowns, all still open:
- the description was transcribed from a UI render behind a "Less" toggle, so
  line breaks, trailing spaces and curly quotes are unverified
- ~~multi-chunk media hashing never confirmed~~ **RESOLVED 2026-08-09.** kubo
  agrees with `ipfs-only-hash` at every size. What remains unknown is only
  whether the PINNING CLIENT used kubo defaults; raw-leaves and CIDv1 media
  variants were generated with kubo and tested. See
  [[project-loopring-recovery]]
- whether the minting client omitted empty schema fields or emitted them

## Mint flow, from him directly

Single file upload, not a folder - so bare-CID `image` values, and directory
CIDs are not needed. The mint form takes media, description and traits. Pizza
had no traits.

## Scripts written for this (loopring-explorer/scripts)

- `derive-from-calldata.js` - builds `nft_mints` and `account_owner` from block
  data. No network.
- `merge-archive.js` - merges a prior archive, re-verifying every block.
- `prove-nft.js` / `sweep.js` - **DELETED 2026-08-09.** They were the
  reconstruction sweep. Removed as artifacts of a direction that was never
  asked for, and worthless regardless: never validated against a known-good
  sample, so every miss was uninterpretable.

See [[project-loopring-recovery]] for the metadata blueprint and
[[feedback-failure-record-2026-08]] for what went wrong in the session that
produced all of this.
