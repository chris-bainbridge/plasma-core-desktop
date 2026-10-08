#!/bin/sh

set -ex

# Idempotent: a previous failed build can leave install-data/ behind
# (the Makefile's trailing `rm -rf install-data` only runs on success),
# and a stale kdesrc-build checkout makes the clone below fail. Only the
# kdesrc-build tool itself is removed; install-data/kde (cloned sources +
# build artifacts) is deliberately preserved so kdesrc-build can do
# incremental rebuilds across iterations.
rm -rf install-data/kdesrc-build install-data/kdesrc-buildrc
# kdesrc-build writes per-module build logs under install-data/kde/src/log
# with a log/latest/* symlink per module. snapcraft's make plugin later
# scans the tree for symlinks to copy and chokes (IsADirectoryError) on
# these directory symlinks if a previous build failed before the 999
# cleanup hook ran. Drop the stale log dir so it can't trip that up.
rm -rf install-data/kde/src/log

git clone --depth 1 https://invent.kde.org/sdk/kdesrc-build.git install-data/kdesrc-build

PLASMA_TAG=v6.7.5

cat >install-data/kdesrc-buildrc<<EOF
global
    branch-group stable-kf6-qt6
    include-dependencies false
    directory-layout flat
    stop-on-failure true

    install-dir /usr
    source-dir $CRAFT_PART_INSTALL/install-data/kde/src
    build-dir $CRAFT_PART_INSTALL/install-data/kde/build

    cmake-generator Ninja
    cmake-options -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DQT_MAJOR_VERSION=6 -DBUILD_WITH_QT6=ON -DCMAKE_C_COMPILER=gcc-14 -DCMAKE_CXX_COMPILER=g++-14 -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

    num-cores $(nproc)
    num-cores-low-mem $(nproc)

    install-session-driver false
    install-environment-driver false
end global

module xwaylandvideobridge
    repository kde:system/xwaylandvideobridge.git
end module

module-set kf6-extra-libs
    repository kde-projects
    use-modules kglobalacceld pulseaudio-qt
    cmake-options -DBUILD_WITH_QT6=ON
end module-set

options kglobalacceld
    tag $PLASMA_TAG
end options

module-set plasma-desktop-modules
    repository kde-projects
    cmake-options -DBUILD_WITH_QT6=ON -DBUILD_QT5=OFF
    use-modules workspace
    ignore-modules discover flatpak-kcm oxygen oxygen-sounds breeze breeze-grub breeze-plymouth breeze-gtk kde-gtk-config khotkeys kup plasma-mobile plasma-settings plasma-bigscreen aura-browser plank-player plasma-login-manager plasma-remotecontrollers plasma-meetings plasma-disks plasma-firewall plasma-setup plymouth-kcm krdp spectacle union plasma-keyboard kwin-x11 print-manager
    tag $PLASMA_TAG
end module-set

options kwin
    cmake-options -DBUILD_WITH_QT6=ON -DBUILD_QT5=OFF -DKWIN_BUILD_DECORATIONS=OFF
end options

options plasma-desktop
    cmake-options -DBUILD_KCM_TOUCHPAD_X11=OFF
end options

module-set base-application-modules
    repository kde-projects
    cmake-options -DBUILD_WITH_QT6=ON -DBUILD_QT5=OFF
    use-modules konsole dolphin
end module-set
EOF

# Make sure qmake is seen
ln -sf /snap/kde-qt6-core26-sdk/usr/bin/qt6/qmake /usr/bin/

# Needed for xmllint to work properly
for i in declaration entities ; do
    if [ -L "/usr/share/xml/$i" ] || [ -f "/usr/share/xml/$i" ]; then
        rm -f "/usr/share/xml/$i"
    elif [ -d "/usr/share/xml/$i" ]; then
        rmdir "/usr/share/xml/$i"
    fi
done
for i in declaration docbook entities qaml svg ; do
    ln -sf "/snap/kf6-core26-sdk/current/usr/share/xml/$i" /usr/share/xml/
done

# Needed for QCA to be found during build
ln -sf /snap/kf6-core26-sdk/current/usr/bin/qcatool-qt6 /usr/bin/
ln -sf /snap/kf6-core26-sdk/current/usr/include/Qca-qt6 /usr/include/
for i in /snap/kf6-core26-sdk/current/usr/lib/libqca-qt6.so* ; do
    ln -sf "$i" /usr/lib/
done

# QML module resolution. ecm_find_qmlmodule looks in
# KDE_INSTALL_FULL_QMLDIR (= /usr/lib/<triplet>/qml, i.e. CMAKE_INSTALL_PREFIX
# + KDE_INSTALL_QMLDIR) and QT_INSTALL_QML (= the Qt SDK's qt6/qml). But the
# modules actually land in two other places:
#   - the KF6 SDK ships its QML modules under usr/lib/<triplet>/qml/ (not
#     qt6/qml/), and
#   - the Plasma modules built by kdesrc-build install to
#     $DESTDIR/usr/lib/<triplet>/qml/ (DESTDIR = the part install dir, which
#     is this hook's CWD), not the container's /usr.
# So make /usr/lib/<triplet>/qml a symlink to the DESTDIR-prefixed install
# dir, and symlink the KF6 SDK modules into that same dir. Then both the
# KF6-provided and the freshly-built Plasma QML modules are found.
# The org.kde.plasma.plasmoid module is deliberately NOT symlinked: the
# KF6 SDK still ships the old plasma-framework copy, but Plasma 6.7.x
# builds its own (libplasma) copy, and both registering the same
# namespace is what caused the "already been used for type registration"
# black-screen failure. Leave that subdir for the Plasma build to create.
QML_TRIPLET="$(gcc -print-multiarch 2>/dev/null || echo x86_64-linux-gnu)"
KF6_QML="/snap/kf6-core26-sdk/current/usr/lib/${QML_TRIPLET}/qml"
INSTALL_QML="$PWD/usr/lib/${QML_TRIPLET}/qml"
mkdir -p "$INSTALL_QML/org/kde"
rm -rf "/usr/lib/${QML_TRIPLET}/qml"
ln -sfn "$INSTALL_QML" "/usr/lib/${QML_TRIPLET}/qml"
for i in "$KF6_QML"/org/kde/* ; do
    name="$(basename "$i")"
    # plasma and activities are also built by Plasma itself (libplasma /
    # plasma-activities), so leave those for the Plasma build.
    [ "$name" = plasma ] && continue
    [ "$name" = activities ] && continue
    # Copy (not symlink): Plasma's own modules extend some KF6 modules
    # (e.g. libplasma installs kirigami/styles/Plasma/ into kirigami), so
    # the KF6 dirs must be real/writable, not symlinks into the read-only
    # SDK snap. The 999 hook removes these copies before the snap is
    # finalised (the kf6-core26 runtime snap provides them at runtime).
    rm -rf "$INSTALL_QML/org/kde/$name"
    cp -a "$i" "$INSTALL_QML/org/kde/$name"
done
# org.kde.plasma.* is built entirely by Plasma 6.7.x itself (libplasma
# builds core/plasmoid, plasma-framework builds components/extras/
# configuration). The KF6 SDK still ships the old plasma-framework copies,
# but symlinking them here would make the Plasma build try to install its
# own copies into the read-only SDK snap ("Read-only file system"). Leave
# the whole org.kde.plasma subtree for the Plasma build to create.
