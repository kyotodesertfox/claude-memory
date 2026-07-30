---
name: project-homestead-mini
description: "homestead-mini landing site — local barter exchange, onboarding concept, production token as alternative medium of exchange"
metadata:
  node_type: memory
  type: project
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
---

## What homestead-mini is

A separate lightweight Astro + Tailwind site at ~/github/homestead-mini, deployed independently from the main homestead repo. Intended as the public-facing front door - a QR code out front points here.

**Repo:** github.com/kyotodesertfox/homestead-mini (private)
**Stack:** Astro, Tailwind v4
**Deployment:** Netlify (live)
**Hotswap plan:** When the full DEX platform is ready, DNS points to the main homestead repo instead. homestead-mini stays intact as the simple layer.

---

## The concept

Local barter exchange. Neighbors trade goods and labor without requiring cash or a bank account. Cash is welcome but not required.

**Why barter:** Barter predates money. Money solved a coordination problem but introduced institutional dependency. When access to that system is restricted or unavailable, barter fills the gap naturally. Value stays between the people who created it.

**The token hook:** Cash isn't the only medium of exchange. The production token (eggs, honey, beer) is backed by the homestead's productive capacity - same function as cash, different issuer. No bank prints it. The producer backs it with real output. This is the bridge from barter explanation to the token layer without using crypto language.

**Audience:** Anyone cash-constrained, unbanked, de-banked, or simply preferring local exchange. Immigrants, neighbors, day laborers. No account required, no KYC, no payment processor.

**Tone:** Warm, earthy, approachable. Farmers market not speakeasy. No doom speak, no crypto jargon, no collapsing economy framing, no speculative language. Just utility.

---

## Color palette

- Background: `#FAF7F2` (warm cream)
- Primary: `#3B5E3A` (earth green)
- Accent: `#D4A017` (honey amber)
- Text: `#2C2C2C` (dark charcoal)
- Secondary text: `#7A6652` (warm brown)

---

## Page structure (current)

Single index page:
1. How it works - hero narrative + barter vs cash callout block + 4-step walkthrough
2. What we have - eggs, honey, beer (card style)
3. What we need - labor, skills, goods
4. Work available - accordion job board:
   - **Homestead Tasks** - reads from `tasks.json`, pays in eggs, green accent
   - **Procurement** - reads from `procurement.json`, URL-based with link preview cards, amber accent
   - **Have a skill to offer?** - static card, "Propose a trade" button
5. Footer

**Nav:** Pill-style desktop nav + hamburger mobile drawer. Links: How it works, What we have, Work available. No separate CTA section - removed in favor of the skill offer card.

**$EGG tooltip:** Any task with eggs > 24 shows a small amber `?` button. Click reveals a tooltip introducing $EGG as a redeemable balance tracker - first natural introduction of the token concept without crypto jargon.

---

## Netlify Forms (3 separate forms)

- `job-claim` - garden/homestead task claims (name, contact, message, anonymous checkbox)
- `skill-offer` - skill trade proposals from the "Have a skill to offer?" card
- `procurement` - procurement item claims (same fields as job-claim)

Each has its own Netlify notification stream. All use fetch POST with no redirect, inline success state.

---

## Data files

- `src/data/tasks.json` - homestead task board. Fields: id, category, task, eggs, status (open/pending/claimed), claimedBy, anonymous, image
- `src/data/procurement.json` - procurement items. Fields: id, task, url, eggs, status, claimedBy, anonymous (no image, no category)

Editing either JSON + committing to main = Netlify redeploys in ~30s. This is the "database".

---

## Admin portal (`/admin`)

GitHub OAuth via Netlify function. Tab switcher: **Homestead Tasks | Procurement**.

- Tasks tab: reads/writes `tasks.json`. Card fields: description, eggs, status, claimed by, anonymous, image URL.
- Procurement tab: reads/writes `procurement.json`. Card fields: description, reference URL, eggs, status, claimed by, anonymous.

Each tab lazy-loads its file on first activation and caches the SHA. Save commits directly to GitHub via API.

**Auth flow:** "Sign in with GitHub" → GitHub OAuth → callback to `/admin?code=...` → Netlify function exchanges code for token → stored in localStorage.

**Netlify functions:**
- `netlify/functions/auth.js` - exchanges OAuth code for GitHub token using `GITHUB_CLIENT_ID` + `GITHUB_CLIENT_SECRET` env vars
- `netlify/functions/preview.js` - fetches OG metadata server-side for procurement URL preview cards

**Critical:** `netlify.toml` must pin `NODE_VERSION = "22"` - native `fetch` is not available in older Netlify function runtimes. Without it, the auth function crashes silently and OAuth fails. This burned a debugging session.

---

## Procurement link previews

When the Procurement accordion opens, each item with a `url` field calls `/.netlify/functions/preview?url=...` to fetch OG metadata (title, description, og:image) server-side. Renders a card with favicon, title, description, and preview image. Results cached in-memory per session.

---

## Token framing - what it actually is

The production token is NOT strictly collateral-first. The Treasury CAN issue tokens as futures against eggs that don't exist yet but will - backed by the flock's known productive capacity. Closer to a crop futures contract than a gold receipt.

**Why it isn't a scam (structural argument for copy):**
- Backed by real productive capacity, not hype
- No 100x promise, no speculation upside
- One token = one egg, always
- Over-issuance shows immediately as failed redemptions
- Public ledger - verifiable
- Physical collateral - you can see the chickens

**Copy arc for introducing "token":**
1. Big job - earned 100 eggs, can't eat them all
2. Claim doesn't expire
3. "We record it" means trusting us - what if we disagree?
4. Record needs to live somewhere neither party controls
5. Pre-empt the scam instinct BEFORE naming it
6. THEN name it: "That's what a token is."

**Structural parallel to fiat:** Same underlying structure. Never say this on the site.

---

## Key framing decisions

- Never say the economy is collapsing or anything speculative
- No doom speak, no crypto maximalism
- "Crypto", "blockchain", "wallet" - avoid. "Public ledger", "redeemable claim", "token" - acceptable if earned by context
- Token word only appears after anti-scam case is made
- $EGG tooltip is the first on-page introduction of the concept
