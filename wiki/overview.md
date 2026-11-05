---
type: Overview
title: amneziavpn-deb overview
description: Builds an Ubuntu .deb from the official AmneziaVPN Linux installer, optionally with a bundled server config so a user can connect right after installing.
tags: [overview]
---

# What this is

A build project, not an application. It repackages the vendor's AmneziaVPN
installer (a Qt Installer Framework `.run`, x86-64 only) as a `.deb` for Ubuntu
22.04 and newer. After `apt install` the privileged service is running.

Two variants come from the same build: a **plain repack** of the installer, or
one with a WireGuard/AmneziaWG server config baked in, which each user's first
launch of the client imports and connects to. The config is optional.

# Parts

* [Build pipeline](/architecture/build-pipeline.md): turns the installer (and the optional config) into the `.deb`.
* [Launcher](/architecture/launcher.md): the `/usr/bin/AmneziaVPN` wrapper that does the per-user import.
* [Maintainer scripts](/architecture/maintainer-scripts.md): service lifecycle and cleanup on install, upgrade and removal.
* [Vendor client](/integrations/amnezia-client.md): how the third-party client and service behave, as observed.

# Things to keep in mind

* A package built with a config contains a VPN private key: [treat it as a secret](/invariants/deb-contains-private-key.md).
* Verified end to end, including the tunnel connecting.
* How to rebuild and test: [build and test playbook](/playbooks/build-and-test.md).
* How an end user installs it without a terminal: [desktop install playbook](/playbooks/install-from-the-desktop.md).
