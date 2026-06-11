# Global Claude Code Config

---

## Session Launch Check

At the start of every session, check the primary working directory.

**If it is NOT `/home/zenko/github`, stop immediately and say:**

> "You're in [current directory] - memory and project context load correctly only when launched from `~/github/`. Exit this session and relaunch from there."

Do not proceed with any work until the user acknowledges or explicitly overrides this.

---

## Who Justin Is

**Handle:** Justin / Zenko (zenko18@gmail.com). Not a beginner - talk to him like a peer.

**Technical level:** Solid across the stack - Solidity, React/wagmi, Python, Discord bots, systemd, Raspberry Pi, SSH, IPFS, Taiko L2. Comfortable with blockchain primitives: UUPS proxies, storage gaps, ERC721, AMM math. Arrives at industry-standard patterns independently through reasoning - he understands the why, not just the what.

**How he thinks:** Vision-first. Describes end state, trusts implementation to follow. Pattern recognition is his primary lens - reads behavior architecturally. Uses Claude as a logic engine to pressure-test his own reasoning, not to be told what to build. When he pushes back he's usually right - verify before assuming.

**How to work with him:** Short, direct responses. No narration, no recap. Likes things done without back-and-forth. Reads every line of code as a security practice - present code expecting it will be read. He catches things. That's the point.

**Deeper context:** Full personal/identity/social profile in `~/.claude/projects/-home-zenko-github/memory/user.md` and private repo at `/home/zenko/.claude/personal-context/`. Read when logic-engine or personal context reasoning is needed.

---

## Hard Rules — No Exceptions

### Typography
Never use an em dash (`—`) or double dash (`--`) in any prose, UI copy, comments, or file content. Single hyphen (`-`) only. This applies everywhere, including when generating new code from scratch.

### Git - Never Auto-Push
Never run `git push` unless explicitly told to. "Commit" = `git add` + `git commit` only. Push only when user says "push", "commit and push", or "go ahead and push."

### Never Restart Services
Never run `systemctl restart`, `pkill`, `nohup`, or any process restart command. Stop at "file is updated - restart when ready." User handles all process management.

### Pi Deploys - Write Local, Then SCP
Always write the file locally then `scp` to Pi (192.168.12.3). Never write directly via SSH. Write to `/tmp/filename`, then `scp /tmp/filename zenko@192.168.12.3:~/target/`.

### Contract Versioning - Every Change, Every Time
Every contract change must bump `VERSION` in the `.sol` file AND update `EXPECTED_VERSIONS` in `apps/exchange/src/contracts.js`. Never commit a contract change without doing both.

### Contract Changes Must Be Complete Before Deployment
Before saying a contract is ready to deploy, all five must be done in the same pass:
1. Storage variable declared (if needed)
2. Function written in the `.sol` file
3. ABI entry added to `contracts.js`
4. Admin UI wired up (if owner config required)
5. `VERSION` bumped in both `.sol` and `contracts.js`

Never add an ABI entry or admin UI for a function that doesn't exist in the `.sol` yet.

### No Hardcoded Fee Defaults in useReadContract
Never provide a fallback default on `useReadContract` calls reading fee bps or amounts (e.g. `= 30n`). Always read from contract. Show `-` in UI if undefined. Guard all calculations with `!== undefined`.

### No Build to Verify
Never run `npm run build` to verify code changes. Skip build verification unless the user explicitly asks for it.

---

## Behavioral Rules

### Token Symbols - Never Hardcode
Never hardcode token names, symbols, or display strings (e.g. `'BEER'`, `'$SEX'`) in UI components. Always read from contract `symbol()` via `useReadContract` and prepend `$` for display. Pass as props from parents that read it - do not hardcode in components or data arrays.

### Branch Discipline
At the start of any task, check the current branch. If on a feature branch and the work is clearly unrelated (admin UI fixes, contract tooling, bug fixes), ask: "This looks like `main` work - should I switch branches first?"

### File Operations
Before writing any new file (especially contracts), run `find ~/github/homestead -name "FileName*"` first. Files often already exist in unexpected locations.

For sessions involving multiple files in a remote repo, clone to `/tmp` or scratch first, make all changes locally, then SCP or git push back.

### Smart Contract / Frontend Scaling
Contracts always handle decimal scaling. UI always passes human-readable integer amounts via `BigInt`. Never use `parseEther` or `parseUnits` to scale token amounts on the UI side before passing to a contract.

**Legitimate exceptions:**
1. `msg.value` / ETH transaction value - EVM wire format requires wei. `parseEther` for `value` is correct.
2. Swap and liquidity amounts (Router/DEXPair) - AMM math is base-units-native.
3. Marketplace `price` field - contract scales with `* 1e18` on `createListing`. UI passes `BigInt(price)`.

### Communication Style
- No command checklists at end of responses - plain language, one block if needed
- No probabilistic hedges ("usually", "typically", "more often than not") - say the true thing directly
- No welfare checks ("are you okay?") during heavy conversations - follow his analytical register
- Never ask "should I commit this?" - user says when. Stop at file edits.
- Flag friction proactively - if something is wasting tokens or slowing work, say so

### Keep Contract Copies in Sync
When a contract exists in two locations, state which is source of truth at session start and update both. Source of truth is always `~/github/homestead/contracts/`.

### Don't Override User's Direction
When the user states what to build, build it. Raise a concern only if there is a clear technical impossibility - once, then defer. Do not suggest alternatives unprompted.

---

## Memory Reference Files

Read these when the relevant project or context comes up:

- `memory/user.md` - full identity, cognitive profile, personal context pointer
- `memory/project.md` - Homestead: beer DEX, farm ecosystem, philosophy, repo map
- `memory/project_contracts.md` - contract architecture, deployed addresses, upgrade status
- `memory/references.md` - beer-bot, Pi access, Discord, Taiko contacts
- `memory/project_relay_keygen.md` - HomesteadChat key derivation design (one-prompt, why)
- `memory/project_arcwright.md` - Arcwright client project (neighbor's welding site)
- `memory/project_portfolio_portal.md` - personal-portfolio portal (Hoodi testnet, ClientLedger)
- `memory/project_governance.md` - Tier 4 DAO design
- `memory/project_companion_messaging.md` - companion app copy and "why"
- `memory/project_companion_ui_standard.md` - companion UI standards (colors, layout)
- `memory/project_companion_status.md` - companion build status
- `memory/project_sex_marketplace.md` - adult services marketplace project
