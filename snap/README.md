# CQRLOG Snap (Qt6)

A strictly-confined Snap of CQRLOG, compiled against the **Qt6** widgetset. It
mirrors the [Flatpak](../flatpak/README.md): the same FPC + Lazarus + libQt6Pas
toolchain is built from source, and the app is **snap-aware** (`isSnap` in
`src/dUtils.pas`) the same way it is flatpak-aware.

## What is and isn't bundled

| Component | In the Snap? | Notes |
|-----------|--------------|-------|
| CQRLOG (Qt6) | ✅ | built from the in-tree sources with `lazbuild --ws=qt6` |
| FPC + Lazarus | build-time only | pruned from the final snap (`prime: [-usr/local/freepascal]`) |
| libQt6Pas | ✅ | built against the `kde-neon-6` extension's Qt6 (Qt6 itself is **not** rebuilt) |
| hamlib (`rigctld`/`rotctld`) | ✅ | bundled at `$SNAP/usr/bin`, run **integrated** in-sandbox |
| xplanet | ✅ | bundled, run integrated (grayline map) |
| MariaDB **client** library | ✅ | `libmariadb3`, aliased to `libmysqlclient.so*` (see note) |
| MariaDB **server** (`mysqld`) | ❌ | **you run it on the host / LAN** — see below |
| tqsl (LoTW) | ❌ | **known v1 limitation** — strict confinement can't reach a host tqsl |

> **Note on the MariaDB client library.** FPC's `mysql57dyn` `dlopen()`s the
> historic soname `libmysqlclient.so.20`. `snapcraft.yaml` aliases `libmariadb`
> to `libmysqlclient.so*` with symlinks next to the real lib in
> `$SNAP/usr/lib/$CRAFT_ARCH_TRIPLET`. `dlopen`-by-soname only consults
> `LD_LIBRARY_PATH` (there is no usable `ld.so.cache` for `$SNAP`), so that dir
> is put on `LD_LIBRARY_PATH` in the app's `environment`; without it the app
> fails with *"Can not load default MySQL library"* at database-connect time.

## How the snap differs from the flatpak

- **Helper tools run integrated, not on the host.** The flatpak launches your
  *host* `tqsl`/`xplanet` via `flatpak-spawn --host`; a strict snap has no host
  bridge, so it **bundles** the tools and runs them in-sandbox. `isSnap` is
  deliberately *not* treated like `InFlatpak` in `SetupHostProcess`, so the app
  executes the bundled binary directly. `DefaultToolPath` already finds them
  next to the `cqrlog` binary (`$SNAP/usr/bin`).
- **Its own settings keys.** `PlatformKey` appends `_snap` (like `_flatpak`), so
  snap paths/rig settings never clash with a native or flatpak install.
- **XWayland.** The app forces `QT_QPA_PLATFORM=xcb`, so the `x11` plug is
  mandatory; the `kde-neon-6` extension provides the XWayland bridge (the snap
  analogue of the flatpak's `--socket=x11`).

## Prerequisite: a MariaDB/MySQL server on the host

The snap does **not** start its own database server. Run MariaDB on the host (or
anywhere reachable) and point CQRLOG at it in **remote MySQL** mode in the
connection dialog (do *not* tick "save to local"). The `network` plug means
`127.0.0.1` is the host loopback, so a local server works.

## Build

On Linux with snapcraft + LXD:

```bash
snapcraft            # produces cqrlog_3.0.0_<arch>.snap
```

The installable bundle is also produced by CI
([`.github/workflows/05-snap.yml`](../.github/workflows/05-snap.yml)).

## Install & test

```bash
snap install --dangerous ./cqrlog_*.snap
snap connect cqrlog:raw-usb        # serial rigs are not auto-connected
cqrlog
```

Test checklist:
- Launch: expect the `Using xcb to get around ugly Wayland bugs` line, then the
  window opens (via XWayland on a Wayland session).
- Settings: `~/snap/cqrlog/current/.config/cqrlog/cqrlog.cfg` gets `*_snap` keys.
- DB: remote mode → host MariaDB on `127.0.0.1`; create a log, save a QSO.
- Rig: rig control uses the **bundled** `rigctld`.
- xplanet grayline renders (bundled xplanet).
- LoTW via tqsl is **not** available in this snap (see table).

## Recipe

See [`snapcraft.yaml`](./snapcraft.yaml). The FPC/Lazarus/libQt6Pas recipe and
the `fpc-3.2.0--glibc-2.34.patch` are shared with the flatpak build.
