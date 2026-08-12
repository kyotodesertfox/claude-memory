---
name: loopring-calldata-retrieval
description: "State of the L1 calldata collection - what was retrieved, exactly what is still missing, and what closes each gap"
metadata: 
  node_type: memory
  type: project
  originSessionId: cbbd03b1-8886-4e2d-9be8-08400e9c318d
  modified: 2026-08-11T23:08:40.754Z
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.

CLAUDE NEVER DOWNLOADS MEDIA - ABSOLUTE: Claude is NEVER permitted to download any media. Not imagery, not video, not JSON. Not from IPFS, not from a gateway, not from any URL, not from any content-addressed source. Claude is never permitted to access or analyze any of it directly. No exceptions. Not to test something, not to verify something, not once.

---

## STATE AS OF 2026-08-12: 67,896 / 67,896 - COMPLETE ON BLOCKS

```
discovered    67896 txs, 67896 fetched, 0 remaining
blocks        67896 stored, 67896 verified, idx 1..67896
gap runs      0
```

Every stored block passes `sha256(data) == publicDataHash`. Zero verification
failures across the entire corpus. The block index is contiguous from 1 to
67,896 with no holes.

**The one remaining audit flag is `L1 25715318..25719813 NEVER QUERIED`, which is
the chain head advancing past the last enumerate. It is not a hole in the
history.**

### What closed it

1. `enumerate` swept the full L1 span contiguously. This closed the
   `23569814..23569999` hole (186 L1 blocks that had never entered `log_cursor`)
   and raised known submissions 67,886 -> 67,896.
2. `fetch` twice: 24 txs then 2 txs. 26 stored, 26 verified, zero failures.

### WHY THE FIRST PASS DIVERGED - the important part

The 26 missing blocks were **not special**. All `block_type 0`, all
`block_in_tx 0`, sizes spread normally across 16..384, nothing malformed. The
divergence was never in the data.

Two distinct and unrelated defects:

**(a) The RPC silently under-reported logs.** The original run detected 10
missing blocks and re-queried, six times, then refused to fetch:

```
pass 2..6: 2 gap(s), 10 block(s) missing - re-querying
  blockIdx 65726..65730  (L1 23577769..23580601)
  blockIdx 65747..65751  (L1 23589532..23592538)
ENUMERATION INCOMPLETE after 6 passes
refusing to fetch on an incomplete enumeration
```

**Those retry windows were correct.** Confirmed 2026-08-12 by joining the
recovered blocks to `l1_txs`: every one of the 10 lives inside them.

```
blockIdx 65726  L1 23578433      window 23577769..23580601
blockIdx 65730  L1 23579968      window 23577769..23580601
blockIdx 65747  L1 23590155      window 23589532..23592538
blockIdx 65751  L1 23591907      window 23589532..23592538
```

So the script asked the right endpoint for the right range six consecutive times
and received an incomplete event set every time, **with no error and no failure
counter** - the run log contains zero error lines and zero nonzero `failed`
counts. The same query today returned them.

**A single RPC endpoint returning HTTP success is not evidence that it returned
everything.** It under-reports silently and repeatably. Nothing in the response
distinguishes "no events here" from "I did not give you the events here."

**(b) A 186-block range never entered `log_cursor` at all** - `23569814..23569999`.
Separate from (a), and not covered by any retry window, which is why targeted
retries could never have fixed it and a full contiguous sweep did.

### What this is evidence FOR

The only thing that caught either defect was the archive's own self-audit:
blockIdx contiguity plus `sha256(data) == publicDataHash`, compared against what
the endpoint claimed. The script refused to fetch on an incomplete enumeration
rather than proceeding and producing a plausible-looking archive with ten silent
holes in it.

That is the project's thesis demonstrated against its own tooling: a source that
answers confidently is not the same as a source that answers completely, and
only verification against the artifact itself tells them apart. A Merkle root
proves inclusion and can never reveal omission - this is the omission case, and
it was invisible until the denominator was checked.

**Consequence for any claim made about this archive:** say what was queried, say
what verified, and say that the endpoint was caught under-reporting. The
completeness claim is now supportable for blocks 1..67,896; it was not before,
and the difference is documented above rather than assumed.

---

## Superseded: state as of 2026-08-11

## State as of 2026-08-11

One `archive.js fetch` process, 28h57m, ~0.50 tx/s, single PID, no restarts.

```
db            ~/github/lonewolf-loopring/loopring-archive/loopring-archive.db
log ranges    1457 chunks covering L1 11149814..25715317
discovered    67886 txs, 67870 fetched, 16 remaining
blocks        67870 stored, 67870 verified, idx 1..67896
```

**Every stored block passed `sha256(data) == publicDataHash`. Zero unverified,
zero verification failures across the entire corpus.**

## IT IS NOT COMPLETE, and the script says so itself

The run ends with a completeness audit that refuses to round up:

```
--- completeness audit ---
L1 span queried      : 11149814..25715317
uncovered L1 ranges  : 1   <-- INCOMPLETE
   NEVER QUERIED L1 23569814..23569999
submissions found    : 67886
stored blocks        : 67870
sha256 verified      : 67870
found but not stored : 16   <-- INCOMPLETE
ARCHIVE IS NOT COMPLETE
```

That self-report is the important part. A corpus whose value is completeness
has to be able to say when it is not complete, and this one does, by name and
by range. 99.976% is not 100% and the script does not pretend otherwise.

### Gap 1 - 16 transactions found but not stored

They were discovered but the store failed - the fetch path catches, rolls back
the transaction, logs `store failed`, and continues **without marking them
fetched**. So nothing is corrupt and nothing is lost; they remain queued and a
re-run picks them up. Cause is almost certainly an RPC returning `result: null`
or a transport failure, not anything about the data.

```
0xbe734845ba5a80640437853e420139072823c0885898a6decd6708970fbc67ee
0xaabe4c8e0246cfb175bd4639781a1062b9f9f3b658f4097b482acbd1d2d7682c
0xcd4caa0bdc20de7db4551f596fd7c83820126599e3124a3a97ec867c694efe1b
0x437c0c5ee3959dd232d080464e88660f9480c88173404db7d35bab78f106b19e
0xbd4d74788f8dc65a0b5ffb8153ee4b837dacf76448d8aaa18107603954ac4fb2
0x0703a493aba9cd8d7f2dce6657f1e74ac139a42cfc14385e99876ddae6c95c06
0x04003c86972061159206851ab64e6ebf30ee482d5adc0e2d108199dd91a1da8d
0xb14be57bf39536021236433bff8f2c9b1c69d74d358178af7023cd73fe5da26e
0xbbebba5f72c52637cf7026e5a2390065bab2c2eb36f9d043c0b2b750ab520529
0x1c37d98e7cff69ed2636520599fd45686f0c3b04c7b2aa3380431e4c22577605
0xe7cfd1ff5ee973cf0c996c1c17d5ab907d963032a44a2a53ac1fa9bf8bb17d4c
0xf7d9853964d9944ba5fa8aaa7e47d665dc62c4eff11c8fc5c61d7fa0e8280b4a
0x1ad9989584dcdafa98cc98b2bb2207e7e7e15f8f76772e7f8f9e5e4f82698bb9
0x6a076d19bdc1bd597cdd8ed638d5fed5736914d5f6012a64564c6195bf6ea7e7
0xf1cc7f0938f1908acdf956e3301da9c7e6318bd311ae64369dea6229df8e8688
0x8553ee3083abf16cb324cc975d5714a9a1c505fa40cf499e7b43d334855583cc
```

### Gap 2 - 186 L1 blocks never scanned: 23569814..23569999

This one is worse than the 16, and the reason matters. **The denominator is
incomplete.** Those L1 blocks were never queried for `BlockSubmitted` events,
so any Loopring block submitted in that window is not in `discovered` at all -
it is not among the 67,886, and it is not among the 16. Nothing knows it is
missing except the range audit.

Until that window is enumerated, "67,886 submissions" is a floor, not a total,
and no claim of completeness can rest on it.

## Commands

`archive.js` takes one argument, default `all`:

```
status      print db path, log chunk coverage, discovered/fetched, block counts
verify      run the completeness audit alone, no network
enumerate   scan L1 for BlockSubmitted, fill log_cursor and discovered
fetch       fetch and store what is discovered but not yet fetched
all         enumerate then fetch (the default)
```

`enumerate` closes gap 2, `fetch` closes gap 1, `all` does both. Progress is
saved continuously and SIGINT finishes the current item, so it is safe to
interrupt.

## Derived tables are STALE - this is the trap

`nft_mints` and `nft_collections` were built when the corpus was roughly 14,000
blocks. They have not been rebuilt since, and the corpus is now 67,870.

**Consequences observed 2026-08-11:**

- `nft_mints` spans block_idx 57,923..67,894 only. Roughly 44,000 collected
  blocks have never been decoded at all.
- All five of the owner's collection address prefixes returned zero rows. That
  is a derivation gap, not a coverage gap - the NFT_DATA is very likely already
  in the archive, undecoded.
- The Coffee House Pack nftID `0xbe5597f487838930b1bc003db7d1a1b8385c9f119795e9de464fa589c511948c`
  returned "not in the archive," which was never a real negative - it simply
  was not in the decoded window.

**Any query against the derived tables right now is answering about 18% of what
has been collected.** Re-derive before drawing any conclusion from an absence.

## Why finishing matters, specifically

Completeness is not tidiness. It is the precondition for the one claim that
cannot be made from a partial corpus: **absence.** Proving that an account did
NOT mint something requires a complete enumeration - from an incomplete one,
absence means nothing. Everything else (who did mint a given nftID, which
collection, when) works fine at 99.976%.

See [[project-loopring-nftid]] for what the derived data is for, and
[[project-loopring-recovery]] for the metadata work that sits downstream of it.
