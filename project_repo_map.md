---
name: project_repo_map
description: "Local repo layout and GitHub repo status — what exists where and what's been consolidated"
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

## Local — /home/zenko/github/

| Path | Status |
|------|--------|
| `homestead/` | Main project — contracts, apps, everything |
| `jax-ale-exchange/` | JAX website + discord bot (beer-bot on Pi) |
| `farm/eggs/` | Superseded by homestead/apps/egg — GitHub repo deleted |
| `farm/solidity/` | Superseded by homestead/contracts/core — GitHub repo deleted |
| `jax-points-tracker/` | Fork — points tracker |
| `databases/` | Unknown |
| `LRC_Price_Check/` | Unknown |
| `Taiko/` | BANNED — do not read or write anything here |

## GitHub — kyotodesertfox/

| Repo | Status |
|------|--------|
| `homestead` | Active, private — main project |
| `jax-discord-beer-box` | Active — unified Discord bot |
| `arcwright` | Active — separate client project (neighbor), never delete |
| `jax-brewers` | Active — Jacksonville Brewers Association |
| `jax-points-tracker` | Fork |
| `Home-Assistant` | Old, dormant |
| `farm-solidity` | Deleted — consolidated into homestead |
| `farm-eggs` | Deleted — consolidated into homestead |
| `jax-website` | Deleted — consolidated into homestead |
| `jax-discord-bot` | Deleted — consolidated into beer-bot |
| `jax-discord-ai-bot` | Deleted — consolidated into beer-bot |

## Pi — 192.168.12.3 /home/zenko/github/

| Path | Status |
|------|--------|
| `jax-ale-exchange/discord/beer-bot/` | Active service (beer-bot.service) |
| `arcwright/` | Client project — leave alone |
