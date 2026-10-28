#!/bin/bash
# Build an Ubuntu .deb from the official AmneziaVPN Linux installer plus a config.
#   ./build.sh ~/Downloads/AmneziaVPN_5.0.3.0_linux_x64.run ~/Downloads/server.conf
# Output: ./dist/amneziavpn_<version>-1_amd64.deb   (contains the private key!)
# Needs Docker (the installer is an x86-64 Linux binary, and dpkg-deb isn't on macOS).
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: $0 <AmneziaVPN_*.run> <config.conf>" >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
INSTALLER=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
CONF=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
mkdir -p "$HERE/dist"

docker build -q -t amneziavpn-deb-builder "$HERE" >/dev/null
docker run --rm \
    -v "$INSTALLER":/in/installer.run:ro \
    -v "$CONF":/in/config.conf:ro \
    -v "$HERE":/src:ro \
    -v "$HERE/dist":/out \
    amneziavpn-deb-builder bash /src/container-build.sh
