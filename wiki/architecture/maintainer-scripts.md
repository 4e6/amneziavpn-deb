---
type: Module
title: Maintainer scripts
description: "The deb's pre/post install and removal scripts: service lifecycle, cleanup of a vendor .run install, and removal of leftover kill-switch rules."
tags: [dpkg, systemd, lifecycle]
sources:
  - resource: pkg/DEBIAN/**
sources_digest: fcf7e07c03468611
---

# Responsibility

Make `apt install`, upgrade, remove and purge leave the machine in a sane state
with the service running, and never strand the user without network.

# Behaviour worth knowing

* **Service handling** mirrors what debhelper's systemd integration would
  generate (enable on first install, restart on upgrade, mask on remove), guarded
  so installs inside containers without systemd do not fail.
* **`preinst`** detects a previous install made with the vendor `.run` by its
  `maintenancetool`, and removes it: the `/etc/systemd/system` unit override
  (it would beat the packaged unit), the `/usr/local/{bin,sbin}` links (they come
  before `/usr/bin` on `PATH` and would bypass the [launcher](/architecture/launcher.md)),
  and the old `/opt` tree.
* **`prerm`** stops the service, then deletes the kill-switch firewall rules the
  service leaves behind ([gotcha](/gotchas/kill-switch-outlives-the-service.md)),
  then ends any running GUI so it does not keep running from replaced files.
* **`postrm`** purges the log directory. Per-user settings in home directories
  are deliberately never touched.

# Why this shape

The firewall cleanup is tied to the package lifecycle and **not** to the
unit (for example `ExecStopPost`): the kill switch is meant to keep blocking
traffic when the service dies unexpectedly, and a unit-level cleanup would
defeat that. Only a stop we cause deliberately should clear it.

# Rejected alternatives

* **Cleanup in the systemd unit** — rejected for the reason above.
* **Leave the kill switch alone** — rejected because upgrading or removing the
  package while connected would leave the machine offline until reboot. Verified
  in a VM: with the cleanup, upgrade and remove over a live tunnel keep the
  network.
