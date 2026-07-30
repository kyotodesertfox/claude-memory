---
name: project-loopring-calldata
description: "How to decode Loopring v3 block calldata from L1 - tools, block format, byte layouts, key addresses, investigation findings, and decoder tool status"
metadata: 
  node_type: memory
  type: project
  modified: 2026-07-25T01:34:14.619Z
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
---

# Loopring L1 Calldata Investigation

**Why:** Loopring v3 zkRollup shut down June 27, 2026. Insider withdrawals in final blocks suspected. All proof data is permanently on Ethereum L1 and decodable. Goal: surface who withdrew what before the exchange went dark.

## Key Addresses

- **Exchange operator wallet (sole block submitter):** `0x487e8Be2BaD383b5B62fC5fb46005A8Fac10E341`
- **Loopring Attestation contract:** `0x153CdDD727e407Cb951f728F24bEB9A5FaaA8512`
- **Operator's final ETH transfer recipient:** `0x88f8Dbd3dC44c6E2e368258D3eee8EB9A07aF191` (holds Taiko tokens)

## Timeline

- **June 26, 2026:** Final blocks submitted including 600 USDT + 300 USDC withdrawals settled to L1
- **June 27, 2026 01:06:03 UTC:** Last `submitBlocksWithCallbacks` call - confirmed final block. One WITHDRAWAL: ShakePay address `0xb0cc7d263f1ba4c79226174ef1dfcc1a19105dc0`, ~0.0855 ETH, Account ID 303200.
- **July 3, 2026 (approx):** Operator's last ETH transaction on L1

## The Decoder Tool

Live at `/decode` in the loopring-explorer repo (`lonewolf-loopring/loopring-explorer`, branch `main`).

**What it does:**
- Paste any `submitBlocksWithCallbacks` tx hash → decodes all block headers and transactions
- Block finder card: pick a date range on a calendar → queries Etherscan txlist for matching submissions → click a result to auto-decode it
- June 27, 2026 is ringed on the calendar as a reference anchor (last known block)

**Confirmed working transaction:** `0xf2174245bcae3a1d124bf57b4807dcd03388384b8255fbfcc13379ba1ce2efa6` (final block)

## Two-Level ABI Decode Required

Level 1: strip 4-byte selector, decode `(bool isDataCompressed, bytes blockData, bytes callbackData)`  
Level 2: `blockData` starts with 4-byte inner prefix `0x53228430` (skip it), then ABI-decode as `Block[]` struct

```
BLOCK_STRUCT_TYPE = 'tuple(uint8 blockType, uint16 blockSize, uint8 blockVersion, bytes data, uint256[8] proof, bool storeDataHashOnchain, bytes auxiliaryData, bytes offchainData)[]'
```

`Block.data` = raw bytes. `Block.blockSize` = number of transactions (NOT in block data - from struct).

## Split Transaction Layout (v3.6 universal blocks)

NOT sequential. After the 98-byte header:
```
[98B header] [blockSize × 29B part1] [blockSize × 39B part2]
```
Transaction i = `part1[i] (29B)` + `part2[i] (39B)` = 68 bytes total. PART1=29, PART2=39 for ALL transaction types.

## Block Header (98 bytes)

| Offset | Size | Field |
|--------|------|-------|
| 0 | 20 | exchange address |
| 20 | 32 | merkleRootBefore |
| 52 | 32 | merkleRootAfter |
| 84 | 4 | timestamp (unix) |
| 88 | 1 | protocolFeeTakerBips |
| 89 | 1 | protocolFeeMakerBips |
| 90 | 4 | numConditionalTransactions |
| 94 | 4 | operatorAccountID |

## Transaction Byte Layouts (within 68-byte txBuf)

**WITHDRAWAL (typeId=2):**
| 0 | 1 | type |
| 1 | 1 | withdrawalType |
| 2 | 20 | from address |
| 22 | 4 | fromAccountID |
| 26 | 2 | tokenID |
| 28 | 12 | amount (raw uint96) |
| 40 | 2 | feeTokenID |
| 42 | 2 | fee (Float16) |
| 44 | 4 | storageID |
| 48 | 20 | onchainDataHash |

`to` address is in auxiliary data, not inline.

**TRANSFER (typeId=3):**
| 0 | 1 | type |
| 1 | 1 | transferType |
| 2 | 4 | fromAccountID |
| 6 | 4 | toAccountID |
| 10 | 2 | tokenID |
| 12 | 3 | amount (Float24) |
| 15 | 2 | feeTokenID |
| 17 | 2 | fee (Float16) |
| 19 | 4 | storageID |
| 23 | 20 | to address (ZERO for L2-only transfers) |
| 43 | 20 | from address (ZERO for L2-only transfers) |

**Note:** `to`/`from` are zero for regular L2-L2 transfers - addresses live in the off-chain Merkle tree. Only account IDs are meaningful on-chain.

**SPOT_TRADE (typeId=4):** accountIdA at 9, accountIdB at 13, fills as Float24
**ACCOUNT_UPDATE (typeId=5):** owner at 2, accountID at 22, fee at 28 (Float16), publicKey at 30 (32B), nonce at 62

## Float Encodings

- **Float16:** 5-bit exponent + 11-bit mantissa, base 10. `mantissa * 10^exponent`
- **Float24:** 5-bit exponent + 19-bit mantissa, base 10. Same formula.

## Finding the Data

**Dune Analytics** has Loopring fully indexed:
- Table: `loopring_ethereum.loopringioexchangeowner_call_submitblockswithcallbacks`
- Query: `SELECT call_block_time, call_tx_hash FROM ... ORDER BY call_block_time DESC LIMIT 1000`

**Etherscan txlist:** `module=account&action=txlist&address=0x153CdDD...&sort=desc` - filter for selector `0xdcb2aa31`

## Investigation Context

- Daniel Wang (founder) went silent
- Byron (third known team member) pivoted to Base/Coinbase ecosystem
- LooperLands confirmed "anything centralized can be shut down" - had foreknowledge
- Justin refused KYC from LooperLands before shutdown; his L2 assets are stranded
- The "hack" narrative may be cover for a controlled shutdown / acquisition
- ShakePay withdrawal in final block raises questions about who had advance notice

**How to apply:** Use the `/decode` page to investigate. Start from the confirmed final tx hash above, or use the calendar block finder to pull other submissions from June 26-27.
