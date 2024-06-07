#! /bin/sh

SDDM_CONF=/etc/writable/sddm/sddm.conf

SDDM=/usr/bin/sddm
UBUNTU_INIT=/snap/ubuntu-core-desktop-init/current/bin/ubuntu_init

if [ -f $SDDM_CONF.orig ] ; then
    mv $SDDM_CONF.orig $SDDM_CONF
fi

if [ ! -f $UBUNTU_INIT ] ; then
    echo "Didn't find ubuntu_init, bailing out"
    exec $SDDM
    exit 0
fi

user_count=`grep '/home/' /var/lib/extrausers/passwd | wc -l`

if [ $user_count -lt 1 ] ; then
    mv $SDDM_CONF $SDDM_CONF.orig
    cat >$SDDM_CONF<<EOF
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --no-global-shortcuts --locale1
SessionDir=/usr/share/wayland-sessions-bootstrap

[Autologin]
User=root
Session=ubuntu-init-session
Relogin=true
EOF
fi

exec $SDDM
