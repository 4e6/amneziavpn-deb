---
type: Invariant
title: The built .deb contains a VPN private key
description: A .deb built with a config carries the peer's private and preshared keys, as does the config; neither may be committed or published.
tags: [security, secrets]
sources:
  - resource: .gitignore
  - resource: container-build.sh
sources_digest: 9556c50903ebf06a
---

# Statement

A package built with a config embeds it verbatim, including `PrivateKey` and
`PresharedKey`. The `.deb`, `dist/`, and any `.conf` or `.run` stay out of git
and out of any shared location.

A plain repack carries no key, but `dist/` holds either variant under the same
file name, so the whole directory is treated as secret either way.

# Why

* Anyone holding the `.deb` can act as that VPN client.
* It is installed at a **world-readable** path on purpose, so every local user's
  [launcher](/architecture/launcher.md) can import it. On a multi-user machine any
  local account can read the key; the group-restricted alternative was not built.
* A WireGuard-style peer key belongs to one device. Installing the same package on
  several machines makes their tunnels fight over the one peer.

# Enforced by

* `.gitignore` excludes the build output and config/installer file types.
* A build with a config writes the `.deb` mode 0600 (a plain repack is 0644).
* A scan of staged files for the key material before committing; the test script
  reads the server's public key from the installed config instead of hard-coding
  it, for the same reason.

# If violated

Treat the key as leaked: replace the peer on the server and rebuild.
