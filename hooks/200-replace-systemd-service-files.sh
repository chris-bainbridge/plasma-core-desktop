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
    user-session-migration
    # The xdg-desktop-portal DAEMON (and friends) come from the base at
    # runtime; hook 250 keeps a drop-in for xdg-desktop-portal.service.
    # These units only exist in the prime because the deb closure pulls
    # the daemon packages (the source build never staged them).
    xdg-desktop-portal
    xdg-desktop-portal-rewrite-launchers
    xdg-document-portal
    xdg-permission-store
    kio-fuse
    appmenu-gtk-module
    obex
    dbus-org.bluez.obex
    mpris-proxy
)
for service in "${removed_services[@]}"; do
    rm -f "usr/lib/systemd/user/$service.service"
done
# The Sentry sender service is intentionally omitted because its runtime
# dependencies are not included in this content snap. Remove its path and
# timer triggers as well so systemd does not try to start a nonexistent
# service for users with pending crash envelopes.
for unit in drkonqi-sentry-postman.path drkonqi-sentry-postman.timer; do
    rm -f "usr/lib/systemd/user/$unit"
    find usr/lib/systemd/user -type l -name "$unit" -delete
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
    if [ "$service" = plasma-polkit-agent ]; then
        printf '%s\n' 'ConditionUser=!sddm' \
            >>"usr/lib/systemd/user/snap.plasma-desktop-session.$service.service.d/override.conf"
    fi
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
    # These oneshots invoke a qdbus client. The source build substituted a
    # build-tree path for the binary (e.g.
    # /root/stage/sdk-stage/kde-qt6-core26-sdk/usr/bin/qt6/qdbus) which the
    # old hook rewrote to the kf6-core26 content snap. The Neon debs ship
    # standard paths instead (/usr/bin/qdbus-qt6, /usr/lib/qt6/bin/qdbus,
    # /usr/bin/qdbus6) which resolve against the core26 base at runtime and
    # don't exist there. Rewrite any qdbus invocation to the kf6-core26
    # content snap's qt6-tools qdbus6 binary, preserving arguments, and fix
    # LD_LIBRARY_PATH to the same content snap.
    sed -i -E \
        -e 's|^(ExecStart=[^ ]*/qdbus[^ ]*)(.*)$|ExecStart=/snap/kf6-core26/current/usr/bin/qdbus6\2|' \
        -e 's,/snap/kf6-core24/current/usr/lib/x86_64-linux-gnu/,/snap/kf6-core26/current/usr/lib/x86_64-linux-gnu/,' \
        "usr/lib/systemd/user/$service.service"
    echo >> "usr/lib/systemd/user/$service.service"
    echo 'Environment="LD_LIBRARY_PATH=/snap/kf6-core26/current/usr/lib/x86_64-linux-gnu/"' >> "usr/lib/systemd/user/$service.service"
done

# Break the systemd ordering deadlock that leaves the desktop black.
# plasma-workspace.target BindsTo=graphical-session.target, and BindsTo=
# on a target implies an implicit After= edge, so plasma-workspace.target
# waits for graphical-session.target to be active. But it also declares
# Before=graphical-session.target, which makes graphical-session.target
# wait for plasma-workspace.target in return. With nothing else pulling
# graphical-session.target in first (on stock KDE the display
# manager/session bootstrap activates it before startplasma runs; in the
# confined snap path nothing does), systemd deadlocks: graphical-session.target
# waits for plasma-workspace.target, which waits for plasma-core.target,
# which waits for plasmashell, which blocks on the xdg-desktop-portal
# service, which waits for graphical-session.target. Neither target ever
# activates and the desktop stays black.
# Dropping the explicit Before=graphical-session.target breaks the cycle
# deterministically: graphical-session.target then activates as a plain
# dependency (Requires=) of plasma-workspace.target, the portal starts,
# plasmashell's portal calls succeed, and the workspace chain completes.
# The BindsTo= cleanup binding (workspace stops when the session ends) is
# kept; the only lost ordering is that graphical-session.target is
# reached before the workspace services are fully up, which nothing
# depends on here (restoresession/xdg-desktop-autostart still order after
# plasma-workspace.target via its remaining Before= entries).
sed -i -E '/^Before=graphical-session\.target$/d' "usr/lib/systemd/user/plasma-workspace.target"
