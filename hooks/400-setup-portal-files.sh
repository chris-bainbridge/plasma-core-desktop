#!/bin/bash

set -ex

cp /snap/kf6-core24-sdk/current/usr/share/xdg-desktop-portal/portals/kwallet.portal usr/share/xdg-desktop-portal/
mv usr/share/xdg-desktop-portal/portals/* usr/share/xdg-desktop-portal/
rmdir usr/share/xdg-desktop-portal/portals

