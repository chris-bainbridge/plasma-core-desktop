#!/bin/bash

set -ex

cp /snap/kf6-core26-sdk/current/usr/share/xdg-desktop-portal/portals/kwallet.portal usr/share/xdg-desktop-portal/
if [ -d usr/share/xdg-desktop-portal/portals ]; then
    mv usr/share/xdg-desktop-portal/portals/* usr/share/xdg-desktop-portal/ 2>/dev/null || true
    rmdir usr/share/xdg-desktop-portal/portals 2>/dev/null || true
fi

