# amneziavpn-deb

Builds an Ubuntu `.deb` (22.04+, amd64) from the official AmneziaVPN Linux
installer plus a WireGuard/AmneziaWG `.conf`. After `apt install`, the service
is running and each user's first launch of the client imports the server.

    ./build.sh ~/Downloads/AmneziaVPN_5.0.3.0_linux_x64.run ~/Downloads/server.conf
    sudo apt install ./dist/amneziavpn_5.0.3.0-1_amd64.deb
    ./test-install.sh 22.04   # or 24.04: packaging + auto-import smoke test in Docker

## How AmneziaVPN works (what the package relies on)
- `AmneziaVPN-service` (root, systemd) owns the tunnel (`amneziawg-go`, OpenVPN,
  routes, kill-switch firewall). The GUI `AmneziaVPN` talks to it over
  `/var/run/amneziavpn/daemon.socket`.
- Servers live per user in `~/.config/AmneziaVPN.ORG/AmneziaVPN.conf` (plain JSON).
- The client has `--import <data>` and `--connect <index>`. `--import` is not
  idempotent, so `/usr/bin/AmneziaVPN` (a wrapper) only adds it when the config's
  peer PublicKey is absent from the user's settings.

## Behaviour / caveats
- The `.deb` contains the VPN private key and PSK; `/usr/share/amneziavpn/default.conf`
  is world-readable (0644) so every user's launcher can import it. Don't publish the `.deb`.
- A peer key is meant for one device at a time; don't install one `.deb` on several machines.
- If a user deletes the server in the app, it is re-imported on the next launch.
- The launcher also passes `--connect 0`, so the app connects to the first server on start.
  Pass your own `--connect N` to override. Whether closing the window disconnects is untested.
- The app's kill switch is on: while connected, other traffic is blocked. `prerm` removes
  the leftover firewall rules when the package is removed/upgraded.
- Installing over a vendor `.run` install cleans up `/opt/AmneziaVPN`, `/etc/systemd/system/AmneziaVPN.service`
  and `/usr/local/{bin,sbin}/AmneziaVPN`.
