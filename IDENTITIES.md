# SSH / GitHub identity map

`~/github/` is foldered by identity - the parent directory IS the identity scope. If a repo lives under `~/github/<identity>/`, that is the account and key it belongs to.

| Host alias | GitHub account | Key file | Repo root |
|---|---|---|---|
| `zenko18` (also plain `github.com`, the default) | kyotodesertfox | `~/.ssh/zenko18` | `~/github/kyotodesertfox/` |
| `lonewolf-loopring` | lonewolf-loopring | `~/.ssh/lonewolf-loopring` | `~/github/lonewolf-loopring/` |
| `192.168.12.3` | n/a (not GitHub) | `~/.ssh/internal` | Raspberry Pi, internal network only |

Only these two identity folders exist at the top level - there is no third bucket.

## kyotodesertfox (`~/github/kyotodesertfox/`)

homestead, homestead-mini, personal-portfolio, arcwright, adult-market, beer-bot (remote repo name: `discord-beer-bot`), qr-tab, popup-zapper

Chrome extensions (`qr-tab`, `popup-zapper`) both live here, public repos, moved in from the `~/github` root on 2026-08-09.

## lonewolf-loopring (`~/github/lonewolf-loopring/`)

loopring-explorer, IceCreamShoppe

Cloned locally no longer, but the repos still exist on GitHub: `Marketplace-Web` (Next.js frontend for the Hekla deployment) and `DEX` (Solidity suite - Factory/Router/DexPair/Marketplace/UpgradeableBeacon). Local clones deleted 2026-08-02, uncommitted deltas discarded deliberately; committed history is intact on GitHub. Re-clone with the `lonewolf-loopring` alias, not `github.com`.

Also here, not git repos: `deploy-sepolia` (Hardhat harness for the self-sovereign Sepolia operator - holds a live `.env`, plus `keygen_cmd.sh`, `initialize_args.txt`, and `register_circuit.md` moved in from the `~/github` root on 2026-08-02), `artifacts` (Solidity build output for IceCreamShoppe/ArtMarketplace), `.deploys` (Remix pinned contracts, chain 167013 Hekla), `.deps` (Remix dep cache).

`~/github/` root holds nothing but the two identity folders - no loose files, no loose secrets. Keep it that way.

## upstream (`~/github/lonewolf-loopring/loopring-explorer/upstream/`)

`protocols`, `protocol3-circuits` - clones of the official **Loopring org** repos over HTTPS. Neither identity, no push access, read-only reference. They live inside loopring-explorer because that is the only project that consumes them, but they are NOT lonewolf-loopring's code - do not attribute or push.

~2.0G, excluded from loopring-explorer's git via `.git/info/exclude` (local-only, so the tracked `.gitignore` stays clean). If the dev server ever gets slow or hits an inotify watch limit, this nested tree is the first thing to suspect.

## Gotchas

- Remote URL formats are inconsistent across repos (`git@github.com:`, `git@zenko18:`, bare `zenko18:`). A remote pointing at plain `github.com` resolves to the **zenko18** key - if that repo belongs to lonewolf-loopring, it pushes with the wrong identity. `marketplace` had exactly this bug; fixed 2026-08-02.
- No secrets in this file. PAT locations live in per-project memory (`project_loopring_revival.md`) and `~/.dms/.pat_*`.
