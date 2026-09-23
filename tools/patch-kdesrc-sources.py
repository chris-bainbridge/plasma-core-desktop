#!/usr/bin/env python3

"""Forward-port patches for Plasma 6.7.5 against the core26 build env.

Plasma 6.7.5 targets PipeWire >= 1.4, which core26 (Ubuntu 26.04) ships,
so the core24-only pw_stream_queue_buffer -> pw_stream_return_buffer
remap is no longer needed and has been dropped. The kdeplasma-addons
kameleon Rust-helper removal remains: the build container still has no
working cargo/crates.io access regardless of base.

Also includes a data fix (not a forward-port): the Breeze look-and-feel
packages' default wallpaper name ("Next") is never actually shipped by
Ubuntu, which permanently breaks the desktop wallpaper/first-paint on a
fresh profile -- see the Image=Next -> Image=Autumn patch below.
"""

from pathlib import Path


def remove_once(path: Path, snippet: str) -> None:
    text = path.read_text()
    if snippet not in text:
        # Already removed (idempotent across incremental rebuilds).
        return
    path.write_text(text.replace(snippet, "", 1))


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if old not in text:
        # Already replaced (idempotent across incremental rebuilds).
        return
    path.write_text(text.replace(old, new, 1))


def main() -> None:
    source_root = Path("install-data/kde/src")

    # kdeplasma-addons' kameleon kded module (RGB keyboard LED accent
    # colouring) pulls in a Rust helper via Corrosion. The build container
    # has no working cargo/crates.io access, and this niche addon isn't
    # needed for a minimal Plasma desktop, so drop the Rust helper.
    kameleon = source_root / "kdeplasma-addons/kdeds/kameleon/CMakeLists.txt"
    remove_once(
        kameleon,
        "if(NOT CMAKE_SYSTEM_NAME MATCHES FreeBSD)\n    add_subdirectory(qmk/kameleon-qmk-helper)\nendif()\n",
    )
    # The top-level CMakeLists still requires Corrosion unconditionally
    # (the only consumer was the kameleon-qmk-helper subdir removed above).
    kdeplasma_addons = source_root / "kdeplasma-addons/CMakeLists.txt"
    remove_once(
        kdeplasma_addons,
        "find_package(Corrosion REQUIRED)\n",
    )

    # kwin 6.7.5 requires wayland-protocols >= 1.48 (for the new
    # xdg-session-management protocol), but the core26 SDKs ship 1.47.
    # The 1.48 xdg-session-management-v1.xml is staged into the SDK's
    # wayland-protocols datadir by the sdk-stage part, so relax the
    # version gate to 1.47 to let the build proceed.
    kwin = source_root / "kwin/CMakeLists.txt"
    replace_once(
        kwin,
        "find_package(WaylandProtocols 1.48)",
        "find_package(WaylandProtocols 1.47)",
    )

    # All three Breeze look-and-feel packages (light/dark/twilight) declare
    # their default desktop wallpaper as "Next". That wallpaper package has
    # never actually been shipped by Ubuntu's plasma-workspace-wallpapers
    # (confirmed against upstream 6.6.4: it ships Altai, Autumn, ... but no
    # Next), so on a freshly-provisioned user profile (no pre-existing
    # Image= in plasma-org.kde.plasma.desktop-appletsrc)
    # MediaProxy::useSingleImageDefaults() -> DefaultWallpaper::
    # defaultWallpaperPackage() can never resolve a valid package and gives
    # up permanently: the desktop containment's wallpaper provider stays
    # stuck at Provider::Unknown forever, so the desktop background (and,
    # as observed, the rest of the initial paint) never renders -- a
    # persistent black desktop after first login. Repoint the default at
    # "Autumn", which is genuinely present in every build. Applied to every
    # lookandfeel/org.kde.breeze*/contents/defaults file found in the
    # checkout, since the exact clone layout can vary.
    for defaults_file in source_root.glob("*/lookandfeel/org.kde.breeze*/contents/defaults"):
        replace_once(defaults_file, "Image=Next", "Image=Autumn")


if __name__ == "__main__":
    main()
