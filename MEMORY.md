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

- [Loopring Protocol / Decode Reference](project_loopring_protocol.md) — decode reference for L1 block calldata, cross-checked against protocol source AND live mainnet blocks. **Key fact: the published repo source does NOT match what was deployed for NFT mints — deployed blocks carry nftID inline and contain zero NFT_DATA transactions. When source and live data conflict, live data wins.** Per-type layouts labelled by how each was verified, plus the creatorFeeBips 1-byte fix, the Float24 transfer fix, why zero addresses are correct, and the token-decimals accuracy trap.
- [Loopring Recovery](project_loopring_recovery.md) — **THE METADATA JSON FORMAT IS CRACKED AND BYTE-VERIFIED** (2026-08-03): flat 4-field JSON, keys alphabetically sorted, CRLF endings, no indent; only the field separator (1-2 CRLF) and trailing whitespace (0-3 CRLF) vary, so reconstruction is 8 deterministic candidates, not a search. Three L2-only NFTs reproduced exactly, proving CIDv0(nftID) resolves to live content for never-deployed collections. Also: nftID addresses the METADATA, not the image (why hashing an image never matches); the SDK conversion is Loopring-canonical with a committed test vector; CREATE2 salt bakes in the baseURI; and the "smart wallets only" claim was false (EOAs resolve fine). Provenance is unconditionally rebuildable from calldata alone; content needs the creator's exact original bytes.
- [His Own Mints](project_loopring_own_mints.md) - account 33443 + all 13 of his mints with nftIDs, derived from calldata; archive state; and the 784-candidate reconstruction that failed. **The blocker: the JSON builder has never been validated against a known-good sample, so every miss is uninterpretable.** Do not re-derive.
- [Loopring Revival](project_loopring_revival.md) — read-only explorer revival under lonewolf-loopring identity; **ONE exclusion to the calldata-only rule: the core team's own explorer pages run as they shipped them, subgraph and all, because the line is authorship. Everything we wrote is calldata-only, firm.** Current route tree, what is dead (REST API stubs), self-sovereign operator (Sepolia) status
- [Decoder Community Reception](project_decoder_community_reception.md) — full arc: decoder announced, hostility/deflection pattern documented, apology extracted, one genuine good-faith resolution (contrast case), final asymmetric-accountability observation; plus why "reverse engineering" is a mislabel to refuse rather than justify
- [Precision Over Helpfulness](feedback_precision_over_helpfulness.md) — don't validate/extend unfounded theories just to seem agreeable, especially re: other people's motives/intent; say "I don't know" mid-conversation when warranted; refined: "what does evidence show" (answerable) vs "what is the truth about hidden intent" (usually not)
- [Failure Record 2026-08](feedback_failure_record_2026_08.md) — dated evidence of ~14 repeats of the same failure in one session, including building the Loopring recovery tool on The Graph, which negates the project's only requirement. Read before assuming any prior "verified" claim was verified against the chain.
- [Verify Before Asserting](feedback_verify_before_asserting.md) — stop collapsing ambiguous signals into confident conclusions; check directly instead of inferring; root cause of the verify bug, premature "gone" calls, and the GitHub identity mistake. **Grep memory BEFORE responding to any claim about his work, not after being told to** — recurred 4x in conversation Aug 8 '26

## Other client/personal projects

- [Arcwright](project_arcwright.md) — client project: neighbor's welding site, stack, CMS design
- [Portfolio Portal](project_portfolio_portal.md) — personal-portfolio portal: Hoodi testnet, ClientLedger, DebtToken ERC-1155
- [Portfolio](project_portfolio.md) — personal portfolio site
- [Fork/Child Visual](feedback_fork_child_visual.md) — confirmed UI pattern for showing a project's fork/child relationship: indent + branch line, not smaller font

## System / Machine

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

## References

- [References](references.md) — beer-bot location/access/commands, Pi access, Taiko contacts, **people: Ryan Kagy (@RSKAGY) and Autodestructive/@LoopExchange — read before reacting to either name**
- [SSH/GitHub Identities](IDENTITIES.md) — canonical identity map: which account/key owns which repo, why ~/github is foldered by identity, the plain-github.com remote gotcha. Check before any identity-sensitive action. `~/.ssh/IDENTITIES.md` symlinks here.
- [Memory Cleanup](project_memory_cleanup.md) — DONE 2026-07-30: fully consolidated the untracked homestead/loopring-explorer per-directory stores into this one tracked store, since sessions always launch from ~/github and those stores would otherwise never be read again; nft_beacon merge complete; old stores retired in place (MEMORY.md pointer left, no files deleted)
