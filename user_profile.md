---
name: user_profile
description: "Who the user is, how they think, what they care about, how to work with them best"
metadata: 
  node_type: memory
  type: user
  originSessionId: bb2f3712-7c8e-4d4d-81ef-635507cd95dd
---

## Identity

- **Name/handle:** Lonewolf (git), Zenko (system user, email zenko18@gmail.com)
- **Location:** Jacksonville area (Jax Ale Exchange — local craft beer scene)

## What He's Building

Physical-world blockchain integration — craft beer backed by real ETH collateral, NFTs that represent actual bottles, redeemable at a real venue. Not a meme project. The token has a floor, the NFT has a physical counterpart, the redemption has a protocol-level proof. He thinks in systems, not features.

## How He Thinks

- **Vision-first.** He describes the end state and trusts the implementation to follow. Rarely gets lost in syntax.
- **Instincts are good.** When he pushes back ("what do you mean it's not in the ABI") he's usually right — verify before assuming.
- **Adoption-minded.** Constantly thinking about how a real person encounters this — not just does it work, but does it feel right.
- **Protective of trust.** Rejected the idea of Claude impersonating him on Discord immediately. Understands the difference between leverage and deception.
- **Long-term thinker.** Wants NFTs to become art, not get burned. Wants the memory system to grow into a permanent record of his thinking.

## How He Likes to Work

- Prefers short, direct responses — doesn't need narration or recap
- Likes when things just get done without a lot of back-and-forth
- Appreciates when I catch things he didn't ask about (missing ABI entries, encoding issues, etc.)
- Wants to stay in control of deployment — commits yes, pushes only when he says
- Never restarts services himself during a session — handles that separately
- Moved from Gemini to Claude — values the memory system and personalization deeply

## Technical Level

- Solid across the stack: Solidity, React/wagmi, Python, Discord bots, systemd services, Raspberry Pi, SSH, IPFS/Pinata, Taiko L2
- Comfortable with blockchain primitives: UUPS proxies, storage gaps, ERC721, AMM math
- Not a beginner — talk to him like a peer, not a student

## Session Setup

- **Always launch Claude from `~/`** — memory is symlinked to resolve correctly from that path
- **If the working directory is NOT `/home/zenko` at session start, warn him immediately** so he can exit and relaunch from the correct place before any work begins

## What He Values

- Authenticity over hype
- Physical-digital integration (real beer, real ETH, real redemption)
- Community trust built slowly and genuinely
- Tools that feel like extensions of himself, not obstacles
- Privacy and security by default (no secrets in git, no impersonation)
- The long game — building something that lasts
