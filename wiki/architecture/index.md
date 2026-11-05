# Module

- [Build pipeline](build-pipeline.md) - Runs the vendor installer headless in an amd64 container and assembles the .deb from its output, templates and the supplied config.
- [Launcher](launcher.md) - The /usr/bin/AmneziaVPN wrapper that imports the bundled server on a user's first run and connects, without ever importing twice.
- [Maintainer scripts](maintainer-scripts.md) - The deb's pre/post install and removal scripts: service lifecycle, cleanup of a vendor .run install, and removal of leftover kill-switch rules.
