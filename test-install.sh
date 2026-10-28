#!/bin/bash
# Smoke-test the built .deb in a clean Ubuntu container (no systemd, no TUN, so
# this checks packaging and the auto-import, NOT that the tunnel connects).
#   ./test-install.sh 22.04|24.04 [path/to/amneziavpn_*.deb]
set -euo pipefail
REL=${1:?usage: $0 <ubuntu release> [deb]}
HERE=$(cd "$(dirname "$0")" && pwd)
DEB=${2:-$(ls -t "$HERE"/dist/amneziavpn_*.deb | head -n1)}

docker run --rm -i --platform linux/amd64 -v "$DEB":/tmp/pkg.deb:ro "ubuntu:$REL" bash -s <<'EOF'
set -eu
export DEBIAN_FRONTEND=noninteractive
step() { printf '\n== %s\n' "$*"; }

apt-get update -qq >/dev/null
apt-get install -y -qq xvfb xauth >/dev/null     # test-only: a fake X server
step "apt install ./pkg.deb (dependency resolution)"
cp /tmp/pkg.deb /root/pkg.deb
apt-get install -y -qq /root/pkg.deb >/dev/null && echo ok
dpkg -s amneziavpn | grep -E '^(Status|Version)'

step "unresolved shared libraries (core binaries + xcb platform plugin + qml/imageformat plugins)"
export LD_LIBRARY_PATH=/opt/AmneziaVPN/lib
miss=0
for f in /opt/AmneziaVPN/bin/AmneziaVPN /opt/AmneziaVPN/bin/AmneziaVPN-service /opt/AmneziaVPN/bin/openvpn \
         /opt/AmneziaVPN/plugins/platforms/libqxcb.so /opt/AmneziaVPN/plugins/imageformats/libqsvg.so \
         /opt/AmneziaVPN/plugins/tls/libqopensslbackend.so; do
    [ -e "$f" ] || { echo "(absent: $f)"; continue; }
    out=$(ldd "$f" 2>&1 | grep -E 'not found|not a dynamic' || true)
    [ -z "$out" ] || { echo "$f:"; echo "$out"; miss=1; }
done
[ $miss = 0 ] && echo "none missing"

step "files"
ls -l /usr/bin/AmneziaVPN /usr/share/amneziavpn/default.conf /usr/lib/systemd/system/AmneziaVPN.service \
      /usr/share/applications/AmneziaVPN.desktop /usr/share/pixmaps/AmneziaVPN.png
ls /opt/AmneziaVPN
[ ! -e /opt/AmneziaVPN/maintenancetool ] && echo "no maintenancetool (good)"
[ ! -e /usr/local/bin/AmneziaVPN ] && echo "nothing shadowing the launcher in /usr/local/bin (good)"

step "first launch as an unprivileged user, twice"
useradd -m tester
S=/home/tester/.config/AmneziaVPN.ORG/AmneziaVPN.conf
run() { su tester -c "export QT_QPA_PLATFORM=xcb; xvfb-run -a timeout -s INT 20 AmneziaVPN" >/dev/null 2>&1 || true; }
PUB=$(sed -n 's/^[[:space:]]*PublicKey[[:space:]]*=[[:space:]]*//p' /usr/share/amneziavpn/default.conf | head -n1)
run; echo "after launch 1: $(grep -o 'storageServerId' $S | wc -l) server(s), pubkey present: $(grep -cF "$PUB" $S)"
run; echo "after launch 2: $(grep -o 'storageServerId' $S | wc -l) server(s)"
grep -E '^defaultServerId' $S
stat -c '%a %U %n' $S

step "dpkg --purge leaves nothing behind"
dpkg --purge amneziavpn >/dev/null 2>&1
for p in /opt/AmneziaVPN /usr/bin/AmneziaVPN /usr/share/amneziavpn /usr/lib/systemd/system/AmneziaVPN.service \
         /usr/share/applications/AmneziaVPN.desktop /usr/share/pixmaps/AmneziaVPN.png /var/log/AmneziaVPN; do
    [ -e "$p" ] && echo "LEFTOVER: $p"
done
dpkg -l amneziavpn 2>&1 | tail -1
echo "purge check done"
EOF
