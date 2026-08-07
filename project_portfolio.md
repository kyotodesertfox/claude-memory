---
name: project-portfolio
description: "Personal portfolio site for Justin's IT/web services business — stack, contracts, deployment info, pricing"
metadata: 
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
  modified: 2026-08-07T01:19:13.015Z
---

# Personal Portfolio

**Repo:** `personal-portfolio` (GitHub: kyotodesertfox/personal-portfolio)
**Stack:** Astro + React islands + Tailwind + Reown/WalletConnect
**Deployed:** Netlify (not yet connected)
**Network:** Taiko Mainnet (same as Homestead)

## Positioning
"Your IT & Web Guy / Not a vendor" - local Jacksonville FL independent, targeting small businesses.

## Pricing
- Site Build: 1 ETH crypto (flat) / Trade
- Managed Presence: 0.2 ETH/mo crypto / Trade
- IT Support: 0.03 ETH/hr crypto / Trade

**Cash removed entirely (2026-08-06).** Compensation model resolved: he doesn't want cash, and tried to write one pricing page that worked for both a "need real income" model and an "opt out of cash on principle" model - it couldn't do both. Landed on Crypto + Trade/Barter as the only two modes. Trade mode drops the price number in favor of "Let's Talk Terms" (scope list still shown) plus a bridge blurb pointing to Homestead as proof this kind of exchange already works - not a gimmick, extending his own barter-infrastructure thesis to freelance work instead of just building it for others.

**No-phone, async-triage decision (2026-08-06):** He's private, dislikes phone calls/the "social layer" of client work, wants a triage system instead of live conversation. Realized the ClientLedger intake flow (submit inquiry -> scope builder -> line-item dual sign-off) already **is** that triage system - async, wallet-identified, no call required. Phone CTA removed from the hero as a result; `OrderModal`'s "Let Me Build For You" flow is the only intake path now.

## Contracts (not yet deployed)
- `ClientLedger.sol` - UUPS upgradeable. Inquiry deposits (0.1 ETH), project lifecycle, line items (dual sign-off for scope + completion), referral credits, accounting (deposited/allocated/released/available)
- `DebtToken.sol` - UUPS ERC-1155 soulbound. tokenId = projectId. Minted per confirmed line item, burned on release/removal.
- `ServiceEscrow.sol` - Simple lump-sum escrow for non-financed clients. Kept separate.

## Testnet Deployment Wallet
`0x9939296688D715b7D9Fc17Cf1966f2e366C1Fa6a` (Hekla testnet)

## Compiler Settings
- EVM version: **Cancun** (required - OZ 5.6.1 uses `mcopy` opcode from EIP-5656)
- Homestead uses Paris; portfolio contracts require Cancun due to newer OZ version
- `.deps/npm` must contain copied (not symlinked) OZ packages for remixd to resolve imports

## Inquiry Deposit
0.1 ETH (10% of site build price). Applied to project balance on acceptance. Refunded if declined.

## Key Design Decisions
- Referral credits are wei-equivalent points; applied at `confirmLineItem` time, reduce client's effective obligation (Justin absorbs the discount)
- DebtToken ERC-1155 chosen over ERC-20 because clients can have multiple open projects simultaneously — each projectId is a separate token type
- Inquiry deposit auto-registers client wallet on-chain
- Cash clients get a footnote; crypto/escrow path is the primary "How It Works" flow

## Deploy Order
1. DebtToken (address needed for ClientLedger init)
2. ClientLedger (pass DebtToken address, feeRecipient, feeBps, inquiryDeposit)
3. Call `DebtToken.setLedger(clientLedgerAddress)` post-deploy

**Why:** Compliance/legal protection - smart contract IS the agreement; both wallets sign every line item. Cash has no on-chain record.
