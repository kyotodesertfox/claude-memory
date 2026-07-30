---
name: project-loopring-revival
description: "Loopring explorer revival under lonewolf-loopring GitHub identity - what's live, what's dead, and restore paths"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
  modified: 2026-07-28T23:49:43.768Z
---

## Overview

Reviving the Loopring block explorer as a read-only historical viewer under the `lonewolf-loopring` GitHub identity. Completely separate from Homestead - different GitHub account, different SSH key, different identity. Does not touch the Homestead repo in any capacity.

**Why:** Loopring's L2 data is permanently preserved on Ethereum L1 as calldata. Servers are gone but the data is final. Motivation: "maybe I'm trying to show Daniel a painting."

**Why:** [[project-homestead-mission]] is separate - this is its own thing.

## Repo

- GitHub: `lonewolf-loopring/loopring-explorer` (forked from `Loopring/loopring-explorer`)
- Local: `/home/zenko/github/loopring/loopring-explorer`
- SSH identity: `~/.ssh/lonewolf-loopring` (config entry: `Host lonewolf-loopring`)
- Deployment target: Netlify

## Secrets

- Graph API key: `~/github/graph.txt` and in `.env.local`
- lonewolf-loopring GitHub PAT: `~/github/PAT.txt` and in `.env.local`
- `.env.local` is gitignored

## What's Live

- **The Graph subgraph** - Loopring zkRollup on Ethereum mainnet
  - Subgraph ID: `8Z15oyPLRCYzVdNbjKSU2iD8BE6Sj8PZRV4KddDuvuk2`
  - Auth: `Authorization: Bearer {API_KEY}` header (NOT `X-API-KEY`)
  - API key is 32-character hex
- **Ethereum L1 calldata** via Infura/ZAN endpoint (block parser reads raw L2 tx data)

## What's Dead

The Loopring REST API (`api3.loopring.io`) is completely offline - no amount of API keys brings it back. The following are stubbed to fail gracefully:

| Hook/util | Dead endpoint | Current behavior | Restore path |
|---|---|---|---|
| `utils/transaction.ts` getBlock/getAccount/getTokens/getPools | `block/getBlock`, `account`, `exchange/tokens`, `amm/pools` | `useTransaction` shows failed state on tx detail pages | Point at live API or equivalent Graph queries |
| `hooks/useTokens.ts` | `exchange/tokens` | Returns `[]`; Graph token data covers all list views | Live API or Graph `Token` entity query |
| `hooks/useTokenPrices.ts` | `datacenter/getLatestTokenPrices` | USD value row hidden in account view | Replace with CoinGecko/oracle |
| `hooks/usePendingTransactionData.ts` | `user/transactions` etc. | Returns null immediately | Requires live operator stack, not just API |
| `pages/collections/[address].tsx` | `nft/public/collection` | Silently returns `{}`, no collection name/avatar shown | Live API or IPFS metadata fallback |

**Trading cannot be restarted on Loopring's contracts** - but see "Self-Sovereign Operator" section below for own deployment.

## What Was Changed

### `pages/api/graphql.ts` (new)
Server-side proxy to The Graph gateway. Keeps the API key out of the client bundle. All Apollo GraphQL queries route through `/api/graphql` which forwards to The Graph with `Authorization: Bearer` header.

### `utils/config.ts`
- `LOOPRING_SUBGRAPH` now points to `/api/graphql` (the local proxy) instead of the dead `dev.loopring.io/api/v3/forwardRequest`
- `NEXT_PUBLIC_SUBGRAPH_ENDPOINT` env var removed (key must not be client-side)
- Note added that `LOOPRING_API` and related exports are dead

### `graphql/index.ts`
Removed the `mapBody` ApolloLink unwrap shim. The old Loopring proxy double-wrapped responses (JSON string inside JSON), requiring `JSON.parse(response.data).data`. The Graph returns standard GraphQL JSON - no unwrapping needed.

## Key Community Actors

| Handle | Wallet | Role |
|---|---|---|
| Autodestructive | `0xC7Eaf32B4141FC4a0984A501D41Da6F06Be13bB6` | Ran secondary NFT marketplace outside GSMP; built LoopringRescueRegistry contract (Merkle-gated ERC-1155 claim for snapshot holders); exit-liquidity focused |

## Priority Status (2026-07-14)

The explorer revival is live and valid. The self-sovereign operator work (ZK prover, Sepolia deployment) has been deprioritized - Justin's assessment: "fun and experimentation, not appropriate for what I actually need." Not abandoned, just not the active thread. Resume only if Justin explicitly says to continue.

## Self-Sovereign Operator (Sepolia Testnet)

Running own Loopring instance under lonewolf-loopring identity. Goal: submit ZK proofs on-chain, eventually on mainnet.

### ZK Prover
- Binary: `/home/zenko/github/loopring/protocols/packages/loopring_v3/build/circuit/dex_circuit`
- Keys (blockSize=8): `/home/zenko/github/loopring/protocols/packages/loopring_v3/keys/`
  - `all_8_pk.raw` (~1.1GB proving key)
  - `all_8_vk.json` (1.4KB verification key)
- Required rewriting `circuit/main.cpp` to replace deleted Loopring ethsnarks `opt` branch with standard `stub_prove_from_pb`
- Circuit: 1,258,544 constraints, 157K/tx, blockSize=8

### Sepolia Contract Deployment
- Deployer: `0x202ECf228020b79bd1BFCE7457C15A9831BCe4D3`
- Compiler: solidity 0.7.6, optimizer 200 runs

| Contract | Address |
|---|---|
| BlockVerifier | `0xb266E3307C17681df9C63b8A60be31b53f8CE239` |
| LoopringV3 | `0xEeBA2b24bc999c9EAf90D56d65E7b399B786a8aA` |
| ExchangeV3 (impl) | `0xb845A4C51c588c6f52dccE542822CEEa435140EF` |
| SimpleProxy (ExchangeV3 proxy) | `0xa78487e53E38851025228e10F56C5cccc7DDb5a4` |
| DefaultDepositContract | `0xE59E84bf5b7FE2604be358489152d48DBa165BB4` |

**Next steps after all 5 deployed:**
1. Register vk.json in BlockVerifier
2. Initialize ExchangeV3 proxy via LoopringV3
3. Set DefaultDepositContract on exchange
4. Register as operator
5. Generate valid block data and submit proof

## Main List Views

Blocks, transactions, pairs, NFTs, accounts - all run through Apollo/The Graph and should work. Individual transaction detail pages (`tx/[id]`) are broken because they depend on L1 calldata parsing + dead REST API enrichment.
