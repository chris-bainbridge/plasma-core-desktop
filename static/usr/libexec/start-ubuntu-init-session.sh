#! /bin/sh

UBUNTU_INIT=/snap/ubuntu-core-desktop-init/current/bin/ubuntu_init
START_SWAYBG=/usr/libexec/start-swaybg.sh

kwin_wayland \
    --no-lockscreen \
    --no-global-shortcuts \
    --locale1 \
    --exit-with-session $UBUNTU_INIT \
    $START_SWAYBG
systemctl restart sddm

