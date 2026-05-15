---
name: project_arcwright
description: Arcwright welding business website for a neighbor — stack, current state, and pending tasks
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

`kyotodesertfox/arcwright` — welding business site built for free for a neighbor in Jacksonville. Deployed on Netlify at arcwrightwelding.com. Repo lives at **`/home/zenko/github/arcwright/`** (cloned with `--filter=blob:limit=400k --depth 1` to skip 2.6GB of project photos). Pi copy at `~/github/arcwright/` can be deleted.

**Stack:** React 19 + Vite, Framer Motion (`motion/react`), Tailwind v4 with `@theme` custom props (`--color-weld-red: #cc0000`, `--color-weld-silver`, `--color-weld-black`). White content area between dark navbar/footer.

**Pages:** Home (hero + animated Svgator scorpion logo via `<object>` tag), Services, Portfolio (tag filtering, pagination, image carousel modal), Contact (multi-step form, Netlify Forms), Admin, NotFound.

**Admin CMS:** Headless GitHub API CMS — no backend. GitHub OAuth (Netlify function). Session-based branching (`update-YYYYMMDD`). Merges to main on Publish → Netlify auto-deploys in ~1 min. Metadata per project: `public/projects/{slug}/metadata.json` = `{ title, client, description, tags: [], images: {id: altText} }`. Images stored as webp at `{slug}/{id}.webp`. Preset tags: Marine, Alloy, Steel, Aluminum — plus custom tags the welder can create.

**Portfolio data flow:** `/projects/index.json` → if missing, falls back to Unsplash DEMO_PROJECTS. Tags are pulled dynamically from loaded project metadata and build the filter bar. Pagination: 9 per page.

**SEO (current state):** Per-page title + description via React 19 native hoisting. LocalBusiness + HomeAndConstructionBusiness JSON-LD schema. Real og-image.webp (weld photo). theme-color #cc0000. sitemap.xml with lastmod. robots.txt present.

**Pending:**
- Welder needs to go through 100+ date-named folders in admin and set job title + tags for each — only he knows what each job was. Once done, portfolio switches from Unsplash placeholders to real photos automatically.
- og-image: currently a raw weld photo — future upgrade: branded 1200×630 card (scorpion + ArcWright name on dark background) if ever designed.

**Resolved:**
- Pi copy of repo deleted (2026-05-13) — local at `~/github/arcwright/` is the only copy.

**Why:** Built as a favor — not paid, not related to homestead.
