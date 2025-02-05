#!/bin/bash

set -ex

# Services not started at all
removed_services=(
    dconf
    drkonqi-coredump-cleanup
    drkonqi-coredump-launcher@
    drkonqi-coredump-pickup
    drkonqi-sentry-postman
    filter-chain
    glib-pacrunner
    pipewire-pulse
    pipewire
    plasma-baloorunner
    plasma-dolphin
    plasma-kaccess
    plasma-kscreen-osd
    plasma-kscreen
    plasma-kwallet-pam
    plasma-kwin_x11
    plasma-xdg-desktop-portal-kde
    session-migration
    wireplumber
    wireplumber@
)
for service in "${removed_services[@]}"; do
    rm "usr/lib/systemd/user/$service.service"
done

# Services launched at session startup
rm "usr/lib/systemd/user/plasma-kwin_wayland.service"
ln -s "/etc/systemd/user/snap.plasma-desktop-session.plasma-kwin-wayland.service" "usr/lib/systemd/user/plasma-kwin_wayland.service"
mkdir "usr/lib/systemd/user/plasma-kwin_wayland.service.d"
cat >"usr/lib/systemd/user/plasma-kwin_wayland.service.d/override.conf"<<EOF
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
    rm "usr/lib/systemd/user/$service.service"
    ln -s "/etc/systemd/user/snap.plasma-desktop-session.$service.service" "usr/lib/systemd/user/$service.service"
    mkdir "usr/lib/systemd/user/$service.service.d"
    cat >"usr/lib/systemd/user/$service.service.d/override.conf"<<EOF
[Unit]
PartOf=graphical-session.target
EOF
done

# Services actually provided by the kf6 content snap
content_provided_services=(
    plasma-kded6
)
for service in "${content_provided_services[@]}"; do
    ln -s "/etc/systemd/user/snap.plasma-desktop-session.$service.service" "usr/lib/systemd/user/$service.service"
    mkdir "usr/lib/systemd/user/$service.service.d"
    cat >"usr/lib/systemd/user/$service.service.d/override.conf"<<EOF
[Unit]
PartOf=graphical-session.target
EOF
done

qdbus_oneshot_services=(
    plasma-kcminit-phase1
    plasma-ksplash-ready
    plasma-restoresession
)
for service in "${qdbus_oneshot_services[@]}"; do
    sed -i -E -e 's,/snap/kde-qt6-core.*?-sdk/current/usr/bin/qt6,/snap/kf6-core24/current/usr/bin/qt6,' "usr/lib/systemd/user/$service.service"
    echo >> "usr/lib/systemd/user/$service.service"
    echo 'Environment="LD_LIBRARY_PATH=/snap/kf6-core24/current/usr/lib/x86_64-linux-gnu/"' >> "usr/lib/systemd/user/$service.service"
done

