---
name: project-loopring-own-mints
description: "His own Loopring L2 account and every mint of his found in L1 calldata, plus archive state and the reconstruction attempt that failed. Derived data - do not re-derive."
metadata:
  type: project
---

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

`creatorFeeBips` here IS the `royalty_percentage` input for reconstruction, per
mint. Do not guess it - 10 on most, 0 on three.

Note "Pizza Pie on a Stone" displays **85** in the wallet. That is the balance
held now, not the mint amount. Two candidates have `amount = 100`
(58754/21 and 58788/43) but neither is confirmed to be Pizza.

## Archive state (2026-08-09)

- `~/github/lonewolf-loopring/loopring-archive/loopring-archive.db`
- enumeration COMPLETE across the full L1 span from the deploy block
  (11,149,814): **67,886 submissions** located
- **9,954 blocks** merged from the preserved copy and each re-verified against
  its own `public_data_hash` rather than trusting the stored flag. 0 failures.
- **57,932 blocks still to fetch**
- preserved backup: `old-archive-2026-08-03.db` in the same directory
- The Graph's block numbers run **25 BELOW** the chain's `blockIdx`. Anchor on
  transaction hash, never on an index's numbering.

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
- multi-chunk media hashing uses `ipfs-only-hash` defaults, never confirmed to
  match the parameters the pinning client used. Every one of those images
  exceeds the 262144-byte chunk size
- whether the minting client omitted empty schema fields or emitted them

## Mint flow, from him directly

Single file upload, not a folder - so bare-CID `image` values, and directory
CIDs are not needed. The mint form takes media, description and traits. Pizza
had no traits.

## Scripts written for this (loopring-explorer/scripts)

- `derive-from-calldata.js` - builds `nft_mints` and `account_owner` from block
  data. No network.
- `merge-archive.js` - merges a prior archive, re-verifying every block.
- `prove-nft.js` / `sweep.js` - the reconstruction sweep. No network.

See [[project-loopring-recovery]] for the metadata blueprint and
[[feedback-failure-record-2026-08]] for what went wrong in the session that
produced all of this.
