---
type: Invariant
title: The built .deb contains a VPN private key
description: The .deb and the config it embeds carry the peer's private and preshared keys; they must never be committed or published.
tags: [security, secrets]
sources:
  - resource: .gitignore
  - resource: container-build.sh
sources_digest: e9416ea5a50833a7
---

# Statement

The package embeds the server config verbatim, including `PrivateKey` and
`PresharedKey`. The `.deb`, `dist/`, and any `.conf` or `.run` stay out of git
and out of any shared location.

# Why

* Anyone holding the `.deb` can act as that VPN client.
* It is installed at a **world-readable** path on purpose, so every local user's
  [launcher](/architecture/launcher.md) can import it. On a multi-user machine any
  local account can read the key; the group-restricted alternative was not built.
* A WireGuard-style peer key belongs to one device. Installing the same package on
  several machines makes their tunnels fight over the one peer.

# Enforced by

* `.gitignore` excludes the build output and config/installer file types.
* The build writes the `.deb` mode 0600.
* A scan of staged files for the key material before committing; the test script
  reads the server's public key from the installed config instead of hard-coding
  it, for the same reason.

# If violated

Treat the key as leaked: replace the peer on the server and rebuild.
