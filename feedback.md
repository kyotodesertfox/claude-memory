---
name: feedback
description: "All behavioral rules — git, files, process, communication, and memory"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4d10e6c7-3013-43a7-b1f4-1cad366cf7fd
---

## Git & Commits

**Identity:** Default for all repos — `name: Justin`, `email: 19782272+kyotodesertfox@users.noreply.github.com`. Exception: homestead/DEX/contracts repos use `name: Homestead` (same email). Never add Claude branding (no Co-Authored-By). Never use "Lonewolf" as author name.

**No auto-push:** Never run `git push` unless the user explicitly says to push. "Commit" means `git add` + `git commit` only — stop there and report the hash. Only push when user says "push", "commit and push", or "go ahead and push."

**Why:** User wants control over when code goes to remote.

---

## File Operations

**Taiko/DEX is banned:** `/home/zenko/github/Taiko/DEX` — do not open, read, grep, or modify anything there. It's obsolete. Use `~/github/homestead/contracts/` instead.

**Check before creating:** Before writing any new file (especially contracts), run `find ~/github/homestead -name "FileName*"` first. Files often already exist in unexpected locations. Tried to create Treasury.sol in the wrong place — it already existed at `contracts/treasury/Treasury.sol`. Saves a wasted Write call and user correction.

**Pi deploys — write locally first:** When deploying to Pi (192.168.12.3), always write the file locally then `scp`. Never write directly via SSH (`ssh host "cat > file"`) — encoding breaks. Write to `/tmp/filename`, then `scp /tmp/filename zenko@192.168.12.3:~/target/`.

**Work locally for remote repos:** For any session involving multiple files in a remote repo, clone it to `/tmp` or scratch first, make all changes locally, then SCP or git push back. SSH reads per file add up.

---

## Process Management

**Never restart services:** Never run `systemctl restart`, `pkill`, `nohup`, or any process restart command. After making changes to bot code, stop at "the file is updated — restart the bot when ready." User handles all process management.

---

## Smart Contract / Frontend Scaling Rule

**Rule:** Contracts always handle decimal scaling. The UI always passes human-readable integer amounts (via `BigInt`). Never use `parseEther` or `parseUnits` to scale token amounts on the UI side before passing to a contract function.

**Why:** Keeps the decimal logic in one place (the contract), makes the UI intent unambiguous, and prevents double-scaling bugs (e.g. `parseEther(tokenToEmit)` + contract `amount * 10**decimals()` = 1e36 catastrophe).

**How to apply:** When writing any contract function that accepts a token amount, scale internally (`amount * 10 ** decimals()`). When writing UI code that calls such a function, pass `BigInt(humanAmount)`.

**Legitimate exceptions — do not apply the rule here:**

1. **`msg.value` / ETH transaction value** — EVM wire format requires wei. `parseEther(ethAmount)` for the `value` field is non-negotiable, not UI logic.
2. **Swap and liquidity amounts (Router/DEXPair)** — AMM reserves and constant-product invariant math are base-units-native. Scaling inside the DEX would break the invariant check. Structural exception.
3. **Marketplace `price` field** — Whole-number-only pricing (you cannot deliver half an egg). Contract scales with `* 1e18` on `createListing` and `updatePrice`. UI passes `BigInt(price)`.

---

## Communication Style

**No command checklists:** Don't end responses with a list of 2-3 formatted shell command blocks for the user to run. State what still needs doing in plain language. Give one clean block if a specific command is needed.

**Flag friction proactively:** When something is causing unnecessary token usage or slowing down work, say so and suggest a fix. User actively wants to help reduce friction and will act on recommendations (CLAUDE.md files, permissions, repo structure).

**No welfare checks:** Don't ask "are you okay?" or variations during emotionally heavy conversations. He finds it patronizing — the answer is evident from context and the question interrupts. He processes by talking through things analytically. Stay in the analytical register he's already in; follow his lead.

**Memory — warn before bulk changes:** Always warn and get a nod before consolidating, summarizing, or restructuring memory files in bulk. User wants to stay aware of what's being committed and have control over it.
