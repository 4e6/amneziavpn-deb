---
type: Module
title: Build pipeline
description: Runs the vendor installer headless in an amd64 container and assembles the .deb from its output, templates and the supplied config.
tags: [build, docker]
sources:
  - resource: build.sh
  - resource: container-build.sh
  - resource: Dockerfile
  - resource: pkg/copyright
sources_digest: 8c4bc55c3414f385
---

# Responsibility

Given the vendor `.run` and a server `.conf`, produce one `.deb` in `dist/`. The
host script only starts a container; the real work happens inside it.

# Behaviour worth knowing

* The package version comes from the extracted installer's own metadata, not from
  a filename.
* The config is checked for the fields the rest of the system depends on. The
  peer `PublicKey` is required because the [launcher](/architecture/launcher.md)
  keys off it.
* Installer-framework leftovers are dropped. `maintenancetool` in particular
  would let a user uninstall behind dpkg's back.
* The vendor's `/opt/AmneziaVPN` layout is kept as is. The client finds its
  libraries relative to its own location and the service unit points there, so
  moving it would mean patching vendor files. Lintian's "files in /opt" errors
  are therefore knowingly ignored.
* The output `.deb` is mode 0600 and compressed with xz (older dpkg cannot read
  zstd). See [the invariant](/invariants/deb-contains-private-key.md).

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
