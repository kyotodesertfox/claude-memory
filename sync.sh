#!/bin/bash
cd ~/.claude/memory
git add -A
git diff --cached --quiet && exit 0   # nothing to commit
git commit -m "Daily sync $(date '+%Y-%m-%d')"
git push
