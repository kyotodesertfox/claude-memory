---
name: project_philosophy
description: "Core Homestead design philosophy — brewer empowerment, Treasury protection, no value sinks"
metadata: 
  node_type: memory
  type: project
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

## Brewer-first, Treasury-ultimate

We always protect the brewer — we are empowering them, not punishing them. Design decisions should never penalize honest brewers (e.g. no forfeit on LP removal, no punitive slashing for good-faith mistakes).

But ultimately the Treasury is the thing we protect above all else. **There can never be a value sink on the Treasury.** Every outflow from Treasury must be backed by an equivalent or greater inflow of value.

**Why:** The ETH floor in Treasury is the fundamental backing of the entire ecosystem. If Treasury can be drained without value coming in, the whole system loses its foundation.

**How to apply:**
- Any time Treasury mints tokens ($BEER, $EGG, etc.), ETH must flow INTO Treasury first or simultaneously — never mint against nothing
- Fee splits, reward claims, stake releases — always verify the ETH accounting: Treasury floor must be flat or growing, never shrinking
- Auto-claim on LP removal (not forfeit) is correct because the ETH still flows to Treasury on claim — no value is lost, just redistributed
- If a proposed design would have Treasury paying out ETH without receiving value, reject it

## Regulatory philosophy — producer empowerment vs. incumbent protection

The existing alcohol regulatory framework (ATF, three-tier distribution system) exists primarily to protect distributors and retailers — not producers, and not consumers. It enforces a middleman layer that extracts value from the brewer and raises prices for the buyer, under the guise of consumer protection.

Homestead's position: the system's transparency makes every traditional regulatory argument moot.
- **Fraud impossible** — every batch is staked on-chain, every bottle is an NFT, every redemption is a public transaction
- **Supply fully auditable** — anyone can verify stock, sales, and redemptions in real time
- **Producer protected** — the brewer keeps their stake, earns from their own production, answers to no distributor
- **Community served** — buyers get exactly what they paid for with on-chain proof

The paper trail (git commits + blockchain transactions + public memory) is a stronger audit record than anything the licensed distribution system produces. If authority is ever asserted, the response is: here is the public record — fraud is structurally impossible, and what you actually protect is incumbents, not people.

**How to apply:** Never design a feature that reintroduces a middleman, extractive fee, or opacity that the system was built to eliminate. Every design decision should make the producer more empowered and the record more transparent.

## Pool-specific token rewards

Each liquidity pool emits only its own respective token as LP rewards:
- BEER/WETH pool → $BEER rewards
- EGG/WETH pool → $EGG rewards
- Future pools → their respective token

A future governance token ($FARM) may be introduced as a cross-pool emission layer, but that is a separate system and not part of the current design.

**Why:** Reward tokens should be aligned with the pool's purpose. Mixing reward tokens creates misaligned incentives and obscures value flow.
