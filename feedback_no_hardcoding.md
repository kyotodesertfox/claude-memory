---
name: feedback-no-hardcoding
description: "Never hardcode token names, symbols, or values — always read from contract or derive dynamically"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

Never hardcode token names, symbols, or display strings (e.g. 'BEER', 'EGG', '$BEER') in UI components unless the user explicitly says to. Always read from the contract ABI (e.g. ERC20 `symbol()`) and derive display values dynamically.

**Why:** Hardcoded strings break when tokens are added, renamed, or reused. The user caught that symbols like "BEER" and "EGG" were hardcoded as strings rather than read from the contract.

**How to apply:** For any component displaying a token symbol, use `useReadContract` with `functionName: 'symbol'` on the token address, then prepend `$` for display. For placeholder/static cards, pass the symbol as a prop from a parent that reads it — do not hardcode it in the component or the data array.
