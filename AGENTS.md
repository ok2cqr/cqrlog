# AGENTS.md

Guidance for coding agents working in this repository.

## Project summary

- CQRLOG is a ham radio logger written in Free Pascal with Lazarus/LCL.
- Primary source lives in `src/`.
- Database backend is MariaDB/MySQL.
- Radio and rotator control are handled through hamlib (`rigctld`, `rotctld`).

## Repository layout

- `src/` — application source
  - `f*.pas` — forms/windows
  - `d*.pas` — data modules
  - `u*.pas` — utility units
  - `fr*.pas` — Lazarus frames
  - `lnet/` — bundled networking library
  - `synapse/` — bundled HTTP/SSL library
- `ctyfiles/` — DXCC/country resolution data
- `members/` — membership data
- `xplanet/` — grayline/Xplanet assets
- `zipcodes/` — zipcode mapping data
- `voice_keyer/` — voice keyer assets/scripts
- `debian/` — Debian packaging metadata
- `flatpak/` — Flatpak packaging
- `snap/` — Snap packaging
- `tools/` — helper scripts and packaging assets

## Build commands

Use the top-level `Makefile`.

- Default build: `make`
- Debug build: `make debug`
- Clean: `make clean`
- Install to custom prefix: `make DESTDIR=/path install`
- Debian package: `make deb`
- Debian source package: `make deb_src`
- Flatpak: `make flatpak`
- Docker-based Flatpak check: `make docker-flatpak`

Widget set defaults from the Makefile:

- macOS: `WS=cocoa`
- Linux/other non-Darwin: `WS=qt6`

Other explicit build targets include:

- `make cqrlog_qt5`
- `make cqrlog_qt6`
- `make cqrlog_gtk2`

The main binary is produced at `src/cqrlog`.

## Toolchain and runtime dependencies

- Lazarus / `lazbuild`
- Free Pascal
- MariaDB/MySQL server and client libraries
- OpenSSL
- hamlib

The README currently documents Lazarus 4.6 and FPC 3.2.2 as the expected baseline.

## Architecture notes

- Entry point: `src/cqrlog.lpr`
- Lazarus project file: `src/cqrlog.lpi`
- Main log/data module code is centered around:
  - `src/fNewQSO.pas`
  - `src/fMain.pas`
  - `src/dData.pas`
  - `src/dUtils.pas`
  - `src/dDXCC.pas`
  - `src/dDXCluster.pas`
  - `src/uRigControl.pas`
  - `src/uRotControl.pas`
  - `src/uVersion.pas`

Database schema/version handling is implemented in Pascal code; check `dData.pas` and related upgrade code before changing persisted data structures.

## Working conventions

- Prefer minimal, targeted changes. This is a mature Lazarus/Free Pascal codebase.
- Follow existing unit naming and class naming patterns.
- Preserve GPL headers and surrounding code style in touched Pascal units.
- When changing UI behavior, inspect both the `.pas` and matching `.lfm` file.
- When changing packaging behavior, update the relevant packaging directory (`flatpak/`, `snap/`, `debian/`, `tools/`) rather than only the README.

## Verification expectations

- There is no obvious automated test suite in the repository root.
- For code changes, at minimum verify the affected target builds if the toolchain is available.
- For packaging changes, verify the relevant packaging target or manifest where practical.

## Known local-state considerations

- The worktree may contain user-owned untracked planning/docs files. Do not remove or overwrite unrelated files.
- There is an existing `CLAUDE.md`; keep `AGENTS.md` aligned with the real build system if the two diverge.
