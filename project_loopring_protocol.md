---
name: project-loopring-protocol
description: "Verified decode reference for Loopring v3 L1 block calldata - layouts cross-checked against protocol source AND live mainnet blocks, with the NFT divergence between them documented"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2520caa1-3a2c-4959-8a24-bd8d5985eb1c
  modified: 2026-08-09T16:54:01.228Z
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.

# Loopring v3 L1 Calldata - Verified Decode Reference

## Read this first: the repo source does not match what was deployed

Loopring's published contract source is the obvious reference. For most transaction
types it matches the deployed protocol exactly. **For NFT mints it does not, and
trusting source over live data produces a broken decoder.**

The protocols repo (`upstream/protocols/.../libtransactions/`) describes a revision
where `NftMintTransaction.process` calls `NftDataTransaction.readDualNftData(...)`, so
`nftID` / `creatorFeeBips` / `nftType` / `minter` / `token` travel in **two separate
NFT_DATA (type 9) transactions** placed after the mint. The stated reason is real: the
full NFT payload needs 76 bytes and only 68 are available per transaction.

**CORRECTED 2026-08-09 - THIS WAS WRONG.** Deployed blocks carry `nftID` inline in the
mint at offset 33, which is real. But the claim that they contain **zero type-9
transactions is false**. The archive holds **82,314 NFT_DATA transactions**, covering
18,244 distinct nftIDs, every one carrying both minter and collection. Both mechanisms ran
on mainnet at once. The error came from never counting transaction types across the
corpus; it was assumed from a handful of blocks that happened to contain no type-9.

This was discovered the hard way on 2026-08-02: the decoder was "corrected" to the
source layout and would have replaced working nftIDs with nulls had it not been tested
against a real block first. See [[feedback-decode-first]] - fetch a real transaction and
read the structure. That rule exists precisely for this, and reading source felt like
the more rigorous move while being the wrong one.

**Standing rule for this protocol: when source and live data disagree, live data wins.**

## How each layout below was established

| Verified against | Types |
|---|---|
| Source `readTx` AND live mainnet data | DEPOSIT, WITHDRAWAL, TRANSFER, ACCOUNT_UPDATE |
| Live mainnet data, CONTRADICTING source | NFT_MINT |
| Source `readTx` only, no live sample yet | AMM_UPDATE, SIGNATURE_VERIFICATION |
| Neither - no Solidity exists | SPOT_TRADE |

### Verification receipts - chain only

Every value below was produced by parsing the archive and is anchored on the **L1
transaction hash**, never on anyone's block numbering. `blockIdx` is read from the
indexed topic of the BlockSubmitted event.

```
blockIdx 67894  (tx 0x008e577c...)  slot 1   minterAccountID 305952
blockIdx 67894  (tx 0x008e577c...)  slot 4   DEPOSIT 574300000000000000
                                             (addr, acct, token, amount all read inline)
blockIdx 67189  (tx 0xb7581ec2...)  slot 4   nftID 0x35899c2b...c6ce2624
                                             creatorFeeBips 10, one byte at offset 65
```

**Anchor on the transaction hash.** An index's block numbering is not the chain's:
one that was in use here ran 25 below the on-chain `blockIdx`, and those numbers got
recorded as chain facts. They were wrong. Any number that did not come from a
BlockSubmitted topic is not a block index.

## Entry point

- Attestation contract: `0x153CdDD727e407Cb951f728F24bEB9A5FaaA8512`
- Function selector: `0xdcb2aa31` (`submitBlocksWithCallbacks`)
- Sole block submitter (operator wallet): `0x487e8Be2BaD383b5B62fC5fb46005A8Fac10E341`

## Two-level ABI decode

Level 1 - strip the 4-byte selector, decode `(bool isDataCompressed, bytes blockData,
bytes callbackData)`.

Level 2 - `blockData` begins with its own 4-byte format prefix `0x53228430`. Skip it,
then decode the remainder as:
```
tuple(uint8 blockType, uint16 blockSize, uint8 blockVersion, bytes data,
      uint256[8] proof, bool storeDataHashOnchain, bytes auxiliaryData,
      bytes offchainData)[]
```
`blockSize` is the transaction count and lives in the struct, NOT inside `data`.

## Block header - first 98 bytes of `data`

| Offset | Size | Field |
|---|---|---|
| 0 | 20 | exchange address |
| 20 | 32 | merkleRootBefore |
| 52 | 32 | merkleRootAfter |
| 84 | 4 | timestamp (unix) |
| 88 | 1 | protocolFeeTakerBips |
| 89 | 1 | protocolFeeMakerBips |
| 90 | 4 | numConditionalTransactions |
| 94 | 4 | operatorAccountID |

## Split transaction layout

Source `ExchangeData.sol:139-141`, confirmed live:
```
TX_DATA_AVAILABILITY_SIZE        = 68
TX_DATA_AVAILABILITY_SIZE_PART_1 = 29
TX_DATA_AVAILABILITY_SIZE_PART_2 = 39
```

Transactions are NOT sequential. After the 98-byte header:
```
[98B header] [blockSize x 29B part1] [blockSize x 39B part2]
tx[i] = part1[i] ++ part2[i] = 68 bytes
```

## TransactionType enum

```
0 NOOP         3 TRANSFER        6 AMM_UPDATE               8 NFT_MINT
1 DEPOSIT      4 SPOT_TRADE      7 SIGNATURE_VERIFICATION   9 NFT_DATA (not used on mainnet)
2 WITHDRAWAL   5 ACCOUNT_UPDATE
```
`NftType`: `0 = ERC1155`, `1 = ERC721`.

## Transaction layouts (offsets within the reassembled 68-byte buffer)

### DEPOSIT (1) - verified live
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 20 | to (address) |
| 21 | 4 | toAccountID |
| 25 | 2 | tokenID |
| 27 | 12 | amount (uint96, raw) |

### WITHDRAWAL (2) - verified live, fully packed
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 1 | withdrawalType |
| 2 | 20 | from (address) |
| 22 | 4 | fromAccountID |
| 26 | 2 | tokenID |
| 28 | 12 | amount (uint96, raw) |
| 40 | 2 | feeTokenID |
| 42 | 2 | fee (Float16) |
| 44 | 4 | storageID |
| 48 | 20 | onchainDataHash (bytes20) |

`to` is in auxiliary data, not inline. Withdrawals always carry a real `from` - funds
must land somewhere on L1.

### TRANSFER (3) - verified live
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 1 | constant, must equal 1 |
| 2 | 4 | fromAccountID |
| 6 | 4 | toAccountID |
| 10 | 2 | tokenID |
| 12 | 3 | **amount (Float24 - must be decoded, not read raw)** |
| 15 | 2 | feeTokenID |
| 17 | 2 | fee (Float16) |
| 19 | 4 | storageID |
| 23 | 20 | to (address, often zero) |
| 43 | 20 | from (address, often zero) |

**Zero addresses are correct, not a decode failure.** Loopring writes an address into
calldata only when L1 needs it. For L2-to-L2 transfers both parties already exist in the
Merkle tree, so those fields are zero and **the account IDs are the real identifiers**.
Confirmed in block 67869: slot 0 carries a real `to` (`0x5f5d612d...`, an NFT collection)
while slots 2 and 3 are zero on both. If the offsets were wrong, slot 0 could not produce
a valid address.

### SPOT_TRADE (4) - NOT VERIFIABLE
No `SpotTradeTransaction.sol` exists. Spot trades touch no L1 state and are validated
entirely in the ZK circuit. The decoder's layout (accountIdA at 9, accountIdB at 13,
fills Float24 at 21/24) is unverified against both source and ground truth.

### ACCOUNT_UPDATE (5) - verified live
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 1 | constant, must equal 1 |
| 2 | 20 | owner (address) |
| 22 | 4 | accountID |
| 26 | 2 | feeTokenID |
| 28 | 2 | fee (Float16) |
| 30 | 32 | publicKey |
| 62 | 4 | nonce |

### AMM_UPDATE (6) - source only, no live sample
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 20 | owner |
| 21 | 4 | accountID |
| 25 | 2 | tokenID |
| 27 | 1 | feeBips |
| 28 | 12 | tokenWeight (uint96) |
| 40 | 4 | nonce |
| 44 | 12 | balance (uint96) |

### SIGNATURE_VERIFICATION (7) - source only, no live sample
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 20 | owner |
| 21 | 4 | accountID |
| 25 | 32 | data |

### NFT_MINT (8) - VERIFIED LIVE, CONTRADICTS SOURCE
| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 1 | nftType (0 = ERC1155, 1 = ERC721) |
| 2 | 4 | minterAccountID |
| 6 | 2 | toTokenID (NFT slot) |
| 8 | 2 | feeTokenID |
| 10 | 2 | fee (Float16) |
| 22 | 2 | amount (Float16) |
| 24 | 4 | storageID |
| 29 | 4 | toAccountID |
| 33 | 32 | **nftID - inline, NOT in a separate NFT_DATA tx** |
| 65 | 1 | **creatorFeeBips - ONE byte (uint8), not two** |

The `creatorFeeBips` width was a real bug in the original decoder: `readUint(65, 2)`
returned **2560** where the true value was **10**. Confirmed by re-parsing the block from
the archive, and the protocol `Nft` struct declares it `uint8`, which agrees.

**RESOLVED 2026-08-09: byte 1 is `mintType`, NOT `nftType`.** Counted across all 2,494
mints in the archive: **1,976 carry 0 and 518 carry 2.** Two is not a valid NftType
(0=ERC1155, 1=ERC721) but is exactly the deposit branch in the source
(`if (mint.mintType == 2)`, requiring `creatorFeeBips == 0` and minter == token contract).

**This is a live bug in `scripts/derive-from-calldata.js`** - it writes byte 1 into the
`nft_type` column, so 518 rows in `nft_mints` claim a standard that does not exist. The
real `nftType` is only available from NFT_DATA, byte 41.

### NFT_DATA (9) - VERIFIED LIVE, matches source exactly

**82,314 of these exist in the archive.** Emitted in PAIRS on the same nftID, differing
only in `scheme` and the trailing address.

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | type |
| 1 | 1 | **scheme**: 0 = WITH_MINTER_ADDRESS, 1 = WITH_TOKEN_ADDRESS |
| 2 | 4 | accountID (the `to` or `from` account) |
| 6 | 2 | tokenID (NFT slot) |
| 8 | 32 | nftID |
| 40 | 1 | creatorFeeBips |
| 41 | 1 | **nftType** (the real one) |
| 42 | 20 | minter (scheme 0) **or collection address (scheme 1)** |

**This is how a collection resolves from calldata.** 18,244 distinct nftIDs, all with both
halves present. It supersedes the L1-log route (679 nftIDs) as the primary source - the
logs remain valid corroboration.

Coverage is not universal: NFT_DATA accompanies L1-touching events, so an NFT that only
ever lived on L2 has none. For those the collection is genuinely unavailable.

`creatorFeeBips` values seen live: **0, 5 and 10.** It is a plain percentage, never
multiplied. Nothing in any contract or circuit does arithmetic with it - royalty was
enforced entirely off-chain.

## Float encodings

- **Float16** - 5-bit exponent, 11-bit mantissa, base 10: `mantissa * 10^exponent`
- **Float24** - 5-bit exponent, 19-bit mantissa, base 10

Which fields are floats matters: `fee` is always Float16; TRANSFER `amount` and
SPOT_TRADE fills are Float24; DEPOSIT and WITHDRAWAL `amount` are raw uint96. NFT_MINT
`amount` reads as Float16 at offset 22 in the deployed layout.

Evidence the Float24 decode is right: block 67869 slot 2 raw bytes `0x4249f0` read raw
give `4344304` (meaningless); decoded give `15000000000000` = mantissa 150000 x 10^8.
Random bytes do not land on a round mantissa.

## Token decimals - a live accuracy trap

`decode.tsx` hardcodes decimals for token IDs 0-7. The `?? 18` fallback silently
mis-scales everything above ID 7 - a WBTC-style 8-decimal value rendered as 18 is off by
10^10. Amounts are therefore shown as raw base units ("(raw)") rather than formatted,
which is honest but unhelpful.

**There is no decimals registry.** Token IDs map to L1 token addresses through the
exchange's own `TokenRegistered` events, which is where a chain-derived registry would
have to come from. Not built. Until it is, raw base units is the only honest render, and
a hardcoded table beyond ID 7 would be a guess.

## The NFT circuits - where they are, and what they settle (2026-08-09)

Memory previously said `upstream/protocol3-circuits` has no NFT support and left the
impression that no circuit source exists. **The NFT circuits do exist**, at
`upstream/protocols/packages/loopring_v3/circuit/`. `protocol3-circuits` is a pre-NFT
clone and remains useless for this.

`Circuits/NftMintCircuit.h` and the gadget it calls:

```cpp
NftDataGadget: Poseidon_6(minter, nftType, tokenAddress, nftIDLo, nftIDHi, creatorFeeBips)
NUM_BITS_NFT_ID = 256      // split Lo/Hi to fit the field
```

Two things this settles, both load-bearing:

1. **`nftID` is an opaque input.** It enters as 256 bits, gets split, and is hashed into
   the account tree. The circuit never derives it and never validates it against any
   content. **So the circuits cannot answer the metadata format question, and reading
   them further is wasted effort.**
2. **`tokenAddress` is inside the NFT's identity hash.** The collection IS bound to the
   nftID in L2 state - but inside a Poseidon hash in the Merkle tree, not in the 68 bytes
   of data availability. That is the protocol-level mechanism behind the collection being
   unrecoverable from a mint, and behind a live marketplace still needing the user to
   supply the collection address.

## What the protocol does NOT do

Load-bearing for [[project-loopring-recovery]]:

- **`nftID` is opaque.** Read with `toUintUnsafe`, never validated. Live proof it carries
  no fixed meaning: one collection's nftID is `0x00...0042` (the integer 66, a sequence
  number), another's is `0x35899c2b...` (high entropy, hash-shaped). Both valid.
- **Collection contracts are opaque.** `ExchangeNFT.sol` just calls
  `safeTransferFrom` against whatever address is in `token`. The protocol never deploys
  collections and knows nothing of their metadata scheme.
- **No CREATE2 NFT deployment in the protocol.** `Create2` appears only in the library,
  `LoopringAmmFactory` (AMM pools) and `WalletDeploymentLib` (smart wallets).

## Finding submissions

- **Dune:** `loopring_ethereum.loopringioexchangeowner_call_submitblockswithcallbacks`
- **Etherscan:** `module=account&action=txlist&address=0x153CdDD...&sort=desc`, filtered
  to selector `0xdcb2aa31`
- **The archive itself:** `discovered_blocks` maps `blockIdx -> tx_hash` directly, built
  from BlockSubmitted logs. This is the route to a block containing a given transaction
  type, and it needs nothing outside the DB.

## Known anchors

- Final block: `0xf2174245bcae3a1d124bf57b4807dcd03388384b8255fbfcc13379ba1ce2efa6`,
  2026-06-27 01:06:03 UTC. One WITHDRAWAL - ShakePay `0xb0cc7d263f...`, ~0.0855 ETH,
  account 303200.
- NFT-bearing test blocks: L2 **67869** (`0x008e577c...`, 1 mint, 1 deposit, 3 transfers,
  2 withdrawals) and L2 **67164** (`0xb7581ec2...`, 5 mints). Use these to regression-test
  any decoder change.
- 2026-07-03 (approx): operator's last L1 transaction.

## Full-corpus archive (2026-08-03) - THE COMPLETENESS CLAIM WAS FALSE

**CORRECTED 2026-08-09.** The archive described below was **not** the full corpus.
It held blockIdx **57,917 to 67,896** - 9,954 blocks. The real history starts at
blockIdx **1**. Roughly **85% was never collected**, and the "26-block hole"
documented below was a rounding error next to it. The old run started from a late
L1 block instead of searching for the deploy block.

Why it went undetected: per-block `sha256(data) == publicDataHash` verification
proves each block you HAVE is genuine. It cannot detect a block you never
enumerated, because there is nothing there to check. Completeness and correctness
are separate claims and only one was ever tested.

**The fix, now in `scripts/archive.js`:** `BlockSubmitted` emits `blockIdx` as an
indexed topic and they are strictly sequential, so the enumerated set must be
contiguous. Any gap means `eth_getLogs` returned an incomplete answer for a range
and marked it done anyway. The collector now records every blockIdx, re-queries
ranges that fail the invariant, and refuses to fetch on an incomplete enumeration.

Original (over-stated) text follows:

Built a full archive of every block the operator ever submitted, so none of it
depends on any outside index - checked every single one against its own on-chain
signature as it came in.

Found a real hole partway through: twenty-six blocks in a row, just gone. Checked
whether they even existed - they do, still sitting on-chain, no gap in the real
record. Which meant the archive was wrong, not the chain. Walked the actual state
roots across the missing stretch to be sure, and they don't connect - real state
moved through there and none of it got captured. Turned out the free node being
used just wasn't reliable - asked it the same question twice in a row and got two
different answers. Not the collection logic, the provider. Still open - haven't
gone back for the missing pieces yet, and want to actually nail down why the node
did that before trusting it again.

## Related

- [[project-loopring-recovery]] - what decoded data can and cannot tell you about NFT
  metadata addressing.
- [[project-loopring-revival]] - the explorer this decoder lives in.
- [[feedback-decode-first]] - the rule this file's biggest error violated.
