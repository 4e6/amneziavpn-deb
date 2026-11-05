---
type: Module
title: Build pipeline
description: Runs the vendor installer headless in an amd64 container and assembles the .deb from its output, templates and, if one is given, a server config.
tags: [build, docker]
sources:
  - resource: build.sh
  - resource: container-build.sh
  - resource: Dockerfile
  - resource: pkg/copyright
sources_digest: 8f205f1cda25e518
---

# Responsibility

Given the vendor `.run` and, optionally, a server `.conf`, produce one `.deb` in
`dist/`. The host script only starts a container; the real work happens inside it.

# Two variants

| | Plain repack | With a config |
|---|---|---|
| Bundled `default.conf` | none | the config, verbatim |
| Package description, changelog | no server mentioned | says a server is pre-imported and the `.deb` is a secret |
| Output mode | 0644 | 0600 |

Everything else (the payload, unit, launcher, maintainer scripts) is the same, so
there is one set of templates and one package name. The variant is decided by
whether a config is mounted into the container, and the control template carries no
`Description`: the build appends the one that matches. Both write the same file
name, so a build replaces the previous one.

# Behaviour worth knowing

* The package version comes from the extracted installer's own metadata, not from
  a filename.
* A given config is checked for the fields the rest of the system depends on. The
  peer `PublicKey` is required because the [launcher](/architecture/launcher.md)
  keys off it.
* Installer-framework leftovers are dropped. `maintenancetool` in particular
  would let a user uninstall behind dpkg's back.
* The vendor's `/opt/AmneziaVPN` layout is kept as is. The client finds its
  libraries relative to its own location and the service unit points there, so
  moving it would mean patching vendor files. Lintian's "files in /opt" errors
  are therefore knowingly ignored.
* The output `.deb` is compressed with xz (older dpkg cannot read zstd). With a
  config it is mode 0600: see [the invariant](/invariants/deb-contains-private-key.md).

# Why this shape

* **In a container, on the container's own filesystem.** The installer is an
  x86-64 Linux binary, and extracting onto a macOS bind mount risks case-folding
  and lost modes or symlinks.
* **The image deliberately has no `sudo`.** The vendor's post-install script
  calls `sudo` to start services and write system paths; without it those calls
  fail harmlessly instead of touching anything.
* The installer is copied inside and made executable there, because the mounted
  original is read-only and usually not executable.

# Rejected alternatives

* **Debhelper source package** — rejected as more machinery than one prebuilt
  binary payload and a few hand-written scripts need; `dpkg-deb` on a staged tree
  is enough.

See [vendor client](/integrations/amnezia-client.md) for the installer's flags and
[Docker quirks](/gotchas/docker-platform-quirks-on-apple-silicon.md) for host pitfalls.
