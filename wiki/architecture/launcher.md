---
type: Module
title: Launcher
description: The /usr/bin/AmneziaVPN wrapper that imports the bundled server on a user's first run and connects, without ever importing twice.
tags: [launcher, import]
sources:
  - resource: pkg/AmneziaVPN
  - resource: pkg/AmneziaVPN.desktop
sources_digest: 013f8debea0b0310
---

# Responsibility

Start the vendor client, adding two arguments when they are needed: `--import`
with the bundled config, and `--connect 0`. In a plain repack there is no bundled
config, and the launcher adds neither: the client starts exactly as the vendor's
would. It is the only place the
"pre-imported server" behaviour exists; nothing runs at install time, because
servers live in each user's home, not on the system.

# Behaviour worth knowing

* Import happens only if the config's peer `PublicKey` is **absent** from the
  user's client settings. The key appears verbatim in that file, so a plain
  substring search is a reliable "already imported" test.
* The caller's own `--import` or `--connect` wins; help and version flags skip
  both.
* `--connect 0` means the first server in that user's list, which is ours only
  when it is the first one. That is why it is tied to the bundled config being
  present: in a plain repack it would auto-connect to whatever server the user
  happened to add first.
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

* **Write the client's settings file into every home directory** — rejected
  because the format is private to the vendor and version-dependent, and a
  package script cannot reach users created later.
* **A write-once marker file instead of the key check** — rejected because a
  failed import, or one dropped because the app was already running (which
  the client does, see [vendor client](/integrations/amnezia-client.md)), would
  be recorded as done. The cost of the content check we chose: a server the user
  deletes comes back on the next launch.
