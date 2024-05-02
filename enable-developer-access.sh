#! /bin/sh

SCRIPT_PATH=`readlink -f $0`
SCRIPT_DIR=`dirname $SCRIPT_PATH`

set -x

cp $SCRIPT_DIR/attic/snap-connections.txt $SCRIPT_DIR
cp $SCRIPT_DIR/attic/007-zzz-add-extra-developer-tools.chroot $SCRIPT_DIR/hooks
cp $SCRIPT_DIR/attic/999-zzz-passwordless-root-on-serial.chroot $SCRIPT_DIR/hooks

