---
name: project-flameshot
description: Patched flameshot fork at ~/github/flameshot-src - how it is run and
  rebuilt, the Wayland keyboard-focus trap that governs all UI work in it, and the
  DBus activation that resurrects the packaged binary
metadata:
  type: project
---

Local fork of flameshot (upstream clone of `flameshot-org/flameshot`) at
`~/github/flameshot-src`, carrying two things upstream does not have: an inline
selection-size panel (sliders plus spin boxes for W/H/X/Y, applied live, with a
settable aspect-ratio lock that persists to the drag handles and arrow-key resize)
and a shift-to-reverse arrow tool. Branch `selection-tools`, cut from the `v12.1.0`
tag, local git identity kyotodesertfox noreply, never pushed.

**How it is run:** GNOME custom keybinding on Shift+Print, running
`sh -c "QT_QPA_PLATFORM=wayland /home/zenko/github/flameshot-src/build/src/flameshot gui"`.
The build tree binary IS the one in use. Nothing is installed to /usr/local, and
`/usr/bin/flameshot` is a different binary. `cmake --build ~/github/flameshot-src/build`
is the entire deploy step - no install, no restart, live on the next Shift+Print.

**The Wayland trap, which governs all UI work in this codebase:** the capture widget
is mapped with `Qt::BypassWindowManagerHint` (Linux non-debug branch in
`capturewidget.cpp`). Under Wayland the compositor never gives keyboard focus to a
surface with that flag. Pointer events still arrive per-surface, so anything hosted
in its own window is mouse-only and looks half-broken rather than plainly broken.
`activateWindow()`, `raise()`, and removing `grabKeyboard()` change nothing.

**How to apply:** any control that needs keys must be a plain child widget of the
capture widget, the way the text tool hosts its inline editor, so focus resolves
inside Qt instead of at the compositor. Set `WA_NoMousePropagation` on it, or the
selection widget's event filter reads clicks landing on it as the start of a new
drag. Prefer mouse-drivable controls anyway, because the failure mode is silent.

**DBus activation resurrects the packaged binary:**
`/usr/share/dbus-1/services/org.flameshot.Flameshot.service` carries
`Exec=/usr/bin/flameshot`, so killing the daemon achieves nothing lasting - the next
copy or pin relaunches the Debian build to serve clipboard, pin windows, and tray
while the capture UI runs from the fork. Shadowed 2026-08-12 by
`~/.local/share/dbus-1/services/org.flameshot.Flameshot.service` pointing at the
build tree binary, since XDG_DATA_HOME is read before XDG_DATA_DIRS. The daemon
activates lazily, so busctl reporting "no such name" while idle is normal, not a
failure. Activation does not inherit `QT_QPA_PLATFORM=wayland`; if tray or pin
windows misbehave, wrap Exec in `/bin/sh -c "QT_QPA_PLATFORM=wayland exec ..."`.

This only bites on daemon-side patches (clipboard, pin, tray), or if apt moves the
package off 12.1.0, since version skew there is a DBus payload mismatch between the
two binaries.

Related: [[IDENTITIES]] - `flameshot-src` and `flameshot-selection-size.patch` sit
loose at the `~/github` root, which that file says holds nothing but the two identity
folders. The patch is a pre-branch snapshot and is now redundant.
