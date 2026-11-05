#!/bin/bash
# Smoke-test the built .deb in a clean Ubuntu container (no systemd, no TUN, so
# this checks packaging, the auto-import and which arguments the launcher passes,
# NOT that the tunnel connects). A plain repack (built without a config) is checked
# to import nothing; an --autoconnect build to pass `--connect 0` exactly once.
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
ls -l /usr/bin/AmneziaVPN /usr/lib/systemd/system/AmneziaVPN.service \
      /usr/share/applications/AmneziaVPN.desktop /usr/share/pixmaps/AmneziaVPN.png
CONF=/usr/share/amneziavpn/default.conf
if [ -e $CONF ]; then ls -l $CONF; else echo "no bundled server config (plain repack)"; fi
ls /opt/AmneziaVPN
[ ! -e /opt/AmneziaVPN/maintenancetool ] && echo "no maintenancetool (good)"
[ ! -e /usr/local/bin/AmneziaVPN ] && echo "nothing shadowing the launcher in /usr/local/bin (good)"

useradd -m tester
step "launcher arguments (installed launcher, stubbed client; prints counts only, never the arguments)"
cat > /tmp/stub <<'STUB'
#!/bin/sh
imp=no; c0=0; prev=
for a in "$@"; do
    case "$a" in --import|--import=*) imp=yes ;; esac
    [ "$prev" = --connect ] && [ "$a" = 0 ] && c0=$((c0 + 1))
    case "$a" in --connect=0) c0=$((c0 + 1)) ;; esac
    prev=$a
done
echo "import: $imp, connect-0 count: $c0" > /tmp/stub.out
STUB
sed 's|^APP=.*|APP=/tmp/stub|' /usr/bin/AmneziaVPN > /tmp/launcher
chmod 0755 /tmp/stub /tmp/launcher
chmod 1777 /tmp
grep -q '^APP=/tmp/stub$' /tmp/launcher || { echo "FAIL: could not point the launcher at the stub"; exit 1; }
# Expected values come from the package itself: does it bundle a server, and was it built with --autoconnect?
AC=$(sed -n 's/^AUTOCONNECT=//p' /usr/bin/AmneziaVPN)
echo "built with AUTOCONNECT=$AC"
if [ -e $CONF ]; then IMP=yes; else IMP=no; fi
if [ $IMP = yes ] && [ "$AC" = 1 ]; then C0=1; else C0=0; fi
expect() {
    want=$1; shift
    rm -f /tmp/stub.out; su tester -c "sh /tmp/launcher $*"
    got=$(cat /tmp/stub.out)
    printf '%-12s -> %s\n' "${*:-(no args)}" "$got"
    [ "$got" = "$want" ] || { echo "FAIL: expected '$want'"; exit 1; }
}
expect "import: $IMP, connect-0 count: $C0"
expect "import: $IMP, connect-0 count: 0" --connect 2
expect "import: no, connect-0 count: 0" --help
[ ! -e /home/tester/.config/AmneziaVPN.ORG/AmneziaVPN.conf ] || { echo "FAIL: the stub run wrote settings"; exit 1; }
echo "settings untouched by the stub (good)"

step "first launch as an unprivileged user, twice"
S=/home/tester/.config/AmneziaVPN.ORG/AmneziaVPN.conf
run() { su tester -c "export QT_QPA_PLATFORM=xcb; xvfb-run -a timeout -s INT 20 AmneziaVPN" >/dev/null 2>&1 || true; }
servers() { grep -so 'storageServerId' $S | wc -l; }
if [ -e $CONF ]; then
    PUB=$(sed -n 's/^[[:space:]]*PublicKey[[:space:]]*=[[:space:]]*//p' $CONF | head -n1)
    run; echo "after launch 1: $(servers) server(s), pubkey present: $(grep -cF "$PUB" $S)"
    run; echo "after launch 2: $(servers) server(s)"
    grep -E '^defaultServerId' $S
else
    run; echo "after launch 1: $(servers) server(s)"
    run; echo "after launch 2: $(servers) server(s)"
    [ "$(servers)" = 0 ] && echo "nothing imported (good)"
fi
[ -e $S ] && stat -c '%a %U %n' $S || echo "(no settings file written)"

step "dpkg --purge leaves nothing behind"
dpkg --purge amneziavpn >/dev/null 2>&1
for p in /opt/AmneziaVPN /usr/bin/AmneziaVPN /usr/share/amneziavpn /usr/lib/systemd/system/AmneziaVPN.service \
         /usr/share/applications/AmneziaVPN.desktop /usr/share/pixmaps/AmneziaVPN.png /var/log/AmneziaVPN; do
    [ -e "$p" ] && echo "LEFTOVER: $p"
done
dpkg -l amneziavpn 2>&1 | tail -1
echo "purge check done"
EOF
