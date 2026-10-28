---
type: Integration
title: AmneziaVPN client and service
description: How the vendor client, its root service, its settings and its installer behave, as observed on 5.0.3.0 (Linux x64); the facts the package relies on.
tags: [vendor, amnezia]
---

Everything here was observed on version 5.0.3.0, not read from vendor docs, so a
vendor upgrade can change it. Re-check before trusting after a version bump.

# Processes and files

* A GUI client (`AmneziaVPN`) and a root service (`AmneziaVPN-service`). The
  client talks to the service over a local socket under `/var/run/amneziavpn/`.
  The service owns the tunnel (its bundled userspace AmneziaWG), routes and
  firewall; the GUI does not.
* Servers are stored per user as **plaintext JSON inside a Qt settings file**
  under `~/.config/AmneziaVPN.ORG/`. An imported WireGuard/AmneziaWG `.conf`
  becomes an `amnezia-awg` container, with the AWG 2.0 fields (S3/S4, H1–H4
  ranges) understood.
* Only the `xcb` Qt platform plugin is bundled, so it needs an X server (XWayland
  on Wayland desktops).

# Command line

* `--import <data>` imports a config given as a string (`vpn://` key or a
  `.conf` body). **Not idempotent**: see [the gotcha](/gotchas/import-is-not-idempotent.md).
* `--connect <index>` connects to the server at that index on startup. Combined
  with `--import` on a first launch it connects to the freshly imported server.
* `--autostart`, `--cleanup` also exist.

# Runtime needs

* Glibc 2.34 or newer, hence Ubuntu 22.04 as the floor.
* The service shells out to `route`, `sysctl` and `ping`; `route` is in
  `net-tools`, which stock Ubuntu does not install.
* A TUN device. The tunnel interface is named `amn0`.

# Kill switch

On by default. When a tunnel comes up the service installs firewall chains named
`amnvpn.*` hooked from `OUTPUT` that reject non-VPN traffic (LAN ranges and the
server endpoint stay reachable). It does not remove them when it is stopped:
[gotcha](/gotchas/kill-switch-outlives-the-service.md).

# The installer

* A Qt Installer Framework binary. It runs headless with `--root <dir>
  --accept-licenses --confirm-command --default-answer install`.
  `--accept-messages` and `--default-answer` are mutually exclusive.
* Its post-install script calls `sudo`, `systemctl`, writes a unit into
  `/etc/systemd/system` and links the binary into `/usr/local/{bin,sbin}`; that is
  what [the package replaces](/architecture/maintainer-scripts.md).
