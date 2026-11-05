#!/bin/bash
# Runs inside the build container (see build.sh). Inputs are mounted read-only:
#   /in/installer.run  vendor installer      /in/config.conf  AmneziaWG/WireGuard config (optional)
#   /src               this directory        /out             where the .deb goes
# Env: AUTOCONNECT=1 makes the launcher connect to the bundled server on start (needs a config).
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

# --- validate the config, if one was given -----------------------------------
WITH_CONF=0
if [ -e /in/config.conf ]; then
    WITH_CONF=1
    grep -q '^\[Interface\]' /in/config.conf || die "config has no [Interface] section"
    grep -q '^\[Peer\]'      /in/config.conf || die "config has no [Peer] section"
    grep -Eq '^[[:space:]]*PrivateKey[[:space:]]*=' /in/config.conf || die "config has no PrivateKey"
    grep -Eq '^[[:space:]]*PublicKey[[:space:]]*='  /in/config.conf || die "config has no peer PublicKey (the launcher keys off it)"
fi

AUTOCONNECT=${AUTOCONNECT:-0}
case $AUTOCONNECT in 0|1) ;; *) die "AUTOCONNECT must be 0 or 1" ;; esac
[ "$AUTOCONNECT" = 0 ] || [ "$WITH_CONF" = 1 ] || die "AUTOCONNECT=1 needs a config to connect to"

# --- run the vendor installer headless into a scratch root -------------------
# Native container filesystem, not a macOS bind mount: keeps case-sensitivity,
# symlinks and file modes intact.
INST=/build/inst
mkdir -p /build
export QT_QPA_PLATFORM=minimal
cp /in/installer.run /build/installer.run   # the mount is read-only and may lack +x
chmod +x /build/installer.run
if ! /build/installer.run --root "$INST" --accept-licenses --confirm-command --default-answer install \
      >/build/installer.log 2>&1; then
    tail -30 /build/installer.log >&2
    die "vendor installer failed"
fi
[ -x "$INST/bin/AmneziaVPN" ] || { tail -30 /build/installer.log >&2; die "installer produced no bin/AmneziaVPN"; }

VERSION=$(sed -n 's:.*<Version>\(.*\)</Version>.*:\1:p' "$INST/components.xml" | head -n 1)
[ -n "$VERSION" ] || die "could not read version from components.xml"
echo "AmneziaVPN $VERSION"

# --- assemble the package tree -----------------------------------------------
ROOT=/build/root
rm -rf "$ROOT"
install -d "$ROOT/opt" "$ROOT/usr/bin" "$ROOT/usr/lib/systemd/system" \
           "$ROOT/usr/share/applications" "$ROOT/usr/share/pixmaps" \
           "$ROOT/usr/share/doc/amneziavpn" "$ROOT/DEBIAN"
mv "$INST" "$ROOT/opt/AmneziaVPN"
APP="$ROOT/opt/AmneziaVPN"

# Installer-framework leftovers. maintenancetool would let a user uninstall
# behind dpkg's back; post_*.sh are replaced by the maintainer scripts.
rm -rf "$APP"/maintenancetool "$APP"/maintenancetool.dat "$APP"/maintenancetool.ini \
       "$APP"/installer.dat "$APP"/installerResources "$APP"/network.xml \
       "$APP"/components.xml "$APP"/InstallationLog.txt \
       "$APP"/post_install.sh "$APP"/post_uninstall.sh

install -m 0644 "$APP/AmneziaVPN.service" "$ROOT/usr/lib/systemd/system/AmneziaVPN.service"
install -m 0644 "$APP/AmneziaVPN.png"     "$ROOT/usr/share/pixmaps/AmneziaVPN.png"
rm -f "$APP/AmneziaVPN.service" "$APP/AmneziaVPN.png" "$APP/AmneziaVPN.desktop"

sed "s/@AUTOCONNECT@/$AUTOCONNECT/" /src/pkg/AmneziaVPN > "$ROOT/usr/bin/AmneziaVPN"
chmod 0755 "$ROOT/usr/bin/AmneziaVPN"
! grep -q '@AUTOCONNECT@' "$ROOT/usr/bin/AmneziaVPN" || die "launcher placeholder was not substituted"
install -m 0644 /src/pkg/AmneziaVPN.desktop "$ROOT/usr/share/applications/AmneziaVPN.desktop"
install -m 0644 /src/pkg/copyright          "$ROOT/usr/share/doc/amneziavpn/copyright"
if [ "$WITH_CONF" = 1 ]; then
    # World-readable on purpose: every local user's launcher must be able to read it.
    install -d "$ROOT/usr/share/amneziavpn"
    install -m 0644 /in/config.conf "$ROOT/usr/share/amneziavpn/default.conf"
    CHANGE="Repackage the official AmneziaVPN $VERSION Linux installer with a pre-imported server."
    [ "$AUTOCONNECT" = 0 ] || CHANGE="$CHANGE The launcher connects to it on start."
    DESCRIPTION="Amnezia VPN client with a pre-imported server configuration
 Repackaging of the official AmneziaVPN Linux installer as a .deb. The
 privileged AmneziaVPN-service daemon is registered as a systemd unit, and
 the bundled server configuration is imported into each user's client the
 first time they launch it, so the VPN can be connected right away.
 .
 The package contains a VPN private key. Treat the .deb as a secret."
else
    CHANGE="Repackage the official AmneziaVPN $VERSION Linux installer."
    DESCRIPTION="Amnezia VPN client
 Repackaging of the official AmneziaVPN Linux installer as a .deb. The
 privileged AmneziaVPN-service daemon is registered as a systemd unit."
fi
printf 'amneziavpn (%s-1) unstable; urgency=medium\n\n  * %s\n\n -- Dmitry Bushev  %s\n' \
    "$VERSION" "$CHANGE" "$(date -R)" | gzip -9n > "$ROOT/usr/share/doc/amneziavpn/changelog.Debian.gz"

# Normalise permissions: nothing group/world-writable, dirs traversable.
find "$ROOT" -type d -exec chmod 0755 {} +
find "$ROOT/opt" -type f -perm /u+x -exec chmod 0755 {} +
find "$ROOT/opt" -type f ! -perm /u+x -exec chmod 0644 {} +

# --- control data ------------------------------------------------------------
SIZE=$(du -sk --exclude=DEBIAN "$ROOT" | cut -f1)
{ sed -e "s/@VERSION@/$VERSION/" -e "s/@SIZE@/$SIZE/" /src/pkg/DEBIAN/control
  printf 'Description: %s\n' "$DESCRIPTION"; } > "$ROOT/DEBIAN/control"
for s in preinst postinst prerm postrm; do install -m 0755 "/src/pkg/DEBIAN/$s" "$ROOT/DEBIAN/$s"; done
(cd "$ROOT" && find . -type f ! -path './DEBIAN/*' -printf '%P\0' | sort -z | xargs -0 md5sum) > "$ROOT/DEBIAN/md5sums"

# --- build -------------------------------------------------------------------
DEB="/out/amneziavpn_${VERSION}-1_amd64.deb"
dpkg-deb --root-owner-group -Zxz -b "$ROOT" "$DEB"
if [ "$WITH_CONF" = 1 ]; then
    chmod 0600 "$DEB"   # contains the VPN private key
else
    chmod 0644 "$DEB"
fi
echo "built $DEB ($(du -h "$DEB" | cut -f1))"

echo "--- lintian (informational) ---"
lintian --tag-display-limit 0 "$DEB" 2>&1 | grep -vE 'dir-or-file-in-opt|embedded-library|statically-linked|binary-without-manpage|no-manual-page|hardening-no|unstripped|shared-library-lacks|library-not-linked|no-symbols-control|shlib' | head -40 || true
