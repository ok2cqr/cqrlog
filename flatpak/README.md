# CQRLOG Flatpak (Qt6)

A self-hosted, single-file Flatpak bundle of CQRLOG, compiled against the **Qt6**
widgetset on the KDE runtime.

## What is and isn't bundled

| Component | In the Flatpak? | Notes |
|-----------|-----------------|-------|
| CQRLOG (Qt6) | ✅ | built from the in-tree sources with `lazbuild --ws=qt6` |
| FPC + Lazarus + libQt6Pas | build-time only | removed from the final image |
| hamlib (`rigctld`/`rotctld`) | ✅ | found on `PATH` (`/app/bin`) inside the sandbox |
| MariaDB **client** library | ✅ | `libmariadb`, aliased to `libmysqlclient.so*` (see note) |
| MariaDB **server** (`mysqld`) | ❌ | **you run it on the host** — see below |
| tqsl, xplanet | ❌ | the app calls your **host** copies via `flatpak-spawn --host` |

> **Note on the MariaDB client library.** FPC's `mysql57dyn` `dlopen()`s the
> historic soname `libmysqlclient.so.20`, so the manifest aliases `libmariadb`
> to `libmysqlclient.so*` with symlinks in `/app/lib`. But `dlopen`-by-soname
> only consults `LD_LIBRARY_PATH` and the `ld.so.cache` — and `ldconfig` indexes
> those symlinks under libmariadb's *real* SONAME, so no `libmysqlclient.so.20`
> cache entry exists. The symlinks on disk are therefore invisible unless
> `/app/lib` is on `LD_LIBRARY_PATH`, which flatpak leaves empty. Hence the
> `--env=LD_LIBRARY_PATH=/app/lib` in `finish-args`; without it the app fails
> with *"Can not load default MySQL library"* at database-connect time.

## Prerequisite: a MariaDB/MySQL server on the host

The Flatpak does **not** start its own database server. Run MariaDB on the host
(or anywhere reachable) and point CQRLOG at it using its **remote MySQL** mode in
the connection dialog (do *not* tick "save to local"). Because the bundle is
granted `--share=network`, `127.0.0.1` inside the sandbox is the host loopback,
so a local host server works.

## Build

### Locally via Docker (manifest smoke test)

```bash
make docker-flatpak      # builds flatpak/Dockerfile then runs `make flatpak` privileged
```

On Apple Silicon this yields an **aarch64** `cqrlog.flatpak` — useful only to
verify the manifest builds. The installable **x86_64** bundle comes from CI.

### Directly (on Linux with flatpak-builder installed)

```bash
make flatpak             # produces cqrlog.flatpak
```

## Install & test (Fedora x86_64)

```bash
flatpak install --user ./cqrlog.flatpak
flatpak run com.cqrlog.cqrlog
```

Test checklist:
- DB: remote mode → host MariaDB on `127.0.0.1`; create a log, save a QSO.
- Rig: rig control uses the **bundled** `rigctld` (serial via `--device=all`).
- WSJT-X/fldigi on the host reach CQRLOG over the network (shared loopback).
- LoTW export / xplanet grayline invoke your **host** `tqsl`/`xplanet`
  (`flatpak-spawn --host`).

## Manifest

See [`com.cqrlog.cqrlog.yml`](./com.cqrlog.cqrlog.yml). The FPC/Lazarus/libQt6Pas
recipe follows the proven approach used by `io.github.cudatext.CudaText-Qt` on
Flathub; `fpc-3.2.0--glibc-2.34.patch` is required by the FPC source build.
