---
type: Playbook
title: Build and test the package
description: Rebuild the .deb for a new installer or config, run the container smoke test, and do the end-to-end check in an amd64 VM with a graphical desktop.
tags: [build, test]
sources:
  - resource: test-install.sh
sources_digest: f0450bd8d9484458
---

# When

A new vendor installer, a new or rotated server config, or any change to the
package templates or scripts.

# Steps

1. Build: run `build.sh` with the installer and the config. Output lands in
   `dist/` as a 0600 file.
2. Smoke test in clean containers for each supported release (22.04, 24.04) with
   `test-install.sh`. It checks that dependencies resolve, no shared library is
   missing, a first launch followed by a second leaves exactly one server, and
   purge leaves nothing behind. Containers have no systemd and no TUN device, so
   this proves packaging and import, **not** that the tunnel connects.
3. End to end, in an amd64 OrbStack machine (it has systemd and `/dev/net/tun`):
   install the `.deb`, confirm the service is active, launch the client as a normal
   user, and check the tunnel interface and the public IP.
4. For a graphical session, run a desktop plus a VNC server in that machine and
   open it with macOS Screen Sharing. The `.deb` is reachable at its Mac path
   from inside the machine; copy it to `/tmp` and make it world-readable before
   `apt install`, since the original is 0600.
5. Delete the VM afterwards.

# Verification

* Service active and enabled right after install, and still after a reboot.
* After upgrade and after remove **while connected**, the network still works
  ([why](/gotchas/kill-switch-outlives-the-service.md)).
* Installing over a vendor `.run` install removes its leftovers.

# Cautions

* Connecting with the real key from a test machine uses the one peer, which can
  disturb another device using it.
* An unanswered handshake plus the kill switch cuts the test machine's internet;
  rebooting the VM clears it.
* Host-side pitfalls: [Docker quirks](/gotchas/docker-platform-quirks-on-apple-silicon.md).
