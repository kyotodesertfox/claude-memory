---
name: project-nordvpn-wireguard
description: Why the official NordVPN GUI was abandoned for a manual NetworkManager WireGuard setup, the suspend/resume fix, and how stale keys get refreshed without reinstalling the app
metadata:
  type: project
---

Left the official NordVPN Linux app because suspend/resume desynced the kernel WireGuard device from what the app's daemon believed was connected — the only recovery was a full reboot. Migrated to a manually-configured WireGuard connection managed directly by NetworkManager (connection name `nordvpn`), authenticated with a key pair pulled once from NordVPN's own infrastructure rather than by running their app continuously.

**Why:** the app's own suspend/resume handling was the actual defect, not WireGuard or NetworkManager. Managing the tunnel through NM instead removes the daemon that was desyncing.

**How to apply:** don't reinstall/reintroduce the official app as the ongoing connection manager — that reintroduces the exact bug this setup exists to avoid. It's fine to install it *transiently* (or just use its access-token API) purely to mint fresh credentials, then go back to the manual setup.

Current architecture:
- Connection is netplan-owned: source YAML at `/etc/netplan/90-NM-426ddfbc-6b88-403d-b66d-d2bc1e9cfe28.yaml` (root-only), rendered to `/run/NetworkManager/system-connections/netplan-nordvpn.nmconnection`. Any fix has to land in the netplan source or it won't survive `netplan apply`/reboot.
- Suspend/resume fix lives at `/etc/systemd/system-sleep/nordvpn-resume` — forces `nmcli connection down` then `up` on resume, because NM reports the connection active after waking but the kernel WireGuard device was actually destroyed during suspend.
- GNOME's network panel toggle is unreliable independent of all this — it caches a stale D-Bus `ActiveConnection` object path, so clicking it after the connection's been recreated elsewhere throws "Object does not exist at path." `nmcli` always resolves live and never hits this. Built a tray toggle (`~/.local/bin/nordvpn-tray`, AyatanaAppIndicator3, calls `nmcli connection up/down nordvpn`) as the click-to-toggle replacement.

## THE RECURRING BREAKAGE: server retirement (confirmed 2026-08-10)

**This is why it "keeps breaking every few days" and always looks like a mystery.**

The config pins one specific WireGuard server. NordVPN rotates and retires servers on
their own schedule and nothing tells us. When the pinned one goes away the connection
still comes up **"activated"**, because bringing up a WireGuard interface never requires
the far end to exist - there is no connection to fail. So it reports healthy and carries
no traffic.

The credential is never the problem. The account-bound private key does not expire. Only
the server address goes stale. Confirmed 2026-08-10: `212.102.45.117` had been retired,
and repinning to a live server restored traffic immediately.

**The signal to test is the handshake, not the API.** `wg show nordvpn` - if
`latest handshake` is missing or older than ~3 minutes while the interface is up, the peer
is not answering. That catches a retired server, a dead server and a blocked port
identically. An API query only catches the first. Conky reports CONNECTED off
`nmcli con show --active`, which stays true for a dead tunnel, so **the desktop indicator
is exactly what lies during this failure.**

## Repinning: THREE coordinated edits, and sed cannot do it

The netplan source looks like this:

```yaml
      peers:
      - endpoint: "212.102.45.117:51820"
        keys:
          public: "mohrVW5iptcR0gt3Y/R8dcgmonn9ZAlsVwvxf60OdCM="
      networkmanager:
        passthrough:
          wireguard-peer.mohrVW5iptcR0gt3Y/R8dcgmonn9ZAlsVwvxf60OdCM=.persistent-keepalive: "25"
```

Swapping servers requires all three:
1. `peers[0].endpoint`
2. `peers[0].keys.public`
3. **the passthrough key literally NAMED `wireguard-peer.<PUBKEY>.persistent-keepalive`** -
   the old public key is embedded in the KEY NAME. Miss it and NetworkManager carries a
   stale peer alongside the new one.

**A sed-based attempt silently matched nothing** - the values are quoted, and the field is
`public:` nested under `keys:`, not `public-key:`. It would have logged five attempts,
changed nothing, and reported failure, hiding the fault behind the appearance of work.
Use the parser.

## Tooling as of 2026-08-10

**`/usr/local/bin/nordvpn-repin`** - INSTALLED, root:root 0755. Python, parses the YAML,
makes all three edits or refuses. `--show` prints the current endpoint and peer key,
`--check` asks NordVPN whether the pinned server still exists, `--set IP PUBKEY` swaps.
Takes a `.bak` first. Verified working: `--show`, `--check` and `--set` all exercised
by hand.

**`90-nordvpn-verify`** - WRITTEN, NOT INSTALLED, at `/tmp/90-nordvpn-verify`. A
NetworkManager dispatcher script for
`/etc/NetworkManager/dispatcher.d/`. Fires on any `up` event for the connection, waits 15s
for a handshake, and if none arrives calls `nordvpn-repin` against up to five recommended
servers until one answers. No timer - it runs only when failure is possible. `flock` guard
is required because it calls `nmcli connection up`, which re-fires the dispatcher.

Because it fires on ANY up event, **the tray toggle becomes a repair button**: traffic
stops, toggle off and on, and it verifies and repins instead of returning to the same dead
server.

**Held pending one decision:** it silently relocates the exit IP, possibly to another
country. Options were auto-switch as written, add a country filter, or notify-only.

## Getting a live server needs no token

The recommendations endpoint is unauthenticated. Only `/v1/users/services/credentials`
(the private key) requires the access token.

```
curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters%5Bservers_technologies%5D%5Bidentifier%5D=wireguard_udp&limit=3" \
 | jq -r '.[] | "\(.hostname) \(.station) \(.load)% \((.technologies[]|select(.identifier=="wireguard_udp")|.metadata[]|select(.name=="public_key")|.value))"'
```

Servers in one cluster share a public key; that is normal.

**Current state 2026-08-10:** repinned to `186.247.182.105` (us13331, Atlanta), handshake
confirmed, traffic flowing.

**Outstanding:** the WireGuard private key was pasted into a Claude session transcript on
2026-08-10 and should be rotated from the NordVPN manual-setup page, then written to
`keys.private` in the netplan source.

## Key refresh, without running the app: NordVPN's account-bound WireGuard private key doesn't expire on its own — what goes stale is the *server* the config points at, since NordVPN rotates/retires servers over time. An access token (generated from the NordVPN dashboard's manual-setup page, one-time-display, no local record kept by NordVPN) authenticates two API calls: `https://api.nordvpn.com/v1/users/services/credentials` returns the durable private key, `https://api.nordvpn.com/v1/servers/recommendations` returns a currently-live WireGuard server. The token itself is stored at `~/.nordvpn-token.sh` (mode 600, sourced from `.bashrc` as `$NORDVPN_ACCESS_TOKEN`) — see [References](references.md).
