---
type: Playbook
title: Install the package from the desktop
description: How a non-terminal user installs the .deb on current Ubuntu (App Center via Open With, or GDebi), and why the package stays a .deb rather than a snap.
tags: [install, gui]
sources:
  - resource: README.md#installing-without-a-terminal
sources_digest: 8291feb936f00ec1
---

# When

Someone installs the `.deb` on Ubuntu without using a terminal, or asks to
repackage it as a snap or Flatpak because double-clicking "doesn't work".

# Why not another format

The package installs a root systemd service, drives `/dev/net/tun`, and leaves
kill-switch firewall rules that `prerm` cleans up ([maintainer scripts](/architecture/maintainer-scripts.md)).
Flatpak and AppImage can't do any of that. A snap would need classic confinement,
and a local snap installs only from the terminal (`--dangerous --classic`), so it
wouldn't fix the GUI problem. The problem is Ubuntu's file association for `.deb`,
not the format.

# Steps

1. **24.04 / 26.04:** right-click the `.deb` → *Open With…* → App Center → *Install*.
   Since 23.10 a double-click could show "Could not display… no app installed for
   'Debian package' files" or open Archive Manager. An App Center (snap-store)
   update in mid-2024 restored side-loading on 24.04.
2. **Fallback:** install `gdebi` and open the file with *GDebi Package Installer*.
3. **Remove:** with `apt remove`/`purge`. As of 2024 App Center couldn't uninstall
   or reinstall a side-loaded `.deb`.

# Cautions

* The maintainer scripts don't read a TTY, `SUDO_USER` or `$HOME`, so an install
  through packagekitd/pkexec should match `sudo apt install`. Only the
  [launcher](/architecture/launcher.md) uses `$HOME`, and it runs as the user.
* A file built with a config is 0600 on purpose ([secret](/invariants/deb-contains-private-key.md)).
  GUI installers read it as root, so don't loosen the mode to "fix" an install.
* Installing from the desktop has been tried with this package and works.
