---
name: feedback-apollo-programmatic
description: "Never use Apollo hooks for programmatic sequential GraphQL loops - use raw fetch to /api/graphql instead"
metadata:
  type: feedback
---

Never use `useLazyQuery` or `useApolloClient` / `client.query()` inside a while loop or any programmatic sequential query pattern in React.

**Why:** `useLazyQuery` returns stale data from the previous call when invoked repeatedly - the same first result comes back every iteration regardless of changed variables. `client.query()` with `fetchPolicy: 'no-cache'` avoids staleness but still interacts badly with Apollo's cache type policies (specifically `keyArgs: false` on `nonFungibleTokens`) when component re-renders occur mid-loop. Both patterns caused infinite accumulation in the recovery tool pagination loop. Clicking a card triggered a re-render which somehow re-triggered the query sequence.

**How to apply:** For any sequential or programmatic query (pagination loops, multi-step lookups), use raw `fetch('/api/graphql', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ query, variables }) })` directly. The `/api/graphql` proxy route handles The Graph auth. Apollo is fine for declarative component-bound queries (`useQuery`, `useLazyQuery` called once per user action) but not for programmatic control flow.
