#!/bin/bash

set -ex

# Units to disable completely
disabled_units=(
    pipewire.service
    pipewire.socket
    pipewire-pulse.socket
    wireplumber.service
    wireplumber@.service
    snap.ubuntu-desktop-session.colord.service
    snap.ubuntu-desktop-session.gnome-terminal-server.service
    snap.ubuntu-desktop-session.ibus-gtk3-service.service
    snap.ubuntu-desktop-session.ibus-portal-service.service
    snap.ubuntu-desktop-session.ibus-service.service
    snap.ubuntu-desktop-session.nautilus-service.service
    snap.ubuntu-desktop-session.pipewire-pulse.pulse.socket
    snap.ubuntu-desktop-session.pipewire-pulse.service
    snap.ubuntu-desktop-session.pipewire.pipewire.socket
    snap.ubuntu-desktop-session.pipewire.service
    snap.ubuntu-desktop-session.screencast.service
    snap.ubuntu-desktop-session.wireplumber.service
    snap.ubuntu-desktop-session.xdg-desktop-portal-gnome.service
)
for unit in "${disabled_units[@]}"; do
    ln -sf /dev/null "usr/lib/systemd/user/$unit"
done

# Make sure we don't pollute xdg-desktop-portal environment
mkdir "usr/lib/systemd/user/xdg-desktop-portal.service.d"
cat >"usr/lib/systemd/user/xdg-desktop-portal.service.d/override.conf"<<EOF
[Service]
ExecStart=
ExecStart=/usr/libexec/xdg-desktop-portal --verbose
UnsetEnvironment=XDG_CONFIG_DIRS XDG_DATA_DIRS LD_LIBRARY_PATH PIPEWIRE_CONFIG_DIR
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games" "XDG_DATA_DIRS=/snap/plasma-core24-desktop/current/usr/share:"
EOF

