Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

---
name: project-loopring-revival
description: "Loopring explorer revival under lonewolf-loopring GitHub identity - what's live, what's dead, and restore paths"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
  modified: 2026-08-09T16:54:45.938Z
---

## Overview

Reviving the Loopring block explorer as a read-only historical viewer under the `lonewolf-loopring` GitHub identity. Completely separate from Homestead - different GitHub account, different SSH key, different identity. Does not touch the Homestead repo in any capacity.

**Why:** Loopring's L2 data is permanently preserved on Ethereum L1 as calldata. Servers are gone but the data is final. Motivation: "maybe I'm trying to show Daniel a painting."

**Why:** [[project-homestead-mission]] is separate - this is its own thing.

## Repo

- GitHub: `lonewolf-loopring/loopring-explorer` (forked from `Loopring/loopring-explorer`)
- Local: `/home/zenko/github/lonewolf-loopring/loopring-explorer`
- **Also cloned 2026-08-03: `lonewolf-loopring/loopring_sdk`** at
  `~/github/lonewolf-loopring/loopring_sdk` (fork of `mobiledev-111-118/loopring_sdk`).
  This is the client SDK and it answered the nftID/CID addressing question that contracts
  could not - see [[project-loopring-recovery]]. Consult it before inferring any
  client-side behaviour.
- SSH identity: `~/.ssh/lonewolf-loopring` (config entry: `Host lonewolf-loopring`)
- Deployment target: Netlify

## Secrets

Single source of truth is `loopring-explorer/.env.local` (gitignored). Keys defined there: `GITHUB_PAT` (lonewolf-loopring), `NEXT_PUBLIC_ETHERSCAN_API_KEY`, `PINATA_API`, `PINATA_API_SECRET`, `PINATA_JWT`.

`GRAPH_API_KEY` was listed here. Nothing reads it any more. **Delete that line from `.env.local`** - an unused key for a source that must never be queried is a loaded gun sitting on the table.

Loose plaintext copies at `~/github/graph.txt` and `~/github/PAT.txt` were deleted 2026-08-02 - both were byte-identical duplicates of values already in `.env.local`, and nothing referenced them by name. Do not recreate them; read from `.env.local`.

## What's Live

**HARD RULE as of 2026-08-09: L1 calldata is the only source of truth.** Not for NFTs, accounts, blocks, or "just this one lookup." No outside index is queried, ever, for anything - not as an input, not as a shortcut, not "just to check." See the banner at the top of this file, the rule in `~/.claude/CLAUDE.md`, and the reason in [[feedback-failure-record-2026-08]].

The indexed data layer was removed from the codebase entirely on 2026-08-09. No endpoint, ID, key or query shape is recorded anywhere in memory, deliberately. **If a future session finds itself wanting them, that is the failure recurring, and the correct response is to stop and say the field is unavailable.**

- **Ethereum L1 calldata** - the source. Everything resolves from it.
  - Live RPC for the decode page: ZAN endpoint hardcoded in `utils/config.ts`. It is `NEXT_PUBLIC_`, so it ships in the browser bundle regardless and is origin-locked at the provider, which is why scripts cannot use it.
  - Bulk collection: `scripts/archive.js`, public endpoints, self-verifying. `eth.drpc.org` serves archive `eth_getLogs` at 10k ranges - it failed once transiently and a whole false thesis got built on that single unretried request.
- **The local archive** - `~/github/lonewolf-loopring/loopring-archive/loopring-archive.db`. Once built, the RPC access layer stops being a dependency at all.

## What's Dead

The Loopring REST API (`api3.loopring.io`) is completely offline - no amount of API keys brings it back. The following are stubbed to fail gracefully:

| Hook/util | Dead endpoint | Current behavior | Restore path |
|---|---|---|---|
| `utils/transaction.ts` getBlock/getAccount/getTokens/getPools | `block/getBlock`, `account`, `exchange/tokens`, `amm/pools` | unreferenced; the tx detail pages that used it are deleted | Rebuild against the archive |
| `hooks/useTokens.ts` | `exchange/tokens` | Returns `[]` | Derive the token registry from the exchange's `TokenRegistered` logs |
| `hooks/useTokenPrices.ts` | `datacenter/getLatestTokenPrices` | USD value row hidden in account view | Replace with CoinGecko/oracle |
| `hooks/usePendingTransactionData.ts` | `user/transactions` etc. | Returns null immediately | Requires live operator stack, not just API |
| `pages/collections/[address].tsx` | `nft/public/collection` | **file deleted 2026-08-09** | A collection has no on-chain name: `name()`/`symbol()` are unimplemented and `contractURI()` points at the dead `nftinfos.loopring.io`. Identify it by the NFTs inside it. |

**Trading cannot be restarted on Loopring's contracts** - but see "Self-Sovereign Operator" section below for own deployment.

## What Was Changed

### The Graph is fully gone (2026-08-09)
Earlier versions of this section documented `pages/api/graphql.ts`, `utils/config.ts`
pointing `LOOPRING_SUBGRAPH` at that proxy, and a `graphql/index.ts` ApolloLink shim.
**None of those files exist.** `generated/` and `graphql/` were deleted, and the 34 source
files that imported them were deleted with them - 10 pages, 15 Graph-importing components
and hooks, and 9 more that broke through those. `package-lock.json` was pruned of 51
Apollo and GraphQL entries so a fresh install cannot pull them back.

### Surviving pages, exhaustive
```
pages/index.tsx        landing page, static, links the tools below
pages/decode.tsx       L1 block decoder
pages/decode/nft.tsx   NFT decoder, archive-backed
pages/decode/help.tsx  methodology
pages/ipfs.tsx         nftID <-> CIDv0 resolver
pages/_app.tsx  pages/_document.tsx
```
`index.tsx` was three Graph-backed list views (latest blocks, transactions, pairs) and is
now a static landing page. The nav search box was removed with it: it routed to `/search`,
which needed `hooks/useSearch.ts`, which was a subgraph query. A calldata-backed search is
buildable against the archive and is not built.

### Surviving API routes, exhaustive
```
pages/api/calldata-nft.ts   address -> accountID -> mints, from the archive
pages/api/nft-metadata.ts   uri(nftID) when a collection is known, else CIDv0(nftID)
pages/api/cid.ts            UnixFS/dag-pb CIDv0 of raw bytes (ipfs-only-hash)
pages/api/ipfs-check.ts     gateway availability race
pages/api/eth-call.ts       raw L1 eth_call passthrough
pages/api/hello.js          Next.js scaffold leftover
```
There is no `/api/probe` and no `/api/pin`. The NFT page called both for weeks; both were
404s. Callers deleted 2026-08-09.

### Kept deliberately, currently unreferenced
`components/table/`, the `transactionDetail/` renderers, `TabbedView`, `FallBackImg`, and
utils like `clipboard.ts` and `getTokenAmount.ts`. None import The Graph; they were only
orphaned because the pages using them are gone. They are the starting material if the
block/tx/account views get rebuilt against the archive.

## Key Community Actors

| Handle | Wallet | Role |
|---|---|---|
| Autodestructive | `0xC7Eaf32B4141FC4a0984A501D41Da6F06Be13bB6` | Ran secondary NFT marketplace outside GSMP; built LoopringRescueRegistry contract (Merkle-gated ERC-1155 claim for snapshot holders); exit-liquidity focused |

## Priority Status (2026-07-14)

The explorer revival is live and valid. The self-sovereign operator work (ZK prover, Sepolia deployment) has been deprioritized - Justin's assessment: "fun and experimentation, not appropriate for what I actually need." Not abandoned, just not the active thread. Resume only if Justin explicitly says to continue.

## Self-Sovereign Operator (Sepolia Testnet)

Running own Loopring instance under lonewolf-loopring identity. Goal: submit ZK proofs on-chain, eventually on mainnet.

### ZK Prover
- Binary: `/home/zenko/github/lonewolf-loopring/loopring-explorer/upstream/protocols/packages/loopring_v3/build/circuit/dex_circuit`
- Keys (blockSize=8): `/home/zenko/github/lonewolf-loopring/loopring-explorer/upstream/protocols/packages/loopring_v3/keys/`
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

## Main List Views - DELETED 2026-08-09

This section used to say blocks, transactions, pairs, NFTs and accounts "should work".
They no longer exist. Every one of those pages was deleted along with the indexed data
layer they read from. The only list view in the app is the NFT decoder's, which reads the
archive.

Rebuilding them is tractable: `blocks`, `l1_txs` and `l1_logs` in the archive hold
everything those pages showed. Nothing about that work requires an outside index.
