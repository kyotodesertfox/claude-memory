---
name: project-relay-keygen
description: Design decision for HomesteadChat encryption key derivation — why the sign message is structured the way it is
metadata: 
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

# HomesteadChat Key Derivation Design

The encryption private key is derived from a wallet signature:

```js
sig     = sign(`Homestead Key Registration:${address}`)
privKey = keccak256(sig)
```

## Why this structure

**The ECDSA signature is the salt.** The signed message doesn't need to be secret or random — only the wallet's private key can produce that specific signature. `keccak256(sig)` is the entropy source, not the message text.

**The address binds it to the wallet.** Including `${address}` in the message means:
- An attacker who tricks wallet A into signing cannot derive wallet B's key
- Re-use across wallets is impossible even if someone knows the message pattern

**Why not chain ID or contract address in the message:** These are just strings — anyone can type them manually. They don't add cryptographic binding. Only the address matters because the signer IS the address.

## The correction Justin made (important)

Claude originally proposed a two-signature scheme: sign a first message to derive a salt, then sign a second message using that salt to derive the key. The reasoning was that the signed message text needs to be unpredictable.

Justin challenged this: **"why would there be two unlocks?"**

This exposed the flaw in Claude's thinking. The signed message text does NOT need to be unpredictable — the unpredictability already lives in the ECDSA signature output. Only the wallet's private key can produce that signature. The message is just the input to that operation. A second signature doesn't add entropy — it just adds a wallet prompt.

The insight: **the signature IS the salt**. You don't derive a salt and then sign again. You sign once, and `keccak256(sig)` gives you everything you need. The message text is just a domain separator to prevent accidental reuse — it doesn't need to be secret or random.

**Why not chain ID or contract address in the message:** These are just strings anyone can type manually. They provide no cryptographic binding. Only the wallet address matters because the signer IS the address — you can't fake that without the private key.

**How to apply:** Never propose two-prompt key derivation schemes. Never mistake "the message needs to be unpredictable" for "the key derivation needs to be unpredictable" — they are different things. The entropy lives in the signature output, not the message input.

## Result
- One wallet prompt (register + unlock)
- No storage required
- Deterministic and recoverable on any device with just the wallet
- Wallet-bound and not reusable across wallets or applications

**Why:** Discussed 2026-06-06 while building HomesteadChat on HomesteadRelay. The goal was to avoid hardcoded predictable sign messages while keeping UX to a single prompt and requiring no key storage.

**How to apply:** Any time encryption keys are derived from wallet signatures in this codebase, use this pattern. Do not use fixed hardcoded strings without the wallet address. Do not propose two-prompt schemes.
