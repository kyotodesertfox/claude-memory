---
name: project-companion-status
description: "Homestead Companion app current build status — what's done, what's pending, what to verify next session"
metadata: 
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

**Last updated: 2026-05-30**

## What's working
- Wallet creation (SecureRandom native Kotlin module, 12-word BIP39 mnemonic)
- Wallet import from seed phrase
- Screenshot protection on CreateWalletScreen (FLAG_SECURE per-screen)
- Navigation: OnboardingStack → MainTabs via `navigation.getParent()?.replace('MainTabs')`
- All tab screens (Home, Market, Redeem, Settings) on light theme — see [[project-companion-ui-standard]]
- ETH balance loads correctly from Taiko mainnet RPC

## Netlify contracts endpoint fix — deployed 2026-05-30
The `/api/contracts` endpoint was returning SPA HTML instead of JSON because the function used Edge Function syntax (`export default`, `export const config`) but was in `netlify/functions/` (Lambda directory).

Fix: created `apps/exchange/netlify/edge-functions/contracts.js` using `Deno.env.get()` for env vars. Committed and pushed. **Needs verification** — after Netlify redeploys, `GET https://homesteaders.netlify.app/api/contracts` should return JSON with contract addresses. Once it does, token balances and market listings will load.

## Pending
- **Verify contracts endpoint** after Netlify deploy: `curl https://homesteaders.netlify.app/api/contracts` should return JSON
- **Biometric login preference** (Task #1): let user choose biometrics on app open after wallet creation; save pref to EncryptedStorage; toggle in Settings; `react-native-keychain` already installed
- **QR scanner on RedeemScreen**: placeholder in place, camera not wired yet
- **BUY button on MarketScreen**: UI only, no transaction logic yet

## Dev machine notes
- Android SDK at `/home/zenko/Android/Sdk`
- `android/local.properties` exists (gitignored)
- Run Metro: `npx react-native start` from `apps/HomesteadCompanion/`
- Build/run: `npx react-native run-android`
