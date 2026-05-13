---
name: project_memory_infra
description: Memory infrastructure — master location, GitHub backup, daily sync, and session startup rules
metadata:
  type: project
---

## Master memory location

All memory files live at `~/.claude/memory/`. This is a git repo synced to a private GitHub repository.

**GitHub repo:** `github.com/kyotodesertfox/claude-memory` (private)

The project-specific path `~/.claude/projects/-home-zenko-github-Taiko-DEX/memory/` is a symlink → `~/.claude/memory/`. The `~/` launch path `~/.claude/projects/-home-zenko/memory/` is also a symlink → `~/.claude/memory/`.

## Daily sync

A cron job runs at 3am daily:
- Script: `~/.claude/memory/sync.sh`
- Only commits if files changed (`git diff --cached --quiet && exit 0`)
- Log: `~/.claude/memory/sync.log`
- Crontab entry: `0 3 * * * /home/zenko/.claude/memory/sync.sh >> /home/zenko/.claude/memory/sync.log 2>&1`

## Session startup rule

**Always launch Claude from `~/`** — memory resolves correctly via symlink from that path. If working directory is NOT `/home/zenko` at session start, warn the user immediately so they can exit and relaunch.

## Disaster recovery

If laptop dies: `git clone git@github.com:kyotodesertfox/claude-memory.git ~/.claude/memory/` then recreate symlinks:
```
ln -s ~/.claude/memory ~/.claude/projects/-home-zenko/memory
mkdir -p ~/.claude/projects/-home-zenko-github-Taiko-DEX
ln -s ~/.claude/memory ~/.claude/projects/-home-zenko-github-Taiko-DEX/memory
```
