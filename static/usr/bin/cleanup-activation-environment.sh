#!/bin/bash

set -x

dbus-update-activation-environment --systemd SNAP="" _KDE_APPLICATIONS_AS_FORKING=1

systemctl --user unset-environment \
    SNAP \
    SNAP_ARCH \
    SNAP_COMMON \
    SNAP_CONTEXT \
    SNAP_COOKIE \
    SNAP_DATA \
    SNAP_EUID \
    SNAP_INSTANCE_KEY \
    SNAP_INSTANCE_NAME \
    SNAP_LIBRARY_PATH \
    SNAP_NAME \
    SNAP_REAL_HOME \
    SNAP_REEXEC \
    SNAP_REVISION \
    SNAP_SAVE_DATA \
    SNAP_UID \
    SNAP_USER_COMMON \
    SNAP_USER_DATA \
    SNAP_VERSION

