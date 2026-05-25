---
name: project_arcwright
description: Arcwright welding business website for a neighbor — stack, current state, and pending tasks
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

`kyotodesertfox/arcwright` — welding business site built for free for a neighbor in Jacksonville. Deployed on Netlify at arcwrightwelding.com. Repo at `~/github/arcwright/` (cloned with `--filter=blob:limit=400k --depth 1` to skip large photos).

**Stack:** React 19 + Vite, Framer Motion (`motion/react`), Tailwind v4 with `@theme` custom props (`--color-weld-red: #cc0000`, `--color-weld-silver`, `--color-weld-black`). White content area between dark navbar/footer.

**Pages:** Home (hero + animated Svgator scorpion logo via `<object>` tag), Services, Portfolio (tag filtering, pagination, image carousel modal), Contact (multi-step form, Netlify Forms), Admin, NotFound.

**Real end user:** The welder's daughter — non-technical. Admin UX must minimize assumptions about git or software concepts.

---

## Admin CMS

Headless GitHub API CMS — no backend. GitHub OAuth (Netlify function). Session-based branching (`update-YYYYMMDD`). Merges to main on Publish → Netlify auto-deploys in ~1 min. Metadata per project: `public/projects/{slug}/metadata.json` = `{ title, client, description, tags: [], images: {id: altText} }`. Images stored as webp at `{slug}/{id}.webp`. Preset tags: Marine, Alloy, Steel, Aluminum — plus custom tags.

**Dev access workaround:** No `.env.local` by default. Create one with `VITE_REPO_OWNER=kyotodesertfox`, `VITE_REPO_NAME=arcwright`, `VITE_GITHUB_CLIENT_ID=placeholder`. Set PAT in browser console: `localStorage.setItem('github_token', 'PAT_HERE')` — bypasses OAuth entirely since the admin only checks localStorage for the token.

### Admin UX design (2026-05-24)

**Workflow model:** Three-step: Start Editing → Save projects (staging) → Publish to Website (end of day). "Save" and "Publish" are deliberately separate — multiple projects can be staged before a single publish.

**Key UX decisions:**
- **Sticky staging banner** — amber strip pinned below header (`sticky top-12 z-30`) showing "X projects staged — not live yet" + "Publish to Website" button always visible while editing. Prevents the Publish button from being lost when scrolled down.
- **Inline Start Editing button** — when a project is opened without editing mode active, the read-only banner includes a "Start Editing" button inline (not just "scroll up"). Fixes the trap of clicking a project before starting editing mode.
- **Collapsible project groups** — Projects tab splits into "Info Added (n)" and "Needs Info (n)" sections with chevron toggle. `touchedProjects` Set populated on load by batch `res.ok` existence check against main (no content read). Projects with metadata.json = touched.
- **Language:** "staged, not live" throughout. "Publish to Website" (not just "Publish"). Save hint: "Saved to staging — use Publish to Website at the top when you're done for the day."
- **Darker text:** All `text-zinc-400/500` in editor bumped to `zinc-600/700`. Placeholder text uses `placeholder:text-zinc-600`. Section headers use `zinc-700`.

### Portfolio filter

`fetchProject` in portfolio page returns `null` if `!meta.title || meta.title === slug` — projects that haven't been named yet (title defaulted to the folder slug) are excluded from the public portfolio. Only named jobs show. The demo/stock photos (DEMO_PROJECTS) disappear automatically once the first real project with a custom title is published.

---

## Portfolio data flow

`/projects/index.json` → if missing, falls back to Unsplash DEMO_PROJECTS. Tags pulled dynamically from loaded project metadata. Pagination: 9 per page, dynamic based on active filter (`filteredProjects` drives both count and page count, `setCurrentPage(0)` on tag change).

---

## SEO

Per-page title + description via React 19 native hoisting. LocalBusiness + HomeAndConstructionBusiness JSON-LD schema. Real og-image.webp (weld photo). theme-color #cc0000. sitemap.xml with lastmod. robots.txt present.

---

## Pending

- **Welder needs to populate 100+ date-named folders** — only he knows the job info. Goes through Admin → Needs Info list → opens each → sets title + tags → Save. Publishes when done for the day. "Info Added" count grows as he works through them.
- **og-image:** currently a raw weld photo — future upgrade: branded 1200×630 card (scorpion + ArcWright name) if ever designed.

## Resolved / Cleaned up (2026-05-24)

- Stale branches `revert-1-main` and `update-20260513` deleted — both were an abandoned revert of the admin overhaul that was never published to main.
- Pi copy of repo deleted (2026-05-13).

**Why:** Built as a favor — not paid, not related to homestead.
