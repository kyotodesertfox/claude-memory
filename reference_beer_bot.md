---
name: reference_beer_bot
description: "Beer-bot Discord bot — where it lives, how to access it, what it does, contract addresses it watches"
metadata: 
  node_type: memory
  type: reference
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

## Location & Access

- **Host:** Raspberry Pi at `192.168.12.3`
- **SSH key:** `~/.ssh/internal` (configured in `~/.ssh/config`)
- **SSH command:** `ssh 192.168.12.3`
- **Repo path on Pi:** `~/github/jax-ale-exchange/discord/beer-bot/`
- **Local clone:** `/home/zenko/github/beer-bot/`
- **GitHub remote:** `git@github.com:kyotodesertfox/discord-beer-bot.git`
- **Entry point:** `src/main.py`
- **Secrets:** `secrets/.env` (contains `BEER_BOT_TOKEN`, `ANTHROPIC_API_KEY`, `MEMBER_SALT`, `GUILD_ID`) — gitignored, never commit
- **Runs as:** systemd service on the Pi (do not restart — user handles that)

## Git Workflow

**Edit locally → push → pull on Pi.** Never edit directly on Pi.
```
# After making changes locally:
git add ... && git commit -m "..." && git push
ssh -i ~/.ssh/internal 192.168.12.3 "cd ~/github/jax-ale-exchange/discord/beer-bot && git pull"
```
Pi was previously edited directly and had uncommitted work. All synced as of 2026-05-13 (commit 543764b). Going forward, local is source of truth.

## What It Does

**Status bar** (every 2 min): Reads pair reserves, posts live `$BEER = X.XXXXXX ETH` as Discord bot status.

**Chain event poller** (every 30s, up to 500 blocks): Watches Taiko mainnet and posts embeds to the `chain_events` channel (`1503622733072830464`) for:
- `Pair.Swap` → 🟢 Buy / 🔴 Sell announcements
- `Pair.Mint` → 💪 Liquidity Added
- `Marketplace.Purchased` → 🛒 Beer Sold
- `Marketplace.Redeemed` → 🍻 Beer Poured
- `Treasury.InventoryNFTPurchased` → 📦 New Batch Added
- `NFT.BatchMinted` / `NFT.Minted` → 🍺 New Beer Batch Minted

**Slash commands:**
- `/pool` — live BEER/ETH reserves + price
- `/announce-mint` — announces latest batch mint
- `/announce-stock [listing_id]` — announces marketplace inventory
- `/ask <question>` — ask JaxBot anything about $BEER / craft beer
- `/respond [message_ids] [context]` — admin only; comma-separated message IDs, optional context. Fetches messages guild-wide (not just current channel). Tags all unique authors. Same channel → Discord reply to first message. Cross-channel → plain send with jump links per cross-channel message + author mentions.
- `/respond_context <message_id> <context>` — admin only; single message required, context required. Cleaner UX when you have one target and specific framing. Same tag/reply/jump-link behavior as `/respond`.
- `/respond_mention <message_id> <@user> <context>` — admin only; use when you want to tag someone explicitly who may not be the message author. Claude addresses the response to the tagged user by name. Both message author and tagged user are mentioned if they differ.

**Passive dissent detection** (all channels, no API cost unless fired):
- Scans every non-bot message for platform-questioning keywords (`scam`, `rug`, `illegal`, `atf`, `fraud`, `fake`, `worthless`, etc. — full list in `DISSENT_TRIGGERS` in `ask.py`)
- General beer chat never fires it — triggers are platform/legal/fraud-specific
- When triggered: calls Claude with `DISSENT_MODIFIER` framing (calm, factual, 2-4 sentences, ends with open invitation)
- Replies directly to the triggering message
- 60-second per-channel cooldown to prevent credit burn from spamming
- Design principle: local keyword check first (free), Claude only called when needed

**Admin command reply/mention behavior (all three respond commands):**
- Same channel as message → `message.reply()` with explicit `@mention` in content (guarantees ping regardless of user notification settings)
- Cross-channel → `channel.send()` with `@mention` in content + jump link field in embed
- Message fetch always tries `interaction.channel.fetch_message()` first (reliable same-channel detection), then falls back to guild-wide search across all readable text channels

**Push notifications:** ntfy.sh topic `jax-discord-bot-904` for bot health events (start, network error, crash).

## Contract Addresses (Taiko Mainnet)

| Contract    | Address |
|-------------|---------|
| beer_nft    | `0x210970F39B3AD4081090100Ed871fE42C54C2101` |
| pair        | `0x7Bbdb6214b0592031933345C8E75186f90d01222` |
| marketplace | `0x2321bDF62364ee38Fcf6b631C9742f6BF61B66Aa` |
| treasury    | `0x631f9D082019E25a2BfD219BF235cA0b742206EC` |

`BEER_IS_TOKEN0 = True` — BEER address < WETH address, so BEER is token0 in the pair.

## State File

`~/github/jax-ale-exchange/discord/beer-bot/chain_state.json` — stores `last_block` to avoid re-processing events on restart.

## Discord App

- **Client ID:** `1503627009178210374`
- **Invite URL:** `https://discord.com/api/oauth2/authorize?client_id=1503627009178210374&permissions=2146958847&scope=bot%20applications.commands`
- **Permissions integer:** `2146958847` (everything except Administrator)
- **Privileged Intents enabled:** Message Content, Server Members, Presence

## Ask Cog (Claude-powered)

- **File:** `src/cogs/ask.py`
- **Triggers:** `@BeerBot`, `/ask`, `/respond` (admin), or dissent keyword match
- **Model:** `claude-haiku-4-5-20251001` (fast, cheap, sufficient for Q&A)
- **API key:** `ANTHROPIC_API_KEY` in `secrets/.env`
- **SDK:** `anthropic` Python package
- **Prompt caching:** `SYSTEM_BASE` block marked `cache_control: ephemeral` — cached across calls
- **Best-friend mode:** role ID `1504239291704807486` — casual tone, bot calls itself Nexus
- **Nexus violation:** non-best-friend uses the name "Nexus" → bot is dramatically offended before answering

## Related

[[project_beer_dex]]
