# Memory Index

Rules, behavioral guidelines, and user profile are in `~/.claude/CLAUDE.md` (always loaded).
These files are project/reference context — read when the relevant topic comes up.

**Before writing any memory:** re-read this file first. Navigate the tree to find the right existing file and update it. Only create a new file if the topic genuinely has no home here.

All sessions launch from `~/github`, so this is the single memory store — there are no other per-directory stores to check.

## Homestead

- [Project](project.md) — Homestead: beer DEX, farm ecosystem, philosophy, repo map, pending UI features
- [Contracts](project_contracts.md) — contract architecture, storage layouts, deployed addresses (mainnet 167000), upgrade status
- [NFT Beacon Architecture](project_nft_beacon.md) — implemented two-track NFTDeployer + UpgradeableBeacon architecture, storage layout, deploy sequencing; addendum folds in tier-system split + deploy-line pattern from an earlier superseded draft
- [NFT Beacon (superseded)](project_nft_beacon.superseded.md) — earlier "decided, not yet implemented" draft, kept for history only, not current
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

- [Recovery Tool](project_recovery_tool.md) — NFT Recovery page behavior, data-driven router architecture, smart-wallet-agnostic core + control-proof seam, community actors
- [Recovery Re-Pin](project_recovery_repin.md) — the resurrection thesis (hash is both proof and address; nothing was lost) + the re-pin node; corrected: L1 deployment uses protocol's own safe exodus mechanism (forceWithdraw/withdrawFromMerkleTree), not a risky fork
- [Moody Brains](project_moody_brains.md) — dynamic-NFT contract (0x1cACC…) proving metadata resolves via on-chain uri() baseURI path, NOT CIDv0(nftID); corrects the recovery tool's core address assumption
- [Loopring Revival](project_loopring_revival.md) — read-only explorer revival under lonewolf-loopring identity; what's live (Graph), what's dead (REST API stubs), per-file restore paths, self-sovereign operator (Sepolia) status
- [Loopring Calldata Investigation](project_loopring_calldata.md) — how to decode L1 block submissions; operator wallet, Attestation contract, 98-byte header + split tx layout, decoder live at /decode, ShakePay final block finding
- [Decoder Community Reception](project_decoder_community_reception.md) — full arc: decoder announced, hostility/deflection pattern documented, apology extracted, one genuine good-faith resolution (contrast case), final asymmetric-accountability observation
- [Apollo Programmatic Queries](feedback_apollo_programmatic.md) — never use Apollo hooks (useLazyQuery/client.query) in sequential/programmatic loops, causes stale-data and cache-policy bugs; use raw fetch to /api/graphql instead
- [Precision Over Helpfulness](feedback_precision_over_helpfulness.md) — don't validate/extend unfounded theories just to seem agreeable, especially re: other people's motives/intent; say "I don't know" mid-conversation when warranted; refined: "what does evidence show" (answerable) vs "what is the truth about hidden intent" (usually not)
- [Verify Before Asserting](feedback_verify_before_asserting.md) — stop collapsing ambiguous signals into confident conclusions; check directly instead of inferring; root cause of the verify bug, premature "gone" calls, and the GitHub identity mistake

## Other client/personal projects

- [Arcwright](project_arcwright.md) — client project: neighbor's welding site, stack, CMS design
- [Portfolio Portal](project_portfolio_portal.md) — personal-portfolio portal: Hoodi testnet, ClientLedger, DebtToken ERC-1155
- [Portfolio](project_portfolio.md) — personal portfolio site

## Cross-cutting / personal

- [User](user.md) — full identity, cognitive profile, personal context pointer (private repo)
- [Kendra Tennessee](kendra_tennessee.md) — Florida secession prediction + hate fuck both routed by Kendra outward and got grace; Justin shared one screenshot and got punished. Core rule: information that protects the structure gets grace, information that challenges it gets punished.
- [Maxwell's Demon Framework](demon_framework.md) — unified thesis: demon/gate layers, Katie July 15 (named herself) + July 25 (listed gate beneficiaries, "I get your game", zkProofs close), GME October thesis, blockchain capture vs ownership
- [Katie - Unsettled Loop](katie_unsettled_loop.md) — named mechanic: observation → discussion → no handshake → deflection; verified via dated screenshot ledger (Oct '22 images/dox-threat exchange, documented Aug 2 '26); cumulative same-actor pattern evidence vs. unrelated-correlation stacking, kept as separate evidentiary categories
- [GME Exit](project_gme_exit.md) — sold against thesis on principle; BLOB/CSAM risk + institutional BTC capture disqualified the infrastructure; Katie reframes as incompetence to avoid crediting the logic
- [Agency Paradox](project_agency_paradox.md) — "do women have agency?" defeats victimhood-as-asset; toggle tell; Epstein files protect the answer not the names; "what is a woman" = definitional protection
- Katie analysis → `/home/zenko/.claude/personal-context/katie_analysis_document.md` (private repo)

## Working feedback (general)

- [Decode First](feedback_decode_first.md) — fetch a real tx and read the hex structure before writing any ABI parser; don't guess the ABI
- [Magical Beans](feedback_magical_beans.md) — Justin's term for fiat money; never Adam's or Katie's phrase
- [Text Screenshot Reading](feedback_text_screenshots.md) — blue bubbles on RIGHT = Justin, grey on LEFT = other person; I consistently get this backwards
- [Memory Review Before Writing](feedback_memory_review.md) — always draft memory content and show Justin for approval before writing; hold this even mid-session when momentum picks up
- [Terminal Commands](feedback_terminal_commands.md) — never use ! prefix; just plain code blocks Justin can copy and run
- [Permission Granted](feedback_permission_granted.md) — scoped execution autonomy; reads proceed freely, modifications get shown first, no re-asking permission mid-task
- [Identity Redaction](feedback_identity_redaction.md) — never write "Justin" into code or technical/project memory, pronouns/role terms instead; exception for personal-context memory (Katie/Kendra/Adam/family); protects pseudonym separation
- [Nuance Means Threading](feedback_nuance_means_threading.md) — "add nuance" means connective tissue between facts, not more volume; terse and undifferentiated-dump are the same failure; a real analysis (Coinbase/Taiko/Loopring capture) was lost this way

## References

- [References](references.md) — beer-bot location/access/commands, Pi access, Taiko contacts
- [SSH/GitHub Identities](IDENTITIES.md) — canonical identity map: which account/key owns which repo, why ~/github is foldered by identity, the plain-github.com remote gotcha. Check before any identity-sensitive action. `~/.ssh/IDENTITIES.md` symlinks here.
- [Memory Cleanup](project_memory_cleanup.md) — DONE 2026-07-30: fully consolidated the untracked homestead/loopring-explorer per-directory stores into this one tracked store, since sessions always launch from ~/github and those stores would otherwise never be read again; nft_beacon merge complete; old stores retired in place (MEMORY.md pointer left, no files deleted)
