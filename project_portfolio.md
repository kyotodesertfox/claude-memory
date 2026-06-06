---
name: project-portfolio
description: "Personal portfolio site for Justin's IT/web services business — stack, contracts, deployment info, pricing"
metadata: 
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

# Personal Portfolio

**Repo:** `personal-portfolio` (GitHub: kyotodesertfox/personal-portfolio)
**Stack:** Astro + React islands + Tailwind + Reown/WalletConnect
**Deployed:** Netlify (not yet connected)
**Network:** Taiko Mainnet (same as Homestead)

## Positioning
"Your IT & Web Guy / Not a vendor" - local Jacksonville FL independent, targeting small businesses.

## Pricing
- Site Build: $2,000 cash / 1 ETH crypto (flat)
- Managed Presence: $400/mo cash / 0.2 ETH/mo crypto
- IT Support: $85/hr cash / 0.03 ETH/hr crypto

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
