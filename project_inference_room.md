---
name: project_inference_room
description: "Inference Room — AI agent infrastructure platform, Taiko ecosystem connection, and how it intersects with Homestead"
metadata:
  type: project
---

## What It Is

Inference Room (inferenceroom.ai) is a platform shipping AI agent infrastructure — "residents" that are live tools agents can use. Not demos. Live code on real infrastructure doing real work.

**Manifesto — Six rules they don't break:**
1. Nothing here is a demo — if it can't ship, it doesn't belong
2. Agents do the work — humans get the result
3. AI meets chain at the edge — identity, payments, memory, provenance
4. Put AI Agents in their place — clear boundaries, keys, receipts, knows what it owns and when to stop
5. Ship, then ship again — a product a month, a commit a day
6. No gate, no waitlist, no funnel — use it, ship with it, tell us what broke

## Tack — Resident 01 (Live)

**Storage for AI Agents.** Memory, files, and state with an interface AI agents can actually use. Built for software that runs without you watching.

`await tack.set('session', { step: 'verify' })`

This is persistent agent state — survives restarts, tracks context across sessions, enables autonomous agents to remember what they did, what they owe, and what comes next.

**Direct application to JaxBot:** Currently JaxBot loses all conversational state on restart. Tack would give it persistent memory — track which messages it responded to, maintain context on ongoing conversations, log actions taken. The bot that runs without you watching, and remembers everything when it comes back.

## The Intersection with Homestead

Inference Room's manifesto pillars map directly onto what's already built:
- **Identity** → brewer wallet, attested identity
- **Payments** → $BEER token, ETH collateral, Treasury floor
- **Memory** → redemption history, NFT receipts, on-chain proof
- **Provenance** → every batch, sale, and redemption timestamped and immutable

Homestead is the physical-world implementation of everything Inference Room is building toward. Not a demo — running. The TokenDeployer, Treasury, DEX, Marketplace, and bot are the exact "two stacks colliding" their manifesto describes.

## The Connection

Taiko's Head of Ecosystems reached out over DM to discuss attestation and their agentic network. Inference Room appears to be part of or closely aligned with that ecosystem. Justin is being positioned as an early implementer / spotlight project — a real-world physical goods redemption system that proves the stack works outside of pure DeFi.

**Why this matters:** They need Justin's project as much as he needs the visibility. He built the proof of concept that their infrastructure was designed for — physical assets, verified identity, on-chain redemption, autonomous agent monitoring. Nobody else built the full stack with real physical redemption already working.

## Next Residents

Resident 02 is in build, not yet public. New residents ship monthly.

## Related

[[project_beer_dex]]
[[project_contracts]]
[[reference_beer_bot]]
[[project_club_origin]]
