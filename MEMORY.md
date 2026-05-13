# Memory Index

- [User Profile](user_profile.md) — who he is, how he thinks, how to work with him best
- [Beer DEX Project Context](project_beer_dex.md) — physical beer-backed $BEER token + NFT redemption system built on the ART DEX framework
- [FarmDEX Ecosystem](project_farm_ecosystem.md) — full system: TokenDeployer factory + masterTemplate ERC20 (farm/solidity) feeds into the DEX/Marketplace via IFarmDEX.onTokenMinted() callback
- [Git Identity](feedback_git_identity.md) — use "Homestead" / 19782272+kyotodesertfox@users.noreply.github.com, no Claude branding in commits
- [No Service Restarts](feedback_service_restarts.md) — never restart systemd/background processes; user handles that themselves
- [No Auto Push](feedback_no_autopush.md) — commit only by default; never git push unless user explicitly says to push
- [Taiko/DEX Banned](feedback_taiko_dex_banned.md) — /home/zenko/github/Taiko/DEX is off-limits; use homestead/contracts instead
- [SCP for Pi deploys](feedback_scp_pi.md) — write files locally first, then scp to Pi; never write directly over SSH (encoding breaks)
- [Memory Warning](feedback_memory_warning.md) — warn user before any bulk memory consolidation or restructuring
- [No Command Lists](feedback_no_command_lists.md) — don't present multiple shell command blocks as a checklist; keep it conversational
- [Reduce Friction](feedback_reduce_friction.md) — proactively flag friction points and suggest fixes; user will act on recommendations
- [Arcwright](project_arcwright.md) — separate client website for a neighbor; future optimization task, unrelated to homestead
- [Repo Map](project_repo_map.md) — full map of local, GitHub, and Pi repos; what's active, deleted, or consolidated
- [Beer Bot](reference_beer_bot.md) — Discord bot on Raspberry Pi (192.168.12.3, ~/.ssh/internal), polls Taiko chain events, slash commands /pool /announce-mint /announce-stock
- [Work Locally for Pi](feedback_work_local.md) — clone remote repos locally instead of SSH-reading files; faster iteration, then SCP or push back
- [Contract Architecture](project_contracts.md) — all contracts: storage layouts, deployed addresses (Hekla 167000), upgrade status, post-deploy config steps
- [Check Existing Files](feedback_check_existing_files.md) — run find before creating any new file; contracts often already exist in unexpected directories
- [Core Philosophy](project_philosophy.md) — brewer-first but Treasury-ultimate; no value sinks ever; pool-specific token rewards
