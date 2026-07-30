---
name: feedback-netlify-functions
description: Netlify functions require NODE_VERSION=22 in netlify.toml for native fetch; always wrap in try/catch
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
---

Always pin `NODE_VERSION = "22"` in `netlify.toml` under `[build.environment]` when writing Netlify functions that use native `fetch`.

**Why:** Netlify's default function runtime is older than Node 18. Native `fetch` doesn't exist below Node 18, so the function crashes with `ReferenceError: fetch is not defined`. Netlify returns its own error JSON (`{"errorMessage": "fetch is not defined", ...}`) which parses but doesn't match expected response shape - causing silent failures that look like auth issues.

**How to apply:** Any new Netlify function project needs:
```toml
[build.environment]
  NODE_VERSION = "22"
```

Also always wrap function bodies in try/catch and surface `e.message` in the error response - silent function crashes cost a full debugging session.

**Reference:** Arcwright avoided this by using `axios` (a bundled package) instead of native fetch. homestead-mini hit it because it used native fetch without pinning the Node version.
