---
type: Module
title: Launcher
description: The /usr/bin/AmneziaVPN wrapper that imports the bundled server on a user's first run, and connects only in an --autoconnect build, without ever importing twice.
tags: [launcher, import]
sources:
  - resource: pkg/AmneziaVPN
  - resource: pkg/AmneziaVPN.desktop
  - resource: container-build.sh
sources_digest: 73d5a38b4731f36b
---

# Responsibility

Start the vendor client, adding up to two arguments: `--import` with the bundled
config, and, only in a build made with `--autoconnect`, `--connect 0`. In a plain
repack there is no bundled config, and the launcher adds neither: the client starts
exactly as the vendor's would. It is the only place the
"pre-imported server" behaviour exists; nothing runs at install time, because
servers live in each user's home, not on the system.

# Behaviour worth knowing

* Import happens only if the config's peer `PublicKey` is **absent** from the
  user's client settings. The key appears verbatim in that file, so a plain
  substring search is a reliable "already imported" test.
* The caller's own `--import` or `--connect` wins; help and version flags skip
  both.
* Connecting on start is **off by default** and fixed per package: the build
  substitutes a placeholder in the launcher (`container-build.sh`), and the
  unsubstituted source value counts as off. It cannot be turned on without a
  config.
* `--connect 0` means the first server in that user's list, which is ours only
  when it is the first one. That is why it needs the bundled config: in a plain
  repack it would auto-connect to whatever server the user happened to add first.
  A user who deleted our server and added another would still be auto-connected to
  that one.
* Builds differ only in the launcher and the changelog line; the version string is
  the same, so upgrading to a build without autoconnect silently stops it. Packages
  built before the option existed always auto-connect, so replacing one with a
  default build stops it too.
* The config is passed as an argument, so the private key is visible in the
  process list while the app runs. The file is world-readable anyway
  ([why](/invariants/deb-contains-private-key.md)), so this adds no exposure.
* The desktop entry points at the launcher by absolute path, for the same reason
  `preinst` deletes stale `/usr/local/bin` links: anything earlier on `PATH`
  would silently bypass the import.

# Why this shape

The client's `--import` is the vendor's own supported path, so it survives
changes to how the client stores servers. The guard exists because
[import is not idempotent](/gotchas/import-is-not-idempotent.md).

# Rejected alternatives

* **A runtime switch for autoconnect (marker file, env var, per-user setting)** —
  rejected: a marker file would be reset by every upgrade, and users can already
  pass their own `--connect N`. The choice is made when the package is built, like
  the config itself.
* **Write the client's settings file into every home directory** — rejected
  because the format is private to the vendor and version-dependent, and a
  package script cannot reach users created later.
* **A write-once marker file instead of the key check** — rejected because a
  failed import, or one dropped because the app was already running (which
  the client does, see [vendor client](/integrations/amnezia-client.md)), would
  be recorded as done. The cost of the content check we chose: a server the user
  deletes comes back on the next launch.
