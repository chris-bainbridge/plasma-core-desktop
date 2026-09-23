#!/bin/sh

set -ex

rm -r install-data/kde
rm -r install-data/kdesrc-build
rm install-data/kdesrc-buildrc

# The 000 hook copied the KF6 SDK's QML modules into
# usr/lib/<triplet>/qml/org/kde/ so ecm_find_qmlmodule could find them at
# configure time and Plasma's own modules could extend them. Those are
# build-time-only (the kf6-core26 runtime snap provides them at runtime),
# so drop the copies, leaving only the Plasma modules that kdesrc-build
# installed there. Also drop any leftover symlinks (from older builds).
QML_TRIPLET="$(gcc -print-multiarch 2>/dev/null || echo x86_64-linux-gnu)"
KF6_QML="/snap/kf6-core26-sdk/current/usr/lib/${QML_TRIPLET}/qml"
for i in "$KF6_QML"/org/kde/* ; do
    name="$(basename "$i")"
    [ "$name" = plasma ] && continue
    [ "$name" = activities ] && continue
    # private is shared: the KF6 SDK ships org/kde/private/kquickcontrols,
    # but Plasma's own modules (e.g. plasma-desktop's folderplugin) install
    # into org/kde/private/desktopcontainment/. Removing the whole private
    # tree would wipe those Plasma modules, so only drop the KF6-provided
    # kquickcontrols subdir (the kf6-core26 runtime snap provides it).
    [ "$name" = private ] && continue
    rm -rf "usr/lib/${QML_TRIPLET}/qml/org/kde/$name"
done
rm -rf "usr/lib/${QML_TRIPLET}/qml/org/kde/private/kquickcontrols"
find "usr/lib/${QML_TRIPLET}/qml" -type l -delete 2>/dev/null || true

