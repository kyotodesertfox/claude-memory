---
name: project_portfolio_portal
description: "personal-portfolio blockchain client/admin portal — Hoodi testnet, ClientLedger, DebtToken ERC-1155, encrypted chat, ScopeBuilder"
metadata: 
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

## Overview

`~/github/personal-portfolio/` is Justin's freelance website and client acquisition system. Separate repo from homestead. Blockchain layer runs on **Hoodi testnet (chainId 167013)** — NOT Taiko mainnet. Uses Astro (static site) + React islands + wagmi v2.

**Why:** Clients submit an ETH deposit inquiry, Justin reviews and accepts/declines via the admin portal. Accepted inquiries open a project where both sides drag-and-drop services into a scope bin and propose line items on-chain. Messaging is end-to-end encrypted via X25519.

---

## Deployed Contracts (Hoodi testnet 167013)

Addresses stored in `hoodie.env` (not .env.local). All UUPS upgradeable (OZ 5.x).

| Contract | Proxy | Current Impl |
|---|---|---|
| DebtToken (ERC-1155) | 0xc2F684223dEc3ce981Ef234b216c3327e072D42f | 0xa5e40dec39307b0087CD90579313f1b7e94Ca9f4 |
| ClientLedger | 0xdEf57F2cA8a7b1403efCDD05e63b93a207080955 | 0x918aC0df829cE37caBfD9D1046C28BA05B2957e4 |
| HomesteadRelay | 0xc662fe2D2b887CE6647e81D971efd1d26B71e854 | 0x3b7a3e36873Be313AB9e2A334959847Fd1668aab |

**Owner wallet:** `0x9939296688D715b7D9Fc17Cf1966f2e366C1Fa6a`

---

## NFT Design (DebtToken ERC-1155)

Soulbound voucher — 1 NFT per inquiry, forever. tokenId = inquiryId.

**Mint:** Once at `submitInquiry`. Never minted again (not on deposit, not on line items).

**Burn:** Only on `withdrawInquiry` (client backs out) or `declineInquiry` (admin declines). Never burned mid-project or on line item release/removal.

**Post-completion:** NFT stays permanently in client wallet. Client can voluntarily `selfBurn` if they want. It's marketing — someone sees an unfamiliar NFT, looks it up, finds the portal.

**Metadata:** `setTokenURI(tokenId, uri)` on DebtToken (owner-only) sets per-token URI at key lifecycle points. `setBaseURI` for fallback. URI returns JSON with project name, services, branding, link to live site — set at acceptance or completion.

**Why ERC-1155 not ERC-20:** Contract handles all financial tracking (deposited, allocated, released). NFT is a credential/voucher, not a balance. 1 unique NFT per engagement is more meaningful as marketing than a fungible balance.

---

## ClientLedger.sol (`contracts/ClientLedger.sol`)

### Inquiry lifecycle
- `submitInquiry()` payable — client deposits ETH, mints 1 DebtToken NFT (tokenId=inquiryId)
- `requestScopeItem(inquiryId, description, ethAmount)` — client only, pending only; emits `ScopeItemRequested` event
- `cancelScopeItem(inquiryId, itemId)` — client only, pending only; sets `scopeItemCancelled` flag, emits event
- `markReadyForReview(inquiryId)` — client signals scope is complete; sets `readyForReview` flag, irreversible, withdraw button hidden after this
- `acceptInquiry(inquiryId, description, financed)` — owner only; opens project
- `declineInquiry(inquiryId)` — owner only; refunds + burns NFT
- `withdrawInquiry(inquiryId)` — client only, pending only; refunds + burns NFT
- `proposeLineItem(projectId, description, ethAmount)` — either party, post-acceptance
- `getInquiry(inquiryId)` returns 6 values: client, depositAmount, accepted, declined, projectId, readyForReview

### Storage additions (beyond original)
- `inquiryScopeCount` mapping — tracks pre-acceptance scope item count per inquiry
- `scopeItemCancelled` mapping — tracks cancelled scope items
- `readyForReview` bool on Inquiry struct (packed between `declined` and `projectId`)
- `__gap[37]` (was 39, reduced by 2 for the two new mappings)

### Key design decisions
- NFT burns removed from `_releaseItem` and `confirmRemoveLineItem` — NFT is not debt tracking, it's a voucher
- `deposit()` does NOT mint NFTs — only `submitInquiry` does
- `financed` flag on Project struct is currently unused (dead flag, kept for future use)

---

## DebtToken.sol (`contracts/DebtToken.sol`)

- `setTokenURI(uint256 tokenId, string uri)` — owner-only, update metadata at any lifecycle point
- `setBaseURI(string baseURI)` — owner-only, fallback URI
- `uri(uint256 tokenId)` — returns per-token URI if set, else base URI
- `selfBurn(uint256 tokenId)` — holder can voluntarily burn their own token
- Soulbound: `safeTransferFrom` and `safeBatchTransferFrom` both revert
- Storage: `_tokenURIs` mapping + `_baseTokenURI` string added after `totalSupply`

---

## Component Architecture

| File | Purpose |
|---|---|
| `src/components/WalletProvider.jsx` | wagmi config for Hoodi testnet |
| `src/components/ClientPortal.jsx` | Client-facing inquiry list + popout (wallet-filtered) |
| `src/components/AdminDashboard.jsx` | Owner-gated admin: RegisterKeyPanel + collapsible inquiry sections |
| `src/components/ChatPanel.jsx` | Encrypted/plaintext messaging via HomesteadRelay events |
| `src/components/ScopeBuilder.jsx` | Drag-and-drop project scope designer, on-chain proposals |
| `src/pages/client.astro` | Astro page, `client:load` React island |
| `src/pages/admin.astro` | Astro page, `client:load` React island |

---

## Admin Dashboard

Four collapsible inquiry sections (open by default except Declined):
1. **Ready for Review** — pending + readyForReview=true
2. **Pending** — pending, not yet submitted for review
3. **Accepted** — active projects
4. **Declined** — collapsed, 50% opacity

"Ready for Review" green badge appears on InquiryCard when client has submitted for review.

---

## Client Portal

- `selectedId` (not `selected` object) drives the popout — always derives live data from `myInquiries` so state updates (like readyForReview) reflect immediately after tx confirms
- "Submit for Review" shows a confirmation modal warning that withdrawal is no longer possible
- Withdraw button hidden once client marks ready for review

---

## ScopeBuilder.jsx

**Pre-acceptance (client):**
- Drag services to bin → "Submit to Build Out" → calls `requestScopeItem` sequentially
- Submitted items appear under "Submitted Tasks" with ETH total
- Services filter out of right panel once submitted (matched by label prefix)
- ✕ button on submitted items calls `cancelScopeItem`

**Pre-acceptance (admin):**
- Sees submitted tasks (read-only), no submit button, no custom item form
- "Accept inquiry to propose items" text shown instead of button

**Post-acceptance (both):**
- Full drag-and-drop, "Propose Items" → calls `proposeLineItem`
- Admin custom item form visible
- "Proposed Line Items" section shows on-chain proposals

---

## Chat Encryption (ChatPanel.jsx)

**Key derivation:** `keccak256(walletSignature of "HomesteadRelay key registration v1")` → 32-byte seed → `nacl.box.keyPair.fromSecretKey(seed)`. Key stays in React state only.

**Payload format:** `senderPubKey(32 bytes) + nonce(24 bytes) + ciphertext`

**Decryption:** sent messages use `theirKey` as peerPub; received use `payload.slice(0, 32)`.

**Library:** `tweetnacl` (not @noble/curves — Vite subpath import resolution fails).

---

## OZ v5 Remix Upgrade Workaround

Remix "Upgrade with Proxy" broken for OZ v5. Workaround every time:
1. Deploy new impl only (no proxy wrapper)
2. "At Address" on proxy using proxy ABI
3. Call `upgradeToAndCall(newImpl, "0x")` manually

---

## Cross-Project Notes

- The HomesteadRelay encrypted chat pattern (X25519 via tweetnacl, key derived from wallet signature, payload = pubKey+nonce+ciphertext) is intended to be reused on the Homestead Exchange site — buyer/seller or user-to-user messaging. Port ChatPanel.jsx when that feature is ready.
- A standalone relay deployment on Taiko mainnet is planned as a revenue product. Fee tiers: external users pay ETH per message, $QUANTUM holders get a discount, Homestead participants pay free/near-free.
- **$QUANTUM token model:** No presale, no allocation. Earned free through on-chain activity in the Homestead ecosystem. Secondary market: earners can sell to anyone. External demand comes from relay users who want the discount rate — they have to buy from real participants. This creates a flywheel: relay demand = $QUANTUM demand = value flows back to active Homestead users.

---

## Pending Items

- Set `tokenURI` on existing inquiry NFTs via `setTokenURI` (need to design metadata JSON + IPFS upload)
- Blockscout verification failed for all Hoodi contracts (compiler mismatch) — unverified
- Quantum encryption subscription model — discussed, not designed
- ClientLedger discount impl (discountBps + discountFlat) deployed 2026-06-06, UTAC complete on proxy
