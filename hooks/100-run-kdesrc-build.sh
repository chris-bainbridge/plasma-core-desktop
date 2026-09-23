#!/bin/sh

set -ex

# kdesrc-build writes per-module build logs under install-data/kde/src/log
# with a log/latest/* symlink per module. snapcraft's make plugin later
# scans the tree for symlinks to copy and chokes (IsADirectoryError) on
# these directory symlinks. Remove just the log/latest symlink dir on exit
# (success OR failure) so a failed build can't leave them behind for the
# next run, while keeping the per-module log files for diagnosis.
cleanup_log() {
    rm -rf install-data/kde/src/log/latest
}
trap cleanup_log EXIT

install-data/kdesrc-build/kdesrc-build --rc-file=./install-data/kdesrc-buildrc --src-only

# Forward-port patches for Plasma 6.7.5 against the core24 build env
# (e.g. PipeWire 1.2.6 vs the 1.4+ that 6.7.5 targets). See
# tools/patch-kdesrc-sources.py.
python3 "$CRAFT_PROJECT_DIR"/tools/patch-kdesrc-sources.py

install-data/kdesrc-build/kdesrc-build --rc-file=./install-data/kdesrc-buildrc --no-src
