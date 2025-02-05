# Core 24 snap for KDE Neon Core

This is a content snap for Ubuntu Core based on Ubuntu 24.04.

## Building locally

To build this snap locally you need snapcraft.

For amd64
```
$ sudo snapcraft
```

Any other architecture is not tested or supported for now.

## Writing code

The usual way to add functionality is to write a shell script hook
with the `.chroot` extenstion under the `hooks/` directory. These hooks
are run inside the base image filesystem.

Each hook should have a matching `.test` file in the `hook-tests`
directory. Those tests files are run relative to the base image
filesystem and should validates that the coresponding `.chroot` file
worked as expected.

The `.test` scripts will be run after building with snapcraft or when
doing a manual "make test" in the source tree.

