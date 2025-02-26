#!/bin/bash

set -ex

rm usr/bin/lookandfeeltool
ln -s plasma-apply-lookandfeel usr/bin/lookandfeeltool

rm usr/bin/kinfocenter
ln -s systemsettings usr/bin/kinfocenter

desktop_files=(
    org.kde.dolphin.desktop
    systemsettings.desktop
)
for desktop_file in "${desktop_files[@]}"; do
    rm "usr/share/kglobalaccel/$desktop_file"
    ln -s "../applications/$desktop_file" "usr/share/kglobalaccel/$desktop_file"
done

