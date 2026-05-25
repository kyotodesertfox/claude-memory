---
name: references
description: "External system pointers — beer-bot, Pi access, Discord, contract addresses"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

## Beer-Bot (Discord) — DORMANT

**Status as of 2026-05-24:** JAX Discord server is dead — the beer group has disbanded. Bot is likely still running on the Pi but has no active audience. Pi itself is being phased out in favor of the laptop. Do not prioritize any work here unless user explicitly asks.

- **Host:** Raspberry Pi at `192.168.12.3` — `ssh 192.168.12.3` (key: `~/.ssh/internal`)
- **Repo on Pi:** `~/github/jax-ale-exchange/discord/beer-bot/`
- **Local clone:** `/home/zenko/github/beer-bot/`
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

## Home Assistant (Dormant)

Previously ran for home automation — presence detection, lights, reminders. Katie specifically wants it running again. Not active, not committed. Revisit when the time is right; don't push it.
