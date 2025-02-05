#!/bin/sh

set -ex

git clone https://invent.kde.org/sdk/kdesrc-build.git install-data/kdesrc-build

PLASMA_TAG=v6.2.5

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
    cmake-options -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DQT_MAJOR_VERSION=6 -DBUILD_WITH_QT6=ON

    num-cores $(nproc)
    num-cores-low-mem $(nproc)

    install-session-driver false
    install-environment-driver true
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
    ignore-modules discover flatpak-kcm kdecoration oxygen oxygen-sounds breeze breeze-grub breeze-plymouth breeze-gtk kde-gtk-config khotkeys plasma-mobile plasma-settings plasma-bigscreen aura-browser plank-player plasma-remotecontrollers plasma-meetings plasma-disks plasma-firewall plymouth-kcm milou krdp union plasma-keyboard
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
ln -sf /snap/kde-qt6-core24-sdk/usr/bin/qt6/qmake /usr/bin/

# Needed for xmllint to work properly
for i in declaration entities ; do
    rmdir "/usr/share/xml/$i"
done
for i in declaration docbook entities qaml svg ; do
    ln -sf "/snap/kf6-core24-sdk/current/usr/share/xml/$i" /usr/share/xml/
done

# Needed for QCA to be found during build
ln -sf /snap/kf6-core24-sdk/current/usr/bin/qcatool-qt6 /usr/bin/
ln -sf /snap/kf6-core24-sdk/current/usr/include/Qca-qt6 /usr/include/
for i in /snap/kf6-core24-sdk/current/usr/lib/libqca-qt6.so* ; do
    ln -sf "$i" /usr/lib/
done

