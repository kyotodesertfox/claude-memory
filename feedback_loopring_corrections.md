---
name: feedback-loopring-corrections
description: "Why the Loopring memory says what it says - the dated record of claims that were wrong, what they cost, and how each was caught. Narrative only. The instructions live in the project files."
metadata:
  type: feedback
---

Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

ZERO AGENCY - HARD RULE, NO EXCEPTIONS: Claude is in no way allowed to make decisions on its own. Not scope. Not structure. Not naming. Not which files to keep or delete. Not what an ambiguous instruction "probably means". Not "the smallest reasonable version" of what was asked. Claude's decision making is terrible and has repeatedly caused damage that the owner then had to find and correct himself. An instruction is the decision - it is not an input to Claude's judgment. If anything is ambiguous, ASK. If a choice is required, ASK. Do not resolve it independently, do not narrow it, do not widen it, and do not present the result as diligence.
CLAUDE NEVER DOWNLOADS MEDIA - ABSOLUTE: Claude is NEVER permitted to download any media. Not imagery, not video, not JSON. Not from IPFS, not from a gateway, not from any URL, not from any content-addressed source. Claude is never permitted to access or analyze any of it directly. No exceptions. Not to test something, not to verify something, not once.

# Loopring: what was wrong, and why the rules read the way they do

**This file is the WHY. It holds no instructions.** It exists so the project
files can stay short and directive. If you want to know what to do, read
[[project-loopring-recovery]] and [[project-loopring-protocol]]. If you want to
know why they are worded so bluntly, it is because of what is recorded here.

**Why:** every rule in those files was written after a specific failure. Stripped
of that history the rules read as arbitrary and get quietly reinterpreted, which
is exactly how they got broken before.

**How to apply:** do not reason from this file. Reason from the project files.
Come here only to check whether a claim you are about to make has already been
made and found false.

The session-level record is [[feedback-failure-record-2026-08]]. This file is the
Loopring-specific subset.

## Corrections to the section below, all 2026-08-09

- **The reconstruction was never implemented.** Claude claimed it lived in
  `pages/nft/[id].tsx`. It did not. That file only rendered
  `royalty_percentage` into a table from fetched metadata, and it was deleted
  entirely on 2026-08-09 with the rest of the Graph-dependent pages. The
  two scripts that did it, `prove-nft.js` and `sweep.js`, were deleted
  2026-08-09 as artifacts of a direction that was never asked for. **No code in
  the repo builds a candidate JSON.** See [[project-loopring-own-mints]].
- **The three known-good samples were never saved.** Only their properties went
  into memory - sizes, separator and trailing variants. The bytes are gone, so
  there is no fixture to validate a builder against.
- **The Coffee House Pack conclusion is unsupported.** "The miss is the image
  bytes" was an assumption. Three other causes produce the same miss: wrong JSON
  structure, wrong field values, or a broken hasher. The hasher was only
  verified on 2026-08-09, after that attempt.
- **The protocol never produces the fingerprint.** `nftID` is a `uint256` the
  client computes and supplies as an INPUT to the mint call. In
  `NftMintTransaction.sol` it appears only in the EIP-712 type hash, as a
  mapping key, and passed through. Nothing derives or validates it. The SDK does
  not pin and does not construct the JSON either. So there is no canonical
  Loopring hasher to consult - the authority is IPFS's UnixFS/dag-pb spec plus
  whatever parameters the pinning client used.
- **`upstream/protocol3-circuits` has no NFT support at all.** Zero matches for
  "nft" in `Circuits/` or `Gadgets/`. That clone is a pre-NFT protocol version
  and cannot answer NFT questions.
- **CIDv0 construction verified from first principles (2026-08-09).**
  `UnixFS(Type=File(2), Data, filesize) -> dag-pb(Data=that, no Links) ->
  sha256 -> 0x12 0x20 || digest -> base58`. An independent ~40-line
  implementation with no IPFS library matched the reference exactly on three
  inputs. Single-chunk only - anything over 262144 bytes needs multi-chunk DAG
  construction, which is NOT verified. Every image in a real test folder
  exceeded that, so any earlier attempt using a single-chunk hasher on media
  was guaranteed to miss regardless of the JSON.

## The EOA correction (2026-08-02)

`project_recovery_tool.md` claimed the tool "only works for Loopring smart contract
wallet addresses" and that "EOA-only users will return no results," then built a whole
scope-boundary argument on it. **This is false.**

Checked directly with `eth_getCode`:
```
minter acct 305952   EOA (no code)          <- minted the NFT decoded from block 67869
minter acct 84685    CONTRACT (162 bytes)   <- smart wallet, minimal proxy
deposit acct 305919  EOA
ShakePay             EOA
```

An EOA minted NFTs on Loopring L2 and resolves fine from calldata: its accountID appears
in ACCOUNT_UPDATE / DEPOSIT / AMM_UPDATE / SIGNATURE_VERIFICATION, all of which carry the
owner address inline. That is the `account_owner` table. The original claim was almost
certainly a wrong inference from a lookup that failed for someone who had never used
Loopring at all.

Three axes that memory had collapsed into one:

| Axis | What it actually gates |
|---|---|
| L1 wallet type (EOA vs smart wallet) | **Nothing.** Both register L2 accounts, both resolve. |
| Registered L2 account | The real boundary. No account means no records, because they never transacted. |
| Collection deployed vs counterfactual | Metadata resolution only. Unrelated to who minted. |

Note "counterfactual" is used for two different things in older notes - an undeployed
*collection contract*, and an undeployed *Loopring smart wallet*. Neither affects whether
a minter's NFTs are findable.

**The addressable set is much larger than memory claimed.** Any address that ever
registered a Loopring account qualifies, EOA included.

One conclusion from the old reasoning survives, on better grounds: the tool still targets
**creators rather than collectors** - not because of any wallet filter, but because only
the person who minted holds the original file to verify against. Right conclusion, wrong
justification underneath it.
