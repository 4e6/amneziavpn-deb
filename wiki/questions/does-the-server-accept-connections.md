---
type: Open Question
title: Does the bundled server accept connections?
description: The tunnel never completed a handshake in tests from Portugal; the server is said to be usable only from Russia, which is unverified.
tags: [server, testing]
---

# Question

Does the server in the bundled config answer handshakes at all, and from where?

# What is known

* The user says the config is meant to be used from Russia, for reaching foreign
  sites.
* In a VM behind a Portuguese residential IP the client behaved exactly as the
  config says (the configured number of junk packets, then the handshake
  initiation, retried every few seconds) and the server sent **nothing** back,
  although it answers ICMP. The tunnel interface came up with the right address
  and routes, but no byte was ever received.
* A silently ignored handshake is what a geo-restricted server, a revoked key or
  a down VPN daemon would each look like. Nothing tested separates them.

# To settle it

Run the end-to-end check from a Russian IP ([playbook](/playbooks/build-and-test.md)).
If it still fails there, look at the peer on the server.

Until then "right after install the user can use the VPN" is unproven; only
"right after install the server is imported and a connection attempt is made" is.
