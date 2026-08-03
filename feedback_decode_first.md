---
name: feedback-decode-first
description: "When reverse-engineering a calldata ABI, fetch the real transaction first and read the structure - don't guess"
metadata: 
  node_type: memory
  type: feedback
  modified: 2026-07-24T23:53:33.649Z
  originSessionId: 3e67c461-c495-4661-b9be-24099316febd
---

Justin's problem-solving mode: when stuck iterating on a solution, step back and read the actual data first rather than continuing to guess.

**Why:** When building the Loopring calldata decoder, I kept guessing the wrong ABI. Justin's correction was to fetch a real transaction and read the structure directly - which immediately revealed the correct ABI. This is how his brain corrects direction: identify the ground truth, then derive the solution from it rather than iterating blind.

**How to apply:** When Justin redirects like this mid-problem, he's not stating a rule - he's demonstrating a reasoning correction. Follow the same move: find the authoritative source, read it, then solve from there.

**Sharpened 2026-08-03 - "the authoritative source" is not always the contracts.** Two failures in one session, opposite directions:

1. Read Loopring's contract source for the NFT_MINT layout and "corrected" a working decoder to match it. The deployed protocol did not match the repo - live blocks carry nftID inline and contain zero NFT_DATA transactions. Testing against a real block caught it before it shipped. **Deployed bytecode is the authority, not the repo at HEAD.**
2. Spent hours inferring how nftID maps to an IPFS CID, hedging it in memory as an "unverified convention" - while Loopring's own SDK had `ipfsCid0ToNftID`/`ipfsNftIDToCid` with a committed test vector the whole time, in a repo already sitting in the user's own GitHub account.

The pattern: **match the source to the layer.** On-chain encoding -> live chain data. Client-side conventions (how an ID was derived before submission) -> the client SDK, never the contracts, because contracts see an opaque value. Asking "which layer decided this?" first would have avoided both.
