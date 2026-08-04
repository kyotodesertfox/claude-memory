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

Key refresh, without running the app: NordVPN's account-bound WireGuard private key doesn't expire on its own — what goes stale is the *server* the config points at, since NordVPN rotates/retires servers over time. An access token (generated from the NordVPN dashboard's manual-setup page, one-time-display, no local record kept by NordVPN) authenticates two API calls: `https://api.nordvpn.com/v1/users/services/credentials` returns the durable private key, `https://api.nordvpn.com/v1/servers/recommendations` returns a currently-live WireGuard server. The token itself is stored at `~/.nordvpn-token.sh` (mode 600, sourced from `.bashrc` as `$NORDVPN_ACCESS_TOKEN`) — see [References](references.md).
