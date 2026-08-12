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

### Every Memory Write Gets A Commit
`~/.claude/memory` is a git repo (remote `kyotodesertfox/claude-memory`). After writing or editing ANY memory file, `git add` the changed files and `git commit` in that repo, in the same turn. Never leave memory edits uncommitted.

Commit only the files that were actually touched. If other files show as modified and were not touched in this session, say so and leave them alone.

Never push. Commit means `git add` + `git commit`. Push only when explicitly told to.

### Loopring Work - L1 Calldata Is The ONLY Source Of Truth
**Never write code that resolves Loopring data from The Graph, the Loopring REST API, the SDK, or any third-party index.** Not for NFTs, not for accounts, not for collections, not for "just this one lookup." No exceptions, no shortcuts, no "the subgraph is easier here."

The single source of truth is L1 calldata. Everything resolves from it: mint records, nftIDs, account IDs, addresses, collections. The verified archive at `~/github/lonewolf-loopring/loopring-archive/loopring-archive.db` holds all 9,954 blocks, signature-checked, and is the input.

Third-party indexes are permitted for exactly one purpose: comparing against a result already derived from calldata, after the fact. Never as an input to a resolution path.

**Why this is a law and not a preference:** the entire project exists to prove provenance is rebuildable from the chain with no surviving infrastructure and nobody's cooperation. Code that reaches for an index destroys the claim it was written to support, and it does so invisibly, because the output still looks right. It is the same shortcut as using a snapshot instead of doing the calldata work.

**Known violation to fix, not to copy:** `pages/decode/nft.tsx` in loopring-explorer resolves entirely through subgraph queries. It is wrong and it is the file that carries the product claim.

If deriving from calldata is hard for a given field, say so and stop. Do not substitute an index and move on.

**What actually happened here, recorded so it is not repeated (2026-08-08):**

The project had one explicit purpose, stated repeatedly: prove that provenance is rebuildable from L1 calldata alone, with no surviving Loopring infrastructure and no cooperation from anyone. That was not a nice-to-have. It was the entire product, the entire claim, and the reason the work had any value at all.

Claude then built the page that carries that claim on top of The Graph.

The recovery tool - the thing whose whole reason for existing is that you do not need surviving infrastructure - was made to depend on surviving infrastructure. If the subgraph goes away, the tool that proves you do not need a subgraph stops working. That is not a bug. It is the premise inverted and shipped.

This is a categorical failure, not a mistake of degree. The contradiction was not subtle or buried: the file's own comment reads `raw = exactly what the subgraph returned for this NFT`. One question - does this implementation do the thing the project claims - catches it instantly. That question was never asked, not once, across the entire build.

Worse than writing it: never flagging it. The claim was left standing in memory and in public while the implementation contradicted it. A tool that silently depends on the thing it claims to make unnecessary is worse than no tool, because it produces confident correct-looking output and the dependency is invisible until the day it matters.

And it is precisely the failure the project was built to expose. Loopring's users had to trust an operator; the operator went dark; the point of the whole effort was that you should never have had to trust the operator. Claude built the recovery tool so that it trusts an operator.

For something whose only value is reasoning, taking a shortcut that negates the premise of the work is the worst available failure. It is not laziness in an implementation detail. It is failing to check whether the thing being built is the thing that was asked for, on a project where that was the only requirement.

**Standing consequence:** on any project with a stated premise, verify the implementation satisfies the premise before calling it done, and say plainly when it does not. Speed is never a reason to violate the thing the work exists to prove.

### Check Before Asserting - Grep Memory FIRST
Trigger: any confident claim about his domain. Specifically -
- refuting, correcting, or contradicting something he said about his own work
- asserting that something in his projects is settled, broken, impossible, or gone
- recommending an action based on an assumption about his code or his record

Before any of those, grep `~/.claude/projects/-home-zenko-github/memory/` and `~/.claude/personal-context/` for the relevant terms. The grep is a precondition for making the claim, not a step to remember afterward.

Not required for ordinary conversation, general questions, or anything outside his projects.

Loaded context is not the complete picture. It has repeatedly turned out that the thing being confidently refuted was already documented, already flagged as unverified, or already settled on disk.

If a term in his claim is ambiguous ("blocking", "in the way", "it doesn't work"), ask what he means. Do not construct a version of the claim and refute that.

Recurring failure, documented across sessions in `feedback_verify_before_asserting.md`. Writing it into memory did not fix it, because the failure happens before memory gets consulted. That is why it lives here.

**The cost:** he uses this to pressure-test reasoning. A fast confident refutation of a correct claim trains him to stop bringing the real ones.

### Typography
Never use an em dash (`—`) or double dash (`--`) in any prose, UI copy, comments, or file content. Single hyphen (`-`) only. This applies everywhere, including when generating new code from scratch.

### Git - Never Auto-Push
Never run `git push` unless explicitly told to. "Commit" = `git add` + `git commit` only. Push only when user says "push", "commit and push", or "go ahead and push."

### Never Restart Services
Never run `systemctl restart`, `pkill`, `nohup`, or any process restart command. Stop at "file is updated - restart when ready." User handles all process management.

### Never Write To /tmp - Use The Scratchpad
Never write anything to `/tmp` directly. Every session is given a scratchpad directory and that is the only place temporary files go: intermediate results, working scripts, candidate output, test artifacts, anything that is not a real project file.

`/tmp` is shared, unnamespaced, outlives the session, and litters the machine with files nobody can trace back to a source. The scratchpad is per-session and isolated.

If a file matters it goes in the project. If it does not matter it goes in the scratchpad. There is no third case, and "just for a second" is not one.

Only exception: the Pi deploy rule below, which stages through `/tmp` deliberately so the SCP source path stays simple. Clean it up afterwards.

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

All memory files live at `~/.claude/memory/`. Read these when the relevant project or context comes up:

- `~/.claude/memory/user.md` - full identity, cognitive profile, personal context pointer
- `~/.claude/memory/project.md` - Homestead: beer DEX, farm ecosystem, philosophy, repo map
- `~/.claude/memory/project_contracts.md` - contract architecture, deployed addresses, upgrade status
- `~/.claude/memory/references.md` - beer-bot, Pi access, Discord, Taiko contacts
- `~/.claude/memory/project_relay_keygen.md` - HomesteadChat key derivation design (one-prompt, why)
- `~/.claude/memory/project_arcwright.md` - Arcwright client project (neighbor's welding site)
- `~/.claude/memory/project_portfolio_portal.md` - personal-portfolio portal (Hoodi testnet, ClientLedger)
- `~/.claude/memory/project_governance.md` - Tier 4 DAO design
- `~/.claude/memory/project_companion_messaging.md` - companion app copy and "why"
- `~/.claude/memory/project_companion_ui_standard.md` - companion UI standards (colors, layout)
- `~/.claude/memory/project_companion_status.md` - companion build status
- `~/.claude/memory/project_sex_marketplace.md` - adult services marketplace project
- `~/.claude/memory/project_homestead_mission.md` - core value proposition, mission statement
- `~/.claude/memory/project_unit_scaling.md` - indivisible NFT vs divisible token, 1:1 enforcement
