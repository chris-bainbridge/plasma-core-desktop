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

# git shim: kdesrc-build hardwires `git clone --recursive [-b <tag>]` and
# has no shallow-clone option in this version (verified 2026-10-07 in
# ksb/Updater/Git.pm), and it clones everything from invent.kde.org --
# which that day served 0.8MB/s and truncated packs mid-transfer ("early
# EOF"), killing an entire 1.5h clone phase on one bad dolphin clone.
# This shim PATH-wraps git so every kdesrc-build clone is:
#   * shallow (--depth 1; kdesrc-build clones with -b <tag>, so the tag
#     itself is still fetched -- no history is needed to build packages)
#   * redirected from invent.kde.org / kde: URLs to the github.com/KDE
#     read-only mirror (fast CDN; proven to work that day when invent
#     was dropping transfers), falling back to the original URL if the
#     mirror doesn't have a repo.
# All non-clone git commands (fetch/checkout/describe/submodule) pass
# through untouched.
SHALLOW_GIT_BIN="${TMPDIR:-/tmp}/shallow-git-bin"
mkdir -p "$SHALLOW_GIT_BIN"
cat >"$SHALLOW_GIT_BIN/git" <<'WRAP'
#!/bin/bash
REAL_GIT="${SHIM_REAL_GIT:-/usr/bin/git}"
if [ "$1" != "clone" ]; then
    exec "$REAL_GIT" "$@"
fi
shift
arr=("$@")
# kdesrc-build always passes the URL after a `--` separator
# (git clone --recursive [-b ref] -- <url> <dest>); find it there.
url_idx=-1
url=
for i in "${!arr[@]}"; do
    if [ "${arr[$i]}" = "--" ]; then
        url_idx=$((i + 1))
        url=${arr[$url_idx]}
        break
    fi
done
if [ -z "$url" ]; then
    # Unexpected arg shape: still make the clone shallow, no rewrite.
    exec "$REAL_GIT" clone --depth 1 "${arr[@]}"
fi
case "$url" in
    kde:*|*invent.kde.org*)
        repo=${url##*/}
        repo=${repo%.git}
        mirror="https://github.com/KDE/${repo}.git"
        ;;
    *)
        mirror=
        ;;
esac
dest=${arr[${#arr[@]} - 1]}
attempt_mirror() {
    rm -rf "$dest"
    "$REAL_GIT" clone --depth 1 "${arr[@]}"
}
if [ -n "$mirror" ]; then
    arr[$url_idx]=$mirror
    if attempt_mirror; then
        exit 0
    fi
    echo "git-shim: mirror clone of $mirror failed; falling back to $url" >&2
    arr[$url_idx]=$url
fi
if attempt_mirror; then
    exit 0
fi
exit 1
WRAP
chmod +x "$SHALLOW_GIT_BIN/git"

# Clone/update all kdesrc-build sources. --src-only is resumable
# (already-updated modules are skipped on re-run), so a transient
# network failure on any single clone can be retried without redoing
# the ~1.5h of successful clones. Without this, one dropped connection
# aborts the whole phase (seen 2026-10-07: dolphin's initial clone
# failed after 47 modules had cloned successfully, killing the entire
# part build and forcing a full from-scratch redo).
attempt=1
max_attempts=5
while ! PATH="$SHALLOW_GIT_BIN:$PATH" install-data/kdesrc-build/kdesrc-build --rc-file=./install-data/kdesrc-buildrc --src-only; do
    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "kdesrc-build --src-only failed after $max_attempts attempts" >&2
        exit 1
    fi
    echo "kdesrc-build --src-only failed (attempt $attempt/$max_attempts), retrying in 30s" >&2
    attempt=$((attempt + 1))
    sleep 30
done

# Forward-port patches for Plasma 6.7.5 against the core26 build env
# (kameleon Rust-helper removal). See tools/patch-kdesrc-sources.py.
python3 "$CRAFT_PROJECT_DIR"/tools/patch-kdesrc-sources.py

PATH="$SHALLOW_GIT_BIN:$PATH" install-data/kdesrc-build/kdesrc-build --rc-file=./install-data/kdesrc-buildrc --no-src
