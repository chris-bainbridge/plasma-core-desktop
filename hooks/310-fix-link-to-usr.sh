#!/bin/bash

set -ex

rm -f usr/bin/lookandfeeltool
ln -sf plasma-apply-lookandfeel usr/bin/lookandfeeltool

rm -f usr/bin/kinfocenter
ln -sf systemsettings usr/bin/kinfocenter

desktop_files=(
    org.kde.dolphin.desktop
    systemsettings.desktop
)
for desktop_file in "${desktop_files[@]}"; do
    rm -f "usr/share/kglobalaccel/$desktop_file"
    ln -sf "../applications/$desktop_file" "usr/share/kglobalaccel/$desktop_file"
done

