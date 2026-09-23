#!/bin/bash

set -ex

# Services not started at all
removed_services=(
    dconf
    drkonqi-coredump-cleanup
    drkonqi-coredump-launcher@
    drkonqi-coredump-pickup
    drkonqi-sentry-postman
    glib-pacrunner
    plasma-baloorunner
    plasma-dolphin
    plasma-kaccess
    plasma-knighttimed
    plasma-kscreen-osd
    plasma-kscreen
    plasma-kwallet-pam
    plasma-kwin_x11
    plasma-startupsound
    plasma-xdg-desktop-portal-kde
    session-migration
)
for service in "${removed_services[@]}"; do
    rm -f "usr/lib/systemd/user/$service.service"
done

# Services launched at session startup
rm -f "usr/lib/systemd/user/plasma-kwin_wayland.service"
sed -i -E -e "s,plasma-kwin_wayland.service,snap.plasma-desktop-session.plasma-kwin-wayland.service," usr/lib/systemd/user/*.target
mkdir -p "usr/lib/systemd/user/snap.plasma-desktop-session.plasma-kwin-wayland.service.d"
cat >"usr/lib/systemd/user/snap.plasma-desktop-session.plasma-kwin-wayland.service.d/override.conf"<<EOF
[Unit]
PartOf=graphical-session.target
EOF
snapped_services=(
    plasma-gmenudbusmenuproxy
    plasma-kactivitymanagerd
    plasma-kcminit
    plasma-kglobalaccel
    plasma-krunner
    plasma-ksmserver
    plasma-ksplash
    plasma-ksystemstats
    plasma-plasmashell
    plasma-polkit-agent
    plasma-powerdevil
    plasma-xembedsniproxy
)
for service in "${snapped_services[@]}"; do
    rm -f "usr/lib/systemd/user/$service.service"
    sed -i -E -e "s,$service.service,snap.plasma-desktop-session.$service.service," usr/lib/systemd/user/*.target
    mkdir -p "usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d"
    cat >"usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d/override.conf"<<EOF
[Unit]
After=snap.plasma-desktop-session.plasma-kwin-wayland.service
PartOf=graphical-session.target
EOF
done

# Services provided by the kf6 content snap
content_provided_services=(
    plasma-kded6
)
for service in "${content_provided_services[@]}"; do
    sed -i -E -e "s,$service.service,snap.plasma-desktop-session.$service.service," usr/lib/systemd/user/*.target
    mkdir -p "usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d"
    cat >"usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d/override.conf"<<EOF
[Unit]
After=snap.plasma-desktop-session.plasma-kwin-wayland.service
PartOf=graphical-session.target
EOF
done

kwin_restart_services=(
    plasma-kactivitymanagerd
    plasma-kded6
    plasma-ksmserver
    plasma-plasmashell
    plasma-powerdevil
)
for service in "${kwin_restart_services[@]}"; do
    cat >>"usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d/override.conf"<<EOF
[Unit]
PartOf=snap.plasma-desktop-session.plasma-kwin-wayland.service
EOF
done

long_start_services=(
    plasma-kactivitymanagerd
    plasma-kded6
    plasma-ksmserver
    plasma-plasmashell
    plasma-powerdevil
)
for service in "${long_start_services[@]}"; do
    cat >>"usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d/override.conf"<<EOF
[Service]
TimeoutStartSec=180
EOF
done

mkdir -p "usr/lib/systemd/user/snap.plasma-desktop-session.xdg-desktop-portal-kde.service.d"
cat >"usr/lib/systemd/user/snap.plasma-desktop-session.xdg-desktop-portal-kde.service.d/override.conf"<<EOF
[Unit]
After=snap.plasma-desktop-session.plasma-kwin-wayland.service
PartOf=graphical-session.target snap.plasma-desktop-session.plasma-kwin-wayland.service
[Service]
TimeoutStartSec=180
EOF

qdbus_oneshot_services=(
    plasma-kcminit-phase1
    plasma-ksplash-ready
    plasma-restoresession
)
for service in "${qdbus_oneshot_services[@]}"; do
    [ -f "usr/lib/systemd/user/$service.service" ] || continue
    sed -i -E -e 's,/snap/kde-qt6-core.*?-sdk/current/usr/bin/qt6,/snap/kf6-core24/current/usr/bin/qt6,' "usr/lib/systemd/user/$service.service"
    echo >> "usr/lib/systemd/user/$service.service"
    echo 'Environment="LD_LIBRARY_PATH=/snap/kf6-core24/current/usr/lib/x86_64-linux-gnu/"' >> "usr/lib/systemd/user/$service.service"
done
