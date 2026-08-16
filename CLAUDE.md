# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CQRLOG is an advanced ham radio logger for Linux/macOS, written in Free Pascal using the Lazarus IDE (LCL framework). It uses MariaDB/MySQL as its database backend and integrates with hamlib for radio control (140+ radio models).

Current version: 3.0.0 (defined in `src/uVersion.pas`; the Makefile derives the package version from it).

## Build Commands

The Makefile expects `lazbuild` (the Lazarus command-line compiler). The `LAZBUILD` variable auto-detects it from `PATH` with a fallback to `~/fpcupdeluxe/lazarus/lazbuild`; override with `make LAZBUILD=/path/to/lazbuild` if needed.

```bash
# Default build (Qt6 on Linux, Cocoa on macOS — WS variable)
make

# Build with specific widget set
make WS=qt5                            # override widget set for the default target
make debug                             # default widget set, no strip
make cqrlog_qt6 / cqrlog_qt6_debug     # Qt6 explicitly
make cqrlog_qt5 / cqrlog_qt5_debug     # Qt5 (legacy — see Widget Set below)
make cqrlog_gtk2 / cqrlog_gtk2_debug   # GTK2 fallback

# Clean build artifacts
make clean

# Install to a directory
make DESTDIR=/path/to/install install

# Packaging
make deb                               # Debian package (Qt5, via tools/makedeb.sh)
make appimage                          # AppImage, Qt6
make appimage-qt5                      # AppImage, Qt5 (what CI publishes)
make flatpak                           # single-file flatpak bundle, Qt6
make dmg / test-dmg                    # macOS DMG (test-dmg skips notarization)
```

The compiled binary is output to `src/cqrlog`. There is no test suite.

macOS DMGs are built locally on Petr's machine (`make dmg` signs and notarizes via keychain profile `cqrlog`), not in CI.

### Docker build (avoids installing dependencies locally)

Uses the prebuilt `pavelmc/cqrlog-build` image (or build it locally with `make docker-image`):

```bash
make docker-build       # build the binary inside the container
make docker-appimage    # AppImage via docker
make docker-deb         # deb package via docker
make docker-flatpak     # flatpak bundle via a Fedora container
```

## Architecture

### Source Organization (`src/`)

All source is in `src/`. Files follow a naming convention by prefix:

- **`f*.pas` / `f*.lfm`** — Forms (UI windows/dialogs). Each form has a `.pas` (logic) and `.lfm` (layout). ~90 form units.
- **`d*.pas` / `d*.lfm`** — Data modules (non-visual components holding database queries, connections, business logic).
- **`u*.pas`** — Utility/helper units (no forms).
- **`fr*.pas`** — Frame units (reusable UI fragments embedded in forms).

### Key Units

| Unit | Purpose |
|------|---------|
| `cqrlog.lpr` | Program entry point; creates all main forms and data modules |
| `fNewQSO.pas` | Primary QSO entry window — the main daily-use form |
| `fMain.pas` | Log browser window (QSO list, filtering, export actions) |
| `dData.pas` | Central data module — all MySQL queries, database connection management, schema versioning (`cDB_MAIN_VER`/`cDB_COMN_VER`) |
| `dUtils.pas` | Shared utilities, constants (band/mode definitions, frequency tables), callsign parsing |
| `dDXCC.pas` | DXCC country resolution engine (OK1RR algorithm using `ctyfiles/`) |
| `dDXCluster.pas` | DX cluster connection and spot parsing |
| `dLogUpload.pas` | Online log upload (HamQTH, ClubLog, HRDLog, UDP) |
| `dMembership.pas` | Club membership database lookups |
| `dSatellite.pas` | Satellite tracking data |
| `uRigControl.pas` | Radio control via hamlib's `rigctld` (TCP connection using lNet) |
| `uRotControl.pas` | Rotator control via hamlib's `rotctld` |
| `uVersion.pas` | Version constants — update this when bumping version |
| `uDbUtils.pas` | Database connection factory and connection info management |
| `uCWKeying.pas` | CW (Morse code) keying support |

### Bundled Libraries

- **`src/lnet/`** — lNet networking library (TCP/UDP components used for rigctld, DX cluster, RBN)
- **`src/synapse/`** — Synapse HTTP/SSL library (used for online callbook lookups, log uploads, LoTW); its `synaser` unit provides serial-port communication (`TBlockSerial`), used by `uCWKeying.pas` to drive WinKeyer USB and K3NG CW keyers

### Data Files

- **`ctyfiles/`** — Country resolution tables (Country.tab, Exceptions.tab, CallResolution.tbl, MASTER.SCP, etc.)
- **`members/`** — Club membership data files
- **`xplanet/`** — Xplanet overlay data for grayline map
- **`zipcodes/`** — ZIP code to locator mapping data
- **`voice_keyer/`** — Voice keyer scripts and sample audio

### Database

Uses MariaDB/MySQL with multiple connectors supported (mysql51, mysql55, mysql56, mysql57). Database schema is versioned — `dData.pas` constants `cDB_MAIN_VER` (20) and `cDB_COMN_VER` (6) track the schema version, and `fUpgrade.pas` handles migrations.

Each log is a separate database. A common database stores shared data (DXCC tables, QSL manager data, membership stats).

### Widget Set

The default widget set is **Qt6** on Linux and **Cocoa** on macOS (Makefile `WS` variable). Qt5 remains only for legacy packaging: the Qt5 AppImage published by CI and the `.deb` package (`debian/rules` pins `WS=qt5` because the Qt6 Lazarus toolchain is not in the apt repositories). Flatpak and Snap are Qt6; GTK2 is a fallback target only. The version string in `uVersion.pas` includes the widget set via `{$IFDEF}` conditionals.

## Runtime Dependencies

- MariaDB/MySQL server and client libraries
- hamlib (`rigctld`, `rotctld`) for radio/rotator control
- OpenSSL (`libssl`) for HTTPS connections (LoTW, callbook lookups)

## Coding Conventions

- Free Pascal `{$mode objfpc}{$H+}` (Object Pascal mode with AnsiStrings)
- GPL v2 license header on all units
- Form classes prefixed with `Tfrm`, data modules with `Tdm`
- Code formatting configured via `jcfsettings.cfg` (Jedi Code Format for Lazarus)
