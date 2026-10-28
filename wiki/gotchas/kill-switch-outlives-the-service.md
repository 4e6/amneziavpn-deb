---
type: Gotcha
title: The kill switch outlives the service
description: Stopping or restarting the Amnezia service while connected leaves firewall rules that block all non-VPN traffic until reboot.
tags: [firewall, kill-switch, ops]
---

# Symptom

After stopping, restarting or removing the service while a tunnel was up, the
machine has no internet at all (even DNS and ping fail), though the tunnel
interface and its routes are gone.

# Cause

The service installs `amnvpn.*` iptables chains, hooked from `OUTPUT`, when a
tunnel comes up. A stop does not remove them, so the "reject everything except
the VPN" rule keeps applying with no VPN. A reboot clears them (rules are not
persistent).

# Fix

Remove the `OUTPUT` jump to `amnvpn.anchors`, then flush and delete every
`amnvpn.*` chain, for both iptables and ip6tables. The package does this in
`prerm` ([maintainer scripts](/architecture/maintainer-scripts.md)). By hand, a
VM reboot also works.

Do not "fix" it in the unit: the same behaviour is the feature when the service
crashes.

# Related

A dead or unreachable server produces the same blackout while connected, since
all traffic is forced through a tunnel that carries nothing.
