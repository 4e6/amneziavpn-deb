---
type: Open Question
title: Does closing the app disconnect?
description: The launcher connects on start, but whether closing the window or quitting from the tray drops the tunnel has not been observed.
tags: [launcher, behaviour]
---

# Question

The [launcher](/architecture/launcher.md) passes `--connect 0`. Does closing the
window, or quitting from the tray menu, disconnect the VPN?

# What is known

The tunnel is owned by the root service, not the GUI, so it does not end merely
because the GUI process does. The client probably hides to the tray on window
close; a tray Quit is believed, not seen, to disconnect. The client has no
disconnect command line option.

# To settle it

Needs a server that answers ([open question](/questions/does-the-server-accept-connections.md)):
connect, then close, then quit, checking the tunnel interface each time.
