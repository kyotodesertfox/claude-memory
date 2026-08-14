# Memory Index

Rules, behavioral guidelines, and user profile are in `~/.claude/CLAUDE.md` (always loaded).
These files are project/reference context — read when the relevant topic comes up.

**Before writing any memory:** re-read this file first. Navigate the tree to find the right existing file and update it. Only create a new file if the topic genuinely has no home here.

All sessions launch from `~/github`, so this is the single memory store — there are no other per-directory stores to check.

## Homestead

- [Project](project.md) — Homestead: beer DEX, farm ecosystem, philosophy, repo map, pending UI features
- [Contracts](project_contracts.md) — contract architecture, storage layouts, deployed addresses (mainnet 167000), upgrade status; **live wiring probed 2026-08-06: ownership split (only Treasury transferred), Relay not registered to Marketplace = silent attestation gap, several deployed impls behind source**; admin Wiring Map tab
- [NFT Beacon Architecture](project_nft_beacon.md) — implemented two-track NFTDeployer + UpgradeableBeacon architecture, storage layout, deploy sequencing; addendum folds in tier-system split + deploy-line pattern from an earlier superseded draft
- [Relay Key Derivation](project_relay_keygen.md) — HomesteadChat key derivation design, why one prompt is correct
- [Governance](project_governance.md) — Tier 4 DAO design: anti-whale, solo vs accelerated paths, slash mechanism
- [Companion Messaging](project_companion_messaging.md) — companion app copy and "why": direct farm sales, NFT as claim ticket
- [Companion UI Standard](project_companion_ui_standard.md) — companion UI: colors, header, cards, tab bar specs
- [Companion Status](project_companion_status.md) — companion build status: what's done, what's pending
- [SEX Marketplace](project_sex_marketplace.md) — adult services marketplace: design, contracts, flows, deployment notes
- [Mission](project_homestead_mission.md) — core value proposition: costly gifting = provable conviction; on-chain reputation derived from behavior under real stakes; mission statement draft
- [Unit Scaling](project_unit_scaling.md) — indivisible good (NFT) vs divisible money (token); 1:1 enforced at four ops via % 1e18, not decimals; control model + Release 1 refactor
- [Homestead Mini](project_homestead_mini.md) — local barter exchange landing site; Astro+Tailwind; OAuth admin, 3 Netlify forms, procurement link previews, $EGG tooltip
- [Netlify Functions](feedback_netlify_functions.md) — must pin NODE_VERSION=22 in netlify.toml for native fetch; always wrap in try/catch
- [Language](feedback_language.md) — word choice rules: "producer" not "worker"; single dashes only; platform fees are real, never say the platform takes nothing

## Loopring / loopring-explorer

- [Loopring Protocol / Decode Reference](project_loopring_protocol.md) — decode reference for L1 block calldata, cross-checked against protocol source AND live mainnet blocks. **Key fact: the published repo source does NOT match what was deployed for NFT mints — deployed blocks carry nftID inline and contain zero NFT_DATA transactions. When source and live data conflict, live data wins.** Per-type layouts labelled by how each was verified, plus the creatorFeeBips 1-byte fix, the Float24 transfer fix, why zero addresses are correct, and the token-decimals accuracy trap. **2026-08-09 contract sweep: NFT_DATA (type 9) DOES exist on mainnet - 82,314 txs carrying collection+minter+creatorFeeBips+nftType, so collections resolve from calldata; NFT_MINT byte 1 is mintType not nftType (live bug in derive-from-calldata.js); royalties are not protocol-enforced anywhere; smart wallet EIP-1271 is just the owner's signature.** **2026-08-12 NFT CUSTODY: a slot is a PIN, not a label - reusable, and TRANSFER publishes the sender's slot with NO destination (toTokenID exists nowhere outside NftMintTransaction.sol). Slots NOT preserved across holders (11.7% of 94,850). Resolution is entirely sender-side: 58.0% named when the sender ever minted, 0.9% when not. Stale-binding bug found and fixed (12,898 -> 658 rows labelled after supply was spent). SOLE_HOLDING is UNFALSIFIABLE - 0 of 7,156 rows testable. DO NOT build a slot-assignment solver without the Merkle root check.** Also the SOURCE HIERARCHY: deployed behaviour > contract source > docs.
- [Loopring nftID](project_loopring_nftid.md) — **what `nftID` is and why it is the join key across all three layers: the L1 calldata mint record, the `CIDv0(nft_id)` metadata address, and any snapshot/claim registry entry.** A Merkle root proves inclusion and can never reveal omission; calldata reconstruction is the only thing that makes omission visible, which moves evidentiary authority from a party to a public process. Holds the canonical nftID<->CID conversion, "nftID addresses the METADATA not the image", THE VERIFIER IS THE nftID (not IPFS), positioning, and the **conflict over whether the pipeline was ever validated - RESOLVED BY EXPERIMENT 2026-08-10, 8/8 real Loopring JSONs reproduced their own CIDs.** Structural claim only - do not convert to intent.
- [Calldata Retrieval](loopring_calldata_retrieval.md) — **COMPLETE 2026-08-12: 67,896 / 67,896 fetched, every block sha256-verified, block index contiguous 1..67,896, zero gaps.** Enumerate closed the 186-block hole (23569814..23569999) and raised known submissions to 67,896; two fetch passes stored the last 26. **Root cause of the first pass's 10 missing blocks: the retry windows were CORRECT - all 10 live inside them, proven via l1_txs - so the RPC returned an incomplete event set six consecutive times with no error and no failure counter. An endpoint returning success is not evidence it returned everything.** Only the archive's own contiguity + hash audit caught it. Commands: status / verify / enumerate / fetch / all. **What guarantees what: sha256(data)==publicDataHash is cryptographic and catches corruption; blockIdx DENSITY (67,896 rows, 1..67,896, zero skips) catches omission in the middle; the L1-span audit catches omission at the end. NOTHING checks receipts/txs against block roots - claim 'internally consistent against the chain's own commitments', never 'proven against consensus'.**
- [Loopring Recovery](project_loopring_recovery.md) — **THE JOB: present a JSON whose hash matches the nftID. Provide the bytes, get the hash. Nothing is being fixed or reconstructed - the creator already holds the bytes.** **2026-08-12: THERE IS NO LOOPRING FORMAT - serialisation belongs to the UPLOADER, not the protocol.** Three verified samples, three incompatible shapes (flat+CRLF+alphabetical / 4-space indent+LF / fully minified), all re-hashing to their own nftIDs. The 'flat, alphabetical, CRLF, 8 deterministic candidates' shape is ONE uploader's fingerprint (probably Loopring's UI) and is NOT a general method - for any other uploader the search space is unbounded. Establish which tool made the file before promising a bounded search. Also: nftID addresses the METADATA, not the image (why hashing an image never matches, now confirmed on-chain via uri()); the SDK conversion is canonical with a test vector; CREATE2 is verified as a formula but resolves nothing (0/12 vs ground truth); collections come from L1 TransferSingle logs; the "smart wallets only" claim was false. **THE VERIFIER IS THE nftID, NOT IPFS - retrieval tests availability, never correctness. DEMONSTRATED 2026-08-10: 8/8 real Loopring metadata JSONs re-hashed and reproduced their own CIDs across 8 independent creators, so the arithmetic IS proven against Loopring's own pinned bytes. A failed reconstruction implicates the name/description bytes, not the pipeline - do not reintroduce the "never validated" framing.**
- [His Own Mints](project_loopring_own_mints.md) - account 33443 + the 13 mints found in the **15% of blocks that were decoded**, so that list was NEVER complete; plus the 784-candidate reconstruction that failed. **2026-08-12: a THIRD collection `0x73236b2a7943B208bC881ABf44F9C2BA81Fd4B49` = "3D Art by LoNEWolf" (wallet UI, not chain-derived); Coffee House Pack and House on the Prairie identities recorded in full; first NFT seen carrying `attributes`; and the `royalty_percentage` colon-NO-SPACE detail that invalidated every candidate until fixed - serialiser now reproduces the AA5K sample byte-exactly.** Staged work lives in `ipfs-node` (private) + `ipfs-content` (public). **Blocker LIFTED 2026-08-10.** Collections: `0x8eb42287...` = 3D Metaverse Assets; `0x7a520803...` UNVERIFIED, do not guess.
- [Snapshot Provenance](project_loopring_snapshot_provenance.md) — governance data is Snapshot's account used IN LIEU OF L1 data (none exists for voting), not a substitute for calldata skipped; signature recovery can never reach calldata's trust tier, no equivalent of publicDataHash exists to check totals against
- [Loopring Revival](project_loopring_revival.md) — read-only explorer revival under lonewolf-loopring identity; **ONE exclusion to the calldata-only rule: the core team's own explorer pages run as they shipped them, subgraph and all, because the line is authorship. Everything we wrote is calldata-only, firm.** Current route tree, what is dead (REST API stubs), self-sovereign operator (Sepolia) status
- [Decoder Community Reception](project_decoder_community_reception.md) — full arc: decoder announced, hostility/deflection pattern documented, apology extracted, one genuine good-faith resolution (contrast case), final asymmetric-accountability observation; plus why "reverse engineering" is a mislabel to refuse rather than justify
- [Precision Over Helpfulness](feedback_precision_over_helpfulness.md) — don't validate/extend unfounded theories just to seem agreeable, especially re: other people's motives/intent; say "I don't know" mid-conversation when warranted; refined: "what does evidence show" (answerable) vs "what is the truth about hidden intent" (usually not)
- [Loopring Corrections](feedback_loopring_corrections.md) — the WHY behind the Loopring rules: dated record of claims that were wrong and what each cost. Narrative only, no instructions; read the project files for those.
- [Failure Record 2026-08](feedback_failure_record_2026_08.md) — dated evidence of ~14 repeats of the same failure in one session, including building the Loopring recovery tool on The Graph, which negates the project's only requirement. Read before assuming any prior "verified" claim was verified against the chain.
- [Verify Before Asserting](feedback_verify_before_asserting.md) — stop collapsing ambiguous signals into confident conclusions; check directly instead of inferring; root cause of the verify bug, premature "gone" calls, and the GitHub identity mistake. **Grep memory BEFORE responding to any claim about his work, not after being told to** — recurred 4x in conversation Aug 8 '26

## Other client/personal projects

- [Arcwright](project_arcwright.md) — client project: neighbor's welding site, stack, CMS design
- [Portfolio Portal](project_portfolio_portal.md) — personal-portfolio portal: Hoodi testnet, ClientLedger, DebtToken ERC-1155
- [Portfolio](project_portfolio.md) — personal portfolio site
- [Fork/Child Visual](feedback_fork_child_visual.md) — confirmed UI pattern for showing a project's fork/child relationship: indent + branch line, not smaller font

## System / Machine

- [Flameshot Fork](project_flameshot.md) - patched flameshot at ~/github/flameshot-src; Wayland BypassWindowManagerHint kills keyboard focus in any separate window; DBus activation resurrects the packaged binary
- [NordVPN / WireGuard](project_nordvpn_wireguard.md) — why the official GUI was dropped, the suspend/resume fix, how stale keys get refreshed via API without reinstalling the app

## Cross-cutting / personal

- [User](user.md) — full identity, cognitive profile, personal context pointer (private repo)
- [Kendra Tennessee](kendra_tennessee.md) — Florida secession prediction + hate fuck both routed by Kendra outward and got grace; Justin shared one screenshot and got punished. Core rule: information that protects the structure gets grace, information that challenges it gets punished.
- [Maxwell's Demon Framework](demon_framework.md) — unified thesis: demon/gate layers, Katie July 15 (named herself) + July 25 (listed gate beneficiaries, "I get your game", zkProofs close), GME October thesis, blockchain capture vs ownership
- [Katie - Unsettled Loop](katie_unsettled_loop.md) — named mechanic: observation → discussion → no handshake → deflection; six deflection tactics incl. "motive substitution" (BTC/Saylor/Adam foreclosure exchange, 2026-08-06); verified via dated screenshot ledger; cumulative same-actor pattern evidence vs. unrelated-correlation stacking, kept as separate evidentiary categories
- [GME Exit](project_gme_exit.md) — sold against thesis on principle; BLOB/CSAM risk + institutional BTC capture disqualified the infrastructure; Katie reframes as incompetence to avoid crediting the logic
- [Agency Paradox](project_agency_paradox.md) — "do women have agency?" defeats victimhood-as-asset; toggle tell; Epstein files protect the answer not the names; "what is a woman" = definitional protection
- Katie analysis → `/home/zenko/.claude/personal-context/katie_analysis_document.md` (private repo)

## Working feedback (general)

- [Decode First](feedback_decode_first.md) — fetch a real tx and read the hex structure before writing any ABI parser; don't guess the ABI
- [Docs vs Bytecode](feedback_docs_vs_bytecode.md) — "judge us by our actions (zkProofs), not our words (documentation)"; verification that needs no trust in the source vs a claim that does; and where the instrument mis-fires
- [Magical Beans](feedback_magical_beans.md) — Justin's term for fiat money; never Adam's or Katie's phrase
- [Speaker Attribution](feedback_text_screenshots.md) — I consistently get who-said-what backwards; confirmed in screenshots (blue right=Justin) AND in plain-text transcripts (check tags, don't assume)
- [Memory Review Before Writing](feedback_memory_review.md) — always draft memory content and show Justin for approval before writing; hold this even mid-session when momentum picks up
- [Terminal Commands](feedback_terminal_commands.md) — never use ! prefix; just plain code blocks Justin can copy and run
- [Permission Granted](feedback_permission_granted.md) — scoped execution autonomy; reads proceed freely, modifications get shown first, no re-asking permission mid-task
- [Identity Redaction](feedback_identity_redaction.md) — never write "Justin" into code or technical/project memory, pronouns/role terms instead; exception for personal-context memory (Katie/Kendra/Adam/family); protects pseudonym separation
- [Nuance Means Threading](feedback_nuance_means_threading.md) — "add nuance" means connective tissue between facts, not more volume; terse and undifferentiated-dump are the same failure; a real analysis (Coinbase/Taiko/Loopring capture) was lost this way
- [Flow Over Friction](feedback_flow_over_friction.md) — do the thing, caveat after in one line; ask only about what cannot be undone; check the file before repeating anything from a summary

## References

- [References](references.md) — beer-bot location/access/commands, Pi access, Taiko contacts, **people: Ryan Kagy (@RSKAGY) and Autodestructive/@LoopExchange — read before reacting to either name**
- [SSH/GitHub Identities](IDENTITIES.md) — canonical identity map: which account/key owns which repo, why ~/github is foldered by identity, the plain-github.com remote gotcha. Check before any identity-sensitive action. `~/.ssh/IDENTITIES.md` symlinks here. **Also holds the DO NOT SANITIZE THE IDENTITY OVERLAP decision (2026-08-09): the Loopring memory in the kyotodesertfox repo and the shared deploy wallet are deliberate and must not be cleaned up.**
- [Memory Cleanup](project_memory_cleanup.md) — DONE 2026-07-30: fully consolidated the untracked homestead/loopring-explorer per-directory stores into this one tracked store, since sessions always launch from ~/github and those stores would otherwise never be read again; nft_beacon merge complete; old stores retired in place (MEMORY.md pointer left, no files deleted)
