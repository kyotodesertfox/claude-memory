---
name: project-companion-ui-standard
description: Homestead Companion app UI/layout standard — all tab screens must match this spec
metadata: 
  node_type: memory
  type: project
  originSessionId: 523c0fda-fe57-4f72-a00b-62954e51ac16
---

All tab screens in the Homestead Companion app share a strict visual standard. Do not deviate from this without explicit instruction.

## Colors
- Page background: `#f0fdf4` (light green tint — matches exchange web app)
- Cards: `colors.white` with `elevation: 2–6` shadow
- Primary text: `colors.gray900`
- Secondary text: `colors.gray400` or `colors.gray500`
- Accent / brand: `colors.green` (`#16a34a`)
- Token icon background: `colors.greenLight` (`#dcfce7`)
- Danger card background: `#fff5f5`, border `#fecaca`
- No dark backgrounds (`colors.dark`, `colors.darkCard`, `colors.darkBorder`) on any tab screen

## Header (every tab screen)
```js
<View style={s.header}>
  <Text style={s.brand}>HOMESTEAD</Text>
  <Text style={s.network}>PAGE NAME</Text>
</View>
```
```js
header:  { paddingTop: 56, paddingBottom: 20, paddingHorizontal: 22 },
brand:   { fontSize: 16, fontWeight: font.black, color: colors.gray900, letterSpacing: 3, marginBottom: 2 },
network: { fontSize: 9, color: colors.green, fontWeight: font.bold, letterSpacing: 1.5 },
```
HomeScreen has `paddingTop: 56`. SettingsScreen (already has its own scroll padding) uses `paddingTop: 34`. All others use 56.

## Tab bar (App.tsx)
```js
tabBarStyle: { borderTopColor: colors.gray100, backgroundColor: colors.white, height: 96, paddingBottom: 24 }
```

## Cards
White background, `borderRadius: 14–20`, shadow:
```js
elevation: 2, shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.04, shadowRadius: 6
```
Balance/hero card uses stronger shadow: `elevation: 6, shadowOpacity: 0.07, shadowRadius: 14`

## Section labels
```js
{ fontSize: 10, fontWeight: font.black, color: colors.gray400, letterSpacing: 2.5, marginBottom: 10 }
```

## Buttons
- Primary (filled): `backgroundColor: colors.green`, white text
- Secondary (outline): `borderWidth: 1.5, borderColor: colors.green`, green text, white bg
- Both: `paddingVertical: 14–16, borderRadius: 12`

**Why:** Established by Justin during HomeScreen redesign (2026-05-30). Companion app should look consistent with the exchange web app light theme.

**How to apply:** Any new tab screen or screen edit must use `#f0fdf4` background, the standard header block with `paddingTop: 56`, white shadow cards, and `colors.gray900` primary text. Never reintroduce dark theme colors on tab screens.
