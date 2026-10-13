#!/bin/bash
# Build the plasma-core26-desktop runtime content snap for CI
# (chris-bainbridge/plasma-core-desktop, desktop/26).
#
# Mirrors the local go-build recipe minus the local-dev build-user/lock/
# proxy wrappers (none of which apply on a GitHub-hosted runner).
set -euo pipefail

rm -f snapd_*.snap plasma-*.snap
snapcraft pack |& tee build.log
mv plasma-*.snap plasma-core-desktop.snap
