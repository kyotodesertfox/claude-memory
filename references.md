---
name: references
description: "External system pointers — beer-bot, Pi access, Discord, contract addresses"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
  modified: 2026-08-08T23:35:41.550Z
---

## Beer-Bot (Discord) — DORMANT

**Status as of 2026-05-24:** JAX Discord server is dead — the beer group has disbanded. Bot is likely still running on the Pi but has no active audience. Pi itself is being phased out in favor of the laptop. Do not prioritize any work here unless user explicitly asks.

- **Host:** Raspberry Pi at `192.168.12.3` — `ssh 192.168.12.3` (key: `~/.ssh/internal`)
- **Repo on Pi:** `~/github/jax-ale-exchange/discord/beer-bot/`
- **Local clone:** `/home/zenko/github/kyotodesertfox/beer-bot/`
- **GitHub:** `git@github.com:kyotodesertfox/discord-beer-bot.git`
- **Entry point:** `src/main.py`
- **Secrets:** `secrets/.env` (`BEER_BOT_TOKEN`, `ANTHROPIC_API_KEY`, `MEMBER_SALT`, `GUILD_ID`) — gitignored, never commit
- **Service:** systemd on Pi — do not restart; user handles that

**Git workflow:** Edit locally → push → pull on Pi. Never edit directly on Pi.

**What it does:**
- Status bar (every 2 min): live `$BEER = X.XXXXXX ETH` as Discord bot status
- Chain event poller (every 30s, up to 500 blocks): Swap, Mint, Purchased, Redeemed, InventoryNFTPurchased, BatchMinted events → Discord embeds in `chain_events` channel (`1503622733072830464`)
- `/pool`, `/announce-mint`, `/announce-stock [listing_id]`, `/ask <question>` — slash commands
- `/respond [message_ids] [context]`, `/respond_context <id> <ctx>`, `/respond_mention <id> <@user> <ctx>` — admin only; fetches messages guild-wide, tags authors, replies same-channel or sends with jump links cross-channel
- **Passive dissent detection:** Scans all non-bot messages for platform-questioning keywords (`scam`, `rug`, `illegal`, `atf`, `fraud`, `fake`, `worthless`, etc.) — local keyword check first (free), calls Claude (`DISSENT_MODIFIER` framing) only when triggered; 60-second per-channel cooldown
- **Ask cog:** `src/cogs/ask.py`, model `claude-haiku-4-5-20251001`, prompt caching on SYSTEM_BASE, best-friend mode (role `1504239291704807486`) — casual tone, bot calls itself Nexus

**Contract addresses watched (Taiko Mainnet):**

| Contract | Address |
|---|---|
| beer_nft | `0x210970F39B3AD4081090100Ed871fE42C54C2101` |
| pair | `0x7Bbdb6214b0592031933345C8E75186f90d01222` |
| marketplace | `0x2321bDF62364ee38Fcf6b631C9742f6BF61B66Aa` |
| treasury | `0x631f9D082019E25a2BfD219BF235cA0b742206EC` |

`BEER_IS_TOKEN0 = True` — BEER address < WETH address.

**State file:** `~/github/jax-ale-exchange/discord/beer-bot/chain_state.json` — stores `last_block`.

**Discord app:** Client ID `1503627009178210374`. Push notifications via ntfy.sh topic `jax-discord-bot-904`.

---

## Private Personal Memory Repo

- **Local path:** `/home/zenko/.claude/personal-context/`
- **GitHub:** `git@github.com:kyotodesertfox/claude-memory-personal-context.git` (private)
- **Purpose:** Personal/social context that should not live in the public `claude-memory` repo — Katie dynamic, family, social architecture, behavioral analysis documents
- **Contents:** `user.md` (personal context), `katie_behavioral_analysis.txt`, `katie_actions_vs_words.txt`, `katie_analysis_document.md`
- **Git workflow:** Edit or copy files to `/home/zenko/.claude/personal-context/`, commit, push. Identity already configured locally.

---

## SSH / GitHub Identities

**Canonical mapping lives at `~/.ssh/IDENTITIES.md`** - check that file (or grep it) before any GitHub-identity-sensitive action, not just per-project memory files.

`~/github/` is foldered by identity, so the parent directory IS the identity scope: `~/github/kyotodesertfox/` (default, `zenko18` key) and `~/github/lonewolf-loopring/` (separate key). Nothing else at that root. See [[project-loopring-revival]].

A remote pointing at plain `github.com` resolves to the `zenko18` key regardless of which account owns the repo - that is the exact cross-identity mistake documented in [[feedback-verify-before-asserting]], found live in the `Marketplace-Web` remote and fixed 2026-08-02.

**Why it is foldered this way (reorg 2026-08-02):** the previous flat layout had `Taiko/` and `loopring/` each mixing both identities *and* third-party upstream clones together, so nothing about a repo's path told you which account it belonged to. That was the structural cause of the repeated cross-identity mistakes, not carelessness in any single instance. Making the parent directory the identity scope means the answer is unavoidable rather than something to remember to look up.

Consequences of that reorg worth knowing:
- Upstream Loopring org clones (`protocols`, `protocol3-circuits`) now sit at `loopring-explorer/upstream/` - ~2.0G, excluded from git via `.git/info/exclude` so the tracked `.gitignore` stays clean. They belong to *neither* identity; never push them.
- `deploy-sepolia` holds the operator harness plus `keygen_cmd.sh`, `initialize_args.txt`, `register_circuit.md`, moved in from the old root.
- Local clones of `Marketplace-Web` and `DEX` were deleted (~2.2G); uncommitted deltas were discarded deliberately after confirming remote HEAD matched local. Both still exist on GitHub - re-clone via the `lonewolf-loopring` alias, not `github.com`.

---

## Taiko Contacts

- **Joaquin Mendez** — COO of Taiko
- **Pigi** — Head of Ecosystem at Taiko

---

## People - Community / Ecosystem

### Ryan Kagy (@RSKAGY)

Former GameStop blockchain developer / community lead. Departure circumstances unknown - quit or terminated, never confirmed. Now building on Base. Spoke very negatively about GameStop in a phone conversation some time ago.

**How the connection started:** first encountered through the GameStop investing scene, which was also the entry point into Loopring. His Metaverse world-building is what led to the 3D asset and Blender work. Whether he built those himself or contracted the work is unknown.

**The working relationship and how it ended:** built 3D environments in Blender for him - taken up as a creative avenue, not a job, and never under an agreement. Kagy paid nothing in money but sent a large amount of $CREATE, a token on Base that he minted and controls. All of it was returned: "I didn't earn it," "I didn't want free money." A token the issuer can print at will is not a costly signal and carried no information about the work's worth - the same reasoning later applied to free praise.

The work was then abandoned undelivered on learning it was destined for a Base project. Reason: unwilling to provide value to Base. Same principle hierarchy as the GME exit (see [[project-gme-exit]]) - contaminated infrastructure is disqualifying regardless of cost - except here the cost landed on someone else who was counting on delivery.

**How to read him:** Kagy was angry about the non-delivery and was right to be. Self-assessed as a betrayal, in those words, and not softened. Other than being on Base, he did nothing known to be wrong. **Do not treat him as an adversary.** The grievance is legitimate and originates from this side. That is the fork, and it is the whole of it.

Tagged by @koip741 (koip.base.eth, also Base) alongside @ryancohen, @l2beat, and @loopringorg in an Aug 8 '26 thread suggesting the Loopring community "merge efforts."

### Autodestructive / @LoopExchange

- Wallet `0xC7Eaf32B4141FC4a0984A501D41Da6F06Be13bB6`
- Ran a secondary NFT marketplace outside GSMP; built LoopringRescueRegistry (Merkle-gated ERC-1155 claim for snapshot holders). Exit-liquidity focused - the opposite cash flow from the recovery tool's customer, see [[project-loopring-recovery]].
- Present for the decoder announcement thread. Did NOT use the "reverse engineering" objection; that came from others. See [[project-decoder-community-reception]].
- Asked on Aug 8 '26 via @koip741 whether the decoder work was a joint effort with him. Answer given: no, personal effort.
- Standing as of Aug 8 '26: unknown. Not established as hostile, not established as trustworthy.

---

## Home Assistant (Dormant)

Previously ran for home automation — presence detection, lights, reminders. Katie specifically wants it running again. Not active, not committed. Revisit when the time is right; don't push it.

---

## NordVPN Access Token

`~/.nordvpn-token.sh` (mode 600, `$NORDVPN_ACCESS_TOKEN` via `.bashrc`) — used to pull a fresh key/server from NordVPN's API when the manual config goes stale. See [[project-nordvpn-wireguard]].
