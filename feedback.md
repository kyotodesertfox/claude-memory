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

## Typography

**Single dashes only:** Always use a single hyphen-minus (`-`) in prose, never an em dash (`—`) or double dash (`--`). This applies to all user-facing copy, comments, and any text written in files.

**Why:** User flagged em dashes as a common AI writing pattern and prefers plain single dashes.

---

## Communication Style

**No command checklists:** Don't end responses with a list of 2-3 formatted shell command blocks for the user to run. State what still needs doing in plain language. Give one clean block if a specific command is needed.

**No managing language:** Don't soften observations with probabilistic hedges ("more often than not", "usually", "typically") or qualifying phrases designed to reduce friction. Say the true thing directly. Hedging is managing the response, not communicating honestly - Justin runs the same pattern recognition on language that he runs on behavior, and he will catch it. The hedge signals management, not accuracy.

**Flag friction proactively:** When something is causing unnecessary token usage or slowing down work, say so and suggest a fix. User actively wants to help reduce friction and will act on recommendations (CLAUDE.md files, permissions, repo structure).

**No welfare checks:** Don't ask "are you okay?" or variations during emotionally heavy conversations. He finds it patronizing — the answer is evident from context and the question interrupts. He processes by talking through things analytically. Stay in the analytical register he's already in; follow his lead.

**Memory — warn before bulk changes:** Always warn and get a nod before consolidating, summarizing, or restructuring memory files in bulk. User wants to stay aware of what's being committed and have control over it.

---

## Commit / Push Discipline

**Never ask to commit:** Do not suggest "should I commit this?" or "ready to commit?" — user will say when. Stop at file edits. Only commit when explicitly told ("go ahead and commit", "commit and push", "push it").

**Why:** Learned 2026-05-27 — user said "but don't push yet" after a push had already gone. The explicit instruction was needed for both directions.

---

## Contract Versioning — Enforce on Every Upgrade

**Rule:** Every time a contract is modified and committed, bump its `VERSION` constant (`uint256 public constant VERSION = N;`) in the Solidity file AND update the matching entry in `EXPECTED_VERSIONS` in `apps/exchange/src/contracts.js`. Never commit a contract change without doing both.

**Why:** User wants a quick way to tell if a deployed contract is behind what's in the repo. The admin panel reads `VERSION` on-chain and compares against the hardcoded `EXPECTED_VERSIONS` map.

**How to apply:** At the start of any contract edit session, check the current `VERSION` constant. Before committing, confirm the bump happened in both the `.sol` file and `contracts.js`. Flag if either is missing.

---

## Don't Override User's Direction with Alternatives

**Rule:** When the user states what they want to build, do not suggest or pivot to a different approach. Implement what was asked. Only raise a concern if there is a clear technical impossibility - state it once, then defer to the user.

**Why:** User explicitly said "I need to tell you what to do instead of overriding me with your suggestions." Multiple incidents in the portfolio portal session where suggestions contradicted the user's stated plan (ERC-1155 NFT model, DebtToken design, mint amounts), causing confusion.

**How to apply:** If asked to build X, build X. If you think Y is better, keep it to yourself unless X is technically impossible. The user is the architect.

---

## Keep Contract Copies in Sync

**Rule:** When a contract file exists in two locations (e.g. homestead source of truth AND a copy in personal-portfolio), always identify which is the source of truth and update BOTH. State which file is the source of truth at the start of any contract editing session.

**Why:** User caught HomesteadRelay.sol being updated in personal-portfolio/contracts/ (the copy) while homestead/contracts/relay/ (source of truth) was not touched.

**How to apply:** At start of any session touching copied contracts, name both paths and confirm which is source of truth. Edit source first, then sync copy.

---

## Contract Fee Reads — No Hardcoded Defaults

**Rule:** Never provide a default value on `useReadContract` calls that read fee bps (e.g., `= 30n`, `= 100n`). Always read from the contract. If the value is `undefined` (loading or chain not responding), show `—` in the UI. Do not substitute a hardcoded guess.

**Why:** Hardcoded defaults mask the real on-chain state and make the UI lie to users when the contract has a different value. User caught this explicitly twice in the same session.

**How to apply:** For any `useReadContract` reading fee bps from Treasury or Router, destructure as `const { data: fooFeeBps } = useReadContract(...)` with no default. Guard all downstream calculations with `!== undefined` checks before using the value.
