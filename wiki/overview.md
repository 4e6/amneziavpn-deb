---
type: Overview
title: amneziavpn-deb overview
description: Builds an Ubuntu .deb from the official AmneziaVPN Linux installer plus a server config, so a user can connect right after installing.
tags: [overview]
---

# What this is

A build project, not an application. It repackages the vendor's AmneziaVPN
installer (a Qt Installer Framework `.run`, x86-64 only) as a `.deb` for Ubuntu
22.04 and newer, and bakes one WireGuard/AmneziaWG server config into it. After
`apt install` the privileged service is running, and each user's first launch of
the client imports that server and connects to it.

# Parts

* [Build pipeline](/architecture/build-pipeline.md): turns installer + config into the `.deb`.
* [Launcher](/architecture/launcher.md): the `/usr/bin/AmneziaVPN` wrapper that does the per-user import.
* [Maintainer scripts](/architecture/maintainer-scripts.md): service lifecycle and cleanup on install, upgrade and removal.
* [Vendor client](/integrations/amnezia-client.md): how the third-party client and service behave, as observed.

# Things to keep in mind

* The built package contains a VPN private key: [treat it as a secret](/invariants/deb-contains-private-key.md).
* Packaging was verified end to end except the one thing users care about: whether
  the tunnel connects. See [the server question](/questions/does-the-server-accept-connections.md).
* How to rebuild and test: [build and test playbook](/playbooks/build-and-test.md).
