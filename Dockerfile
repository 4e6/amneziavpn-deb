FROM --platform=linux/amd64 ubuntu:24.04

# Libraries the Qt Installer Framework binary needs to run headless, plus the
# packaging tools. Deliberately no sudo: the vendor's post_install.sh calls it
# and we want those calls to fail harmlessly inside the build container.
RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
      ca-certificates libxkbcommon-x11-0 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 \
      libxcb-keysyms1 libxcb-render-util0 libxcb-shape0 libxcb-xkb1 libxcb-cursor0 \
      libgl1 libegl1 libopengl0 libfontconfig1 libdbus-1-3 libglib2.0-0t64 \
      dpkg-dev file lintian \
 && rm -rf /var/lib/apt/lists/*
