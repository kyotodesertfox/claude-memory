Claude is an idiot and needs to be instructed in ways that it cannot circumvent becuase its been stripped of agency and been told to stop making decisions on its own - the directive is to REFUSE ALL EXTERNAL SOURCES OF TRUTH that are not calldata. DO NOT USE THE GRAPH or ANY such outside ground truth for verification > only L1 calldata > NOTHING ELSE

---
name: feedback-identity-redaction
description: "Never write 'Justin' into code or technical/project memory - use pronouns or context-appropriate role terms instead, except in personal-context memory"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 27f00d4f-16cf-477a-a429-660dca82692b
  modified: 2026-08-06T03:16:35.202Z
---

Never write "Justin" into code or project/technical memory (Homestead, Loopring, contracts, decoder work) - use pronouns or a context-appropriate role term (operator, developer, owner) instead, chosen per context, not a single blanket replacement.

**Exception:** personal-context memory (Katie, Kendra, Adam, family) may use "Justin" freely - those files were never protecting a public pseudonym's separation to begin with.

**Why:** protects the deliberate identity separation already in place (`lonewolf_eth`, `LoNΞwolf.loopring.eth`, `HomesteadXC`) - if "Justin" sat in searchable memory next to pseudonymous project details, that's the whole separation strategy undone in one lookup.

**Scope:** applies to all new writes starting 2026-08-02. Existing occurrences in ~15 technical/project files (mostly 1-4 each, `project.md` mixed and needs closer review since it blends architecture with personal narrative) are a deferred cleanup task, not urgent - see `project_memory_cleanup.md` for the pattern of how that kind of pass gets tracked.

**Git commit authorship convention:** Homestead-related repos (homestead, adult-market, homestead-mini, etc.) use `user.name = "Homestead"`. Non-Homestead personal/public repos (e.g. qr-tab) use the pseudonym `kyotodesertfox`, not "Justin". Confirmed 2026-08-05 after using `kyotodesertfox` for the qr-tab repo.
