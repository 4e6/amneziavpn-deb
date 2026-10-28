---
type: Gotcha
title: The client's --import is not idempotent
description: Running the client with --import twice for the same config adds a duplicate server instead of recognising it.
tags: [import, amnezia]
---

# Symptom

Launching the client twice with `--import` and the same config shows two servers
("Server 1" and "Server 2").

# Cause

The client treats every import as a new server and does not compare against
existing ones.

# Fix

Never pass `--import` blindly. The [launcher](/architecture/launcher.md) checks
whether the config's peer public key is already in the user's settings first.
