#!/bin/bash

set -ex

# Don't require password on the lockscreen
cat >"etc/xdg/kscreenlockerrc"<<EOF
[Daemon]
RequirePassword[\$i]=false
EOF

