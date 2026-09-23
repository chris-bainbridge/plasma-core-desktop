#!/bin/bash

set -ex

prefixes=(
    usr/share/applications
    usr/share/kglobalaccel
)
for prefix in "${prefixes[@]}"; do
    find "$prefix" \
        -type f \
        -name "*.desktop" \
        -exec bash -c "i=\$1; sed -i 's:^Exec=/:Exec[\$e]=\$SNAP/plasma/:g' \$i" shell {} \;
done

# Remove the discover entries from taskmanager launchers
# this is provided by a separate snap and might not be here
if [ -f usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml ]; then
    sed -i "s/applications:org.kde.discover.desktop,//" \
        usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
fi


