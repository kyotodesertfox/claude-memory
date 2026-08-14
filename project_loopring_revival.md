---
name: project-loopring-revival
description: "Loopring explorer revival under lonewolf-loopring GitHub identity - what's live, what's dead, and restore paths"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
  modified: 2026-08-14T20:58:31.461Z
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.
CLAUDE NEVER DOWNLOADS MEDIA - ABSOLUTE: Claude is NEVER permitted to download any media. Not imagery, not video, not JSON. Not from IPFS, not from a gateway, not from any URL, not from any content-addressed source. Claude is never permitted to access or analyze any of it directly. No exceptions. Not to test something, not to verify something, not once.

## Overview

Reviving the Loopring block explorer as a read-only historical viewer under the `lonewolf-loopring` GitHub identity. Completely separate from Homestead - different GitHub account, different SSH key, different identity. Does not touch the Homestead repo in any capacity.

**Why:** Loopring's L2 data is permanently preserved on Ethereum L1 as calldata. Servers are gone but the data is final. Motivation: "maybe I'm trying to show Daniel a painting."

**Why:** [[project-homestead-mission]] is separate - this is its own thing.

**Identity note:** the Loopring memory files living in the kyotodesertfox repo, and the shared deploy wallet, are a DELIBERATE overlap. Do not clean it up - see the section in `IDENTITIES.md`.

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

**HARD RULE: for anything WE build, L1 calldata is the only source of truth.** Not for NFTs, accounts, blocks, or "just this one lookup." No outside index is queried, ever, as an input. See the banner at the top of this file, the rule in `~/.claude/CLAUDE.md`, and the reason in [[feedback-failure-record-2026-08]].

### The one exclusion, and why it is one (2026-08-09)

**Loopring's own core-team explorer runs as they shipped it, subgraph and all.**

The line is AUTHORSHIP, not convenience. That code is theirs. Preserving it means
preserving how it worked, and rewriting their pages onto a different data source would be
altering their work, not restoring it. The owner's phrasing: acceptable proximity.

Covered by the exclusion - all core-team authored:
`pages/index.tsx` (landing), `/blocks`, `/transactions`, `/pairs`, `/search`, and the
`block/[id]`, `tx/[id]`, `account/[id]`, `pair/[id]`, `nft/[id]`, `collections/[address]`
detail pages, plus `generated/`, `graphql/`, `codegen.yml`, `pages/api/graphql.ts`,
`components/USDPriceValue.tsx`, `hooks/useTokenUSDPrice.ts` and the Apollo deps.

NOT covered, rule stands FIRM - everything we wrote:
`pages/decode/index.tsx` (hub), `pages/decode/l1.tsx`, `pages/decode/nft.tsx`,
`pages/decode/help.tsx`, `pages/ipfs.tsx`, every route under `pages/api/` except
`graphql.ts`, and all of `scripts/`.

**How this came about, so it is not mistaken for drift:** the removal was ordered without
knowing the subgraph powered the core team's landing page. On finding that out the owner
drew this line deliberately. It is the only exclusion. Adding a second one is not a
judgement call available to a future session.

The note lives in code too, directly above the two exports in `utils/config.ts`.

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
| `pages/collections/[address].tsx` | `nft/public/collection` | restored; silently returns `{}`, no collection name/avatar | A collection has no on-chain name: `name()`/`symbol()` are unimplemented and `contractURI()` points at the dead `nftinfos.loopring.io`. Identify it by the NFTs inside it. |

**Trading cannot be restarted on Loopring's contracts** - but see "Self-Sovereign Operator" section below for own deployment.

## What Was Changed

### Current state of the tree (2026-08-09, after the restore)

The Graph was removed, then partially restored by owner decision. See the exclusion above.

```
/                     core team landing page          subgraph  (excluded)
/blocks /transactions /pairs /search                  subgraph  (excluded)
/block/[id] /tx/[id] /account/[id] /pair/[id]
/nft/[id] /collections/[address]                      subgraph  (excluded)

/decode                hub, the single "Decoder" nav entry       calldata only
/decode/l1             block decoder (was /decode)               calldata only
/decode/nft            NFT decoder, disabled on the hub          calldata only
/decode/help           methodology                               calldata only
/ipfs                  routable, unlinked                        calldata only
```

Nav: the two entries (L1 Decode, NFT Decoder) collapsed into one, "Decoder", pointing at
the hub. The NFT decoder card on the hub is disabled with a COMING SOON badge while it is
built out, and the IPFS resolver card was removed from the hub since it is part of the NFT
decoder flow.

**`/decode` used to be the block decoder.** It is now the hub, and the decoder is at
`/decode/l1`. Old links land on the hub, one click away, not a 404. Two things moved with
it that would otherwise have broken silently: the methodology page's back-link, and the
Netlify contact form on the decoder, which POSTs to its own path.

`/decoder` and `/decode` differ by one character and both resolve, so a wrong link will
not 404 visibly.

### API routes
```
pages/api/graphql.ts        subgraph proxy - EXCLUDED, core team pages only
pages/api/calldata-nft.ts   address -> accountID -> mints, from the archive
pages/api/nft-metadata.ts   uri(nftID) when a collection is known, else CIDv0(nftID)
pages/api/cid.ts            UnixFS/dag-pb CIDv0 of raw bytes (ipfs-only-hash)
pages/api/ipfs-check.ts     gateway availability race
pages/api/eth-call.ts       raw L1 eth_call passthrough
pages/api/hello.js          Next.js scaffold leftover
```
There is no `/api/probe` and no `/api/pin`. The NFT page called both for weeks; both were
404s, and the callers were deleted 2026-08-09. `/api/ipfs-resolve.ts` is also gone.

## Key Community Actors

| Handle | Wallet | Role |
|---|---|---|
| Autodestructive | `0xC7Eaf32B4141FC4a0984A501D41Da6F06Be13bB6` | Ran secondary NFT marketplace outside GSMP; built LoopringRescueRegistry contract (Merkle-gated ERC-1155 claim for snapshot holders); exit-liquidity focused |

## Priority Status (2026-07-14)

The explorer revival is live and valid. The self-sovereign operator work (ZK prover, Sepolia deployment) has been deprioritized - Justin's assessment: "fun and experimentation, not appropriate for what I actually need." Not abandoned, just not the active thread. Resume only if Justin explicitly says to continue.

## Branch Structure (2026-08-14 restructuring)

`main` was reset to a clean base: the original Loopring fork + the L1 Decode
block-calldata page only. Everything built since (NFT Decoder, How It Works,
DAO Proposals) had accumulated as sequential commits directly merged into
main with no branch discipline - not specified at the time, should have been.
This pass retroactively separated them into independent sibling feature
branches, each branching directly off `main`:

- `feature/how-it-works` - methodology page + DATA-ACCESS attribution rewrite
- `feature/nft-decoder` - the NFT decoder
  - `feature/ipfs-work` - server-side IPFS removal, card polish, slot-allocation
    probes; sits ON TOP of nft-decoder (a continuation, not a sibling)
- `feature/dao-proposals` - Loopring DAO governance archive, **merged into
  main and pushed 2026-08-14** - see [[project-loopring-snapshot-provenance]]

**Why rebase was used here, once, deliberately - not the general rule:**
the DATA-ACCESS attribution commits sat directly on main's own line, with no
branch of their own, tangled in with how-it-works' actual page commits by
proximity rather than by relationship. Untangling that meant reassembling
which commits belonged to which never-built feature branch and giving them
one - which is fundamentally a construction problem, not a sync problem.
Merge preserves two histories that already both exist and just brings them
together; there was no second branch here to preserve, only a pile of
main-line commits that needed sorting into branches that were never made.
Rebase was the tool that could build that structure after the fact.

Ongoing sync between branches - keeping a feature branch current with main,
or vice versa - should default to merge from here on, per the
transparency-over-rewriting reasoning above. The rebase was a one-time
corrective act to impose the structure that should have existed from the
start, not a standing preference.

`how-it-works` and `nft-decoder` are NOT yet merged into main - still local
feature work. `main` itself needed a force-push to `origin` once this reset
diverged it from the old pushed history (safe here: solo repo, no other
collaborators, and the DATA-ACCESS commits that would otherwise have been
stranded were pushed to `feature/how-it-works` first, before main's
force-push, specifically to avoid a window where they had no pushed home).

**Confirmed 2026-08-14, later in the same session:** discipline held even
after the structural work landed - a small copy-only tweak to
`pages/proposals.tsx` was caught mid-edit as having been made directly on
`main` instead of `feature/dao-proposals`, moved back onto the feature
branch via stash, committed there, then merged forward. Owner's explicit
approval: "thank you for that discipline, that is important." Keep doing
this for *follow-up* edits to an already-merged feature, not just the
initial build - relaxing once the big work lands is exactly where
discipline erodes.

**Route tree below this point predates the restructuring and needs
re-verification against the current how-it-works/nft-decoder branch state
before trusting it.**

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

## Main List Views

Blocks, transactions, pairs, NFTs and accounts run through Apollo and the subgraph, as the
core team built them, and they work. That is the exclusion, not a violation.

They could be rebuilt against the archive - `blocks`, `l1_txs` and `l1_logs` hold what
those pages show - but there is no reason to. Rewriting their code onto a different source
is not restoration.
