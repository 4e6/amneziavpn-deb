#!/bin/bash
# Build an Ubuntu .deb from the official AmneziaVPN Linux installer, optionally
# with a server config that each user's first launch imports and connects to.
#   ./build.sh ~/Downloads/AmneziaVPN_5.0.3.0_linux_x64.run                     # plain repack
#   ./build.sh ~/Downloads/AmneziaVPN_5.0.3.0_linux_x64.run ~/Downloads/server.conf
# Output: ./dist/amneziavpn_<version>-1_amd64.deb   (with a config: contains the private key!)
# Needs Docker (the installer is an x86-64 Linux binary, and dpkg-deb isn't on macOS).
set -euo pipefail

[ $# -eq 1 ] || [ $# -eq 2 ] || { echo "usage: $0 <AmneziaVPN_*.run> [config.conf]" >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
INSTALLER=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
MOUNTS=()
if [ $# -eq 2 ]; then
    CONF=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
    MOUNTS=(-v "$CONF":/in/config.conf:ro)
fi
mkdir -p "$HERE/dist"

docker build -q -t amneziavpn-deb-builder "$HERE" >/dev/null
docker run --rm \
    -v "$INSTALLER":/in/installer.run:ro \
    ${MOUNTS[@]+"${MOUNTS[@]}"} \
    -v "$HERE":/src:ro \
    -v "$HERE/dist":/out \
    amneziavpn-deb-builder bash /src/container-build.sh
