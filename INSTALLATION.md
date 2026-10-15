# Installation

## Building from source

Install the Plasma 6 / KDecoration3 development dependencies first. Plasma 6.4
or newer is required for the Task Manager `HasNoBorder` role used to follow
native-titlebar changes.

### Arch

```bash
sudo pacman -Syu
sudo pacman -S base-devel cmake extra-cmake-modules qt6-base qt6-declarative kcoreaddons kconfig kdecoration ksvg libplasma plasma-workspace
```

### Fedora

Package names vary by Fedora/KDE spin, but the required development families are
Qt 6, KF6, Plasma 6, KDecoration3, CMake, and ECM:

```bash
sudo dnf install gcc-c++ cmake extra-cmake-modules qt6-qtbase-devel qt6-qtdeclarative-devel kf6-kcoreaddons-devel kf6-kconfig-devel kf6-ksvg-devel plasma-workspace-devel kdecoration-devel
```

### Ubuntu / KDE neon

KDecoration3 packaging names vary across Ubuntu releases. Use KDE neon or a
Plasma 6-capable Ubuntu release and install the Qt 6, KF6, Plasma 6, and
KDecoration3 development packages available for that release.

## Building and installing

```bash
cmake -B build -S .
cmake --build build
sudo cmake --install build
systemctl --user restart plasma-plasmashell.service
```

## Prebuilt package

On the maintained Arch repo:

```bash
sudo pacman -S plasma-applet-window-buttons
```

Signed package archives and checksum manifests are also available in the
[rolling Arch release](https://github.com/ciolansteen/plasma-applet-window-buttons6/releases/tag/arch-packages).
Download the main package, its detached signature, and the matching
`SHA256SUMS` manifest and signature. Verify the manifest with a trusted signing
key before checking the archive checksum. The debug package is optional.
Install the main archive with `sudo pacman -U /path/to/package.pkg.tar.zst`;
do not disable pacman's signature checking.

## After a Plasma upgrade

This applet includes a compiled QML plugin. A Plasma ABI change can require a
package rebuild even when the applet source has not changed.

Plasma 6.8 changed the library SONAME from `libPlasma.so.7` to
`libPlasma.so.8`. The Arch package `1:0.16.0.r11.g19fc7f7-2` is a rebuild for
Plasma 6.8. A binary built for the previous ABI can fail with:

```text
Cannot load library .../libappletdecorationplugin.so:
libPlasma.so.7: cannot open shared object file: No such file or directory
```

With the maintained package repository configured, upgrade the system and applet
together:

```bash
sudo pacman -Syu plasma-applet-window-buttons
```

Alternatively, install a verified archive built against the installed Plasma
libraries, or rebuild from source against those libraries. Do not create a
symlink from one library SONAME to another: that does not restore ABI
compatibility. Do not use `pacman -Sy` followed by a package-only upgrade.

After installing the rebuild, log out and back in, or restart only Plasma Shell
from the graphical session:

```bash
systemctl --user restart plasma-plasmashell.service
```

The panel briefly disappears during the restart; application windows stay open.
There is no need to remove and re-add the applet or recreate the panel.

For diagnosis, inspect the installed plugin and the current boot's shell logs:

```bash
ldd -r /usr/lib/qt6/qml/org/kde/appletdecoration/libappletdecorationplugin.so
journalctl -b _COMM=plasmashell --no-pager --grep='windowbuttons|appletdecoration'
```

`not found` or `undefined symbol` entries indicate unresolved native-library
dependencies. Also check for a user-local applet under
`~/.local/share/plasma/plasmoids/org.kde.windowbuttons/`, which can shadow the
system package; preserve its configuration before changing it.
