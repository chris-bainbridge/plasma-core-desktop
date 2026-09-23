# Vendored wayland-protocols files

Ubuntu 26.04's `wayland-protocols` archive package is 1.47, but kwin 6.7.5
requires two updates added in wayland-protocols 1.48:

- The `xdg-session-management-v1` staging protocol (entirely new file in
  1.48; 1.47 doesn't have it at all).
- The `zwp_text_input_v3` interface version 2 additions to
  `unstable/text-input/text-input-unstable-v3.xml` (the `action` and
  `preedit_hint` enums/events/requests, `set_available_actions`,
  `show_input_panel`, `hide_input_panel`; 1.47 only has interface version 1).

Rather than depend on network access at build time (or backporting the
whole package), this directory vendors just the two affected protocol
XMLs, fetched verbatim from the upstream wayland-protocols repository at
the 1.48 tag:

  https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/1.48/staging/xdg-session-management/xdg-session-management-v1.xml
  https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/1.48/unstable/text-input/text-input-unstable-v3.xml

They carry the same MIT-style copyright/license as the rest of
wayland-protocols (see each file's own `<copyright>` block). They are
staged into the SDK's `usr/share/wayland-protocols/` tree by the
`sdk-stage` part in `snapcraft.yaml`, replacing/augmenting the 1.47
protocols already shipped by the kde-qt6-core26-sdk snap.

Remove this vendoring once the core26 SDKs ship wayland-protocols >= 1.48.
