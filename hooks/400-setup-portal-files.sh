#!/bin/bash

set -ex

# The deb closure stages kwallet.portal (kf6-kwallet) and kde.portal
# (xdg-desktop-portal-kde) under portals/; the portal config in
# xdg-desktop-portal looks for them directly under
# usr/share/xdg-desktop-portal, so flatten (the source build copied
# kwallet.portal out of the kf6 SDK instead -- same end state).
if [ -d usr/share/xdg-desktop-portal/portals ]; then
    mv usr/share/xdg-desktop-portal/portals/* usr/share/xdg-desktop-portal/ 2>/dev/null || true
    rmdir usr/share/xdg-desktop-portal/portals 2>/dev/null || true
fi

