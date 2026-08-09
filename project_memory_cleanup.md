Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

---
name: project-memory-cleanup
description: "One-time cleanup task - project memory scattered across untracked per-directory stores; exact moves needed, no deletions"
metadata:
  type: project
  modified: 2026-07-30
---

# Task: Memory Store Cleanup

Justin asked for this to be picked up in a new session launched from `~/github` (root), specifically to work through this cleanup. This file is the handoff note.

## Root cause (already diagnosed, do not re-litigate)

Claude Code's auto-memory is keyed to the exact literal directory a session launches from. `~/github`, `~/github/Taiko-DEX` (stale, no longer exists), and `~/` are symlinked to this tracked, git-backed store (`~/.claude/memory/`). But `~/github/homestead` and `~/github/loopring/loopring-explorer` are **real, untracked, ungit'd directories** with their own separate memory stores:

- `/home/zenko/.claude/projects/-home-zenko-github-homestead/memory/`
- `/home/zenko/.claude/projects/-home-zenko-github-loopring-loopring-explorer/memory/`

Justin works long sessions that bounce across multiple projects (homestead → loopring → arcwright → loopring, etc.) rather than one-project-per-session — that's a deliberate workflow choice (in-conversation nuance matters to him, not just durable facts) and is **not changing**. The actual fix is that Claude should route new memory writes to the topically-correct project store during a session, not default to the launch directory. This cleanup is the one-time catch-up for what already scattered before that discipline was established.

## Exact moves needed (move, do not delete anything)

### 1. Loopring content stuck in the homestead store → move to loopring-explorer store

From `/home/zenko/.claude/projects/-home-zenko-github-homestead/memory/`:
- `project_loopring_revival.md`
- `project_loopring_calldata.md`

To `/home/zenko/.claude/projects/-home-zenko-github-loopring-loopring-explorer/memory/`

That store already has: `project_decoder_community_reception.md`, `project_moody_brains.md`, `project_recovery_repin.md`, `project_recovery_tool.md`. Check for topical overlap/duplication before just dropping the files in (e.g. `project_recovery_repin.md` and `project_loopring_calldata.md` may both touch L1 recovery/calldata - read both before merging or leaving separate).

### 2. Personal/cross-cutting content stuck in the homestead store → move to this tracked core store (`~/.claude/memory/`, where this file lives)

From `/home/zenko/.claude/projects/-home-zenko-github-homestead/memory/`:
- `kendra_tennessee.md`
- `demon_framework.md`
- `project_gme_exit.md`
- `project_agency_paradox.md`

These aren't Homestead-project-specific - they ended up there only because sessions discussing them launched from `~/github/homestead`. Homestead's own `MEMORY.md` TODO already flagged `kendra_tennessee.md` and `demon_framework.md` for this exact move (`project_gme_exit.md` and `project_agency_paradox.md` weren't in that TODO but are the same category - verify they don't already have a home here before moving).

### 3. Diverged duplicate: `project_nft_beacon.md`

Exists in **two places** with genuinely different content, not just formatting drift:
- `/home/zenko/.claude/memory/project_nft_beacon.md` (this store) - dated 2026-06-21, describes the **implemented** two-track NFTDeployer + UpgradeableBeacon architecture, deploy sequencing, storage layout. This is the current/authoritative state.
- `/home/zenko/.claude/projects/-home-zenko-github-homestead/memory/project_nft_beacon.md` - earlier "decided, not yet implemented" draft. Has unique content NOT in the core copy: the tier-system split (standard producers get platform-managed BeaconProxy; high-tier attested producers get self-governed custom collections) and the "deploy-line pattern" insight (features never ship because each one reveals the next; correct pattern is build-until-stable-then-push-everything-at-once).

**Action:** fold the tier-system and deploy-line-pattern content into the core copy as a dated addendum (do not overwrite the implemented-architecture content already there). Then rename the homestead copy to `project_nft_beacon.superseded.md` in place (do not delete) so the history is preserved but it's no longer read as current.

## After moving files

Update `MEMORY.md` in every store touched (this one, homestead's, loopring-explorer's) to reflect what actually lives there now - add index lines for anything moved in, remove index lines for anything moved out, and clear the homestead `MEMORY.md` TODO line once its items are actually moved.

## What NOT to do

- Don't touch `-home-zenko-github-Taiko-DEX` - that directory hash is stale (the actual project directory was renamed to `~/github/Taiko`, and that store is just a symlink to this same core store anyway, so there's nothing separate to clean up there).
- Don't delete any file outright - move/rename only, per Justin's explicit instruction.
- Don't re-run the full diagnosis (which files use "Justin" by name, commit history questions, etc.) - that's already resolved; this file is the actionable residue.
