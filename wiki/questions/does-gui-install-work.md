---
type: Open Question
title: Does installing through App Center or GDebi work?
description: The documented GUI install path (Open With → App Center, or GDebi) is based on 2024–2026 press coverage and has not been tried with this package.
tags: [install, gui, untested]
sources:
  - id: omgubuntu-2024
    resource: https://www.omgubuntu.co.uk/app-center-update-adds-deb-install-support
    title: App Center update adds DEB install support (OMG! Ubuntu, July 2024)
  - id: itsfoss-2026
    resource: https://itsfoss.com/news/ubuntu-26-04-deb-in-app-center/
    title: Ubuntu 26.04 shows deb packages in App Center (It's FOSS, March 2026)
---

# Question

Does installing the `.deb` with App Center (24.04, 26.04) or GDebi leave the
service active and enabled, and does the first launch still import the server?

# What is known

* An OMG! Ubuntu article (July 2024) says an App Center update brought back
  installing a side-loaded `.deb` on 24.04, by double-click or *Open With*.[^omgubuntu-2024]
* An It's FOSS article (March 2026) covers App Center listing deb packages from
  the repositories on 26.04. It says nothing about local files.[^itsfoss-2026]
* Nothing was found on how Ubuntu Software handles a local `.deb` on 22.04.

# How to answer

Use the VNC desktop from the [build and test playbook](/playbooks/build-and-test.md).
Open the `.deb` with App Center on 24.04, then check the same things as for an
`apt install`. Then update the [desktop install playbook](/playbooks/install-from-the-desktop.md).

[^omgubuntu-2024]: https://www.omgubuntu.co.uk/app-center-update-adds-deb-install-support
[^itsfoss-2026]: https://itsfoss.com/news/ubuntu-26-04-deb-in-app-center/
