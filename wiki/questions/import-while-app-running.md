---
type: Open Question
title: Is --import honoured when the app is already running?
description: If the client is already open (for example in the tray), a second launch may hand off to it and drop the --import argument.
tags: [launcher, import]
---

# Question

The client is single-instance. When the launcher starts a second one with
`--import` while the first is running, is the argument forwarded or dropped?

# What is known

Not tested. It only matters if the app is already running before the server was
ever imported, which a fresh install makes unlikely. Because the launcher decides
by looking at the user's settings, a dropped import is retried on the next launch
rather than lost ([why](/architecture/launcher.md)).
