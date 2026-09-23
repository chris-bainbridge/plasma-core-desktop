#!/usr/bin/env python3

"""Forward-port patches for Plasma 6.7.5 against the core24 build env.

Plasma 6.7.5 targets a newer PipeWire (>= 1.4) than the core24 build
environment ships (1.2.6, the newest available for noble). PipeWire 1.4
renamed pw_stream_queue_buffer() to pw_stream_return_buffer(); the old
name is what 1.2.6's headers still expose, so map it back.
"""

from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if old not in text:
        # Already patched (idempotent across incremental rebuilds), or the
        # source changed upstream. Either way there is nothing to do.
        return
    path.write_text(text.replace(old, new, 1))


def remove_once(path: Path, snippet: str) -> None:
    text = path.read_text()
    if snippet not in text:
        # Already removed (idempotent across incremental rebuilds).
        return
    path.write_text(text.replace(snippet, "", 1))


def main() -> None:
    source_root = Path("install-data/kde/src")

    # PipeWire 1.4 renamed pw_stream_queue_buffer -> pw_stream_return_buffer.
    # core24 only has PipeWire 1.2.6, which still uses the old name.
    screencast = source_root / "kwin/src/plugins/screencast/screencaststream.cpp"
    replace_once(
        screencast,
        "pw_stream_return_buffer(m_pwStream, pwBuffer);",
        "pw_stream_queue_buffer(m_pwStream, pwBuffer);",
    )

    # kdeplasma-addons' kameleon kded module (RGB keyboard LED accent
    # colouring) pulls in a Rust helper via Corrosion. The build container
    # has no working cargo/crates.io access, and this niche addon isn't
    # needed for a minimal Plasma desktop, so drop the Rust helper.
    kameleon = source_root / "kdeplasma-addons/kdeds/kameleon/CMakeLists.txt"
    remove_once(
        kameleon,
        "if(NOT CMAKE_SYSTEM_NAME MATCHES FreeBSD)\n    add_subdirectory(qmk/kameleon-qmk-helper)\nendif()\n",
    )


if __name__ == "__main__":
    main()
